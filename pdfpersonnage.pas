unit PdfPersonnage;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}

interface

uses
  Classes, SysUtils, fpPDF, FPImage, FPReadPNG, FPWritePNG, PdfUtils, ChargeRace, ChargeMetier, ChargeMetierNiveau,
  ChargeRaceAttribut, ChargeRacePhysique, ChargeSigneAstral, ChargeTalent, ChargeCompetence, ChargeArme, ChargeArmure,
  ChargeArmeBonus, ChargeArmureBonus, ChargeSort, ChargeAttribut, ChargeFabrication,
  ChargeConstantes, ChargeTraduction, ChargeMetierAttribut, ChargeTexte, ChargeMetierTalent, ChargeTrapping,
  ChargePersonnage, ChargeArmureSimplifie, 
  ChargeCorruptionTable,
  ChargeModificateur, ChargeCorruptionCompetenceModif,
  ChargeTalentEffet, ChargeAffliction, ChargeDisease, ChargeGroupe,
  Dialogs, MessageTest, UnitCalcul, Math, LCLIntf, LazUTF8, StrUtils;

Type
  StructureDonnee  = record
    Base:	   Integer;
    Augmentation:  Integer;
    Total:	   Integer;
end;

  // Brique 2 (tableau de données, CONTEXT.md §2.4) — types génériques pour dessiner un
  // tableau à partir de données déjà préparées, sans que le dessin ait à connaître le sens
  // métier des champs.
  //
  // Orientation : orLigne = une entrée du tableau est une ligne, ses champs sont en colonnes
  // (cas des tableaux de Compétences). orColonne = une entrée est une colonne, ses champs
  // sont empilés en lignes (cas du tableau des Caractéristiques).
  TPdfOrientationTableau = (orLigne, orColonne);

  // Police utilisée pour dessiner une valeur : spValeur = police de valeur normale de la
  // colonne (Arial, taille Tableau.Police) sauf si la colonne est EnTete (alors police
  // d'en-tête, voir TPdfColonne) ; spEnTete force la police d'en-tête (Carlson gras 10)
  // même sur une colonne qui ne l'est pas par défaut ; spAccent force une police "accent"
  // (Arial gras 8), utilisée par ex. pour le nom d'une compétence liée au métier en cours.
  TPdfStylePolice = (spValeur, spEnTete, spAccent);

  // Une valeur affichée dans une case du tableau. Valeur = '' signifie "case vide, rien
  // n'est dessiné" (ex : le niveau métier n'existe pas pour cette caractéristique).
  // Annotation est un petit texte optionnel affiché à côté de la valeur, utilisé pour le
  // bonus racial/talent (Caractéristiques) ou l'astérisque de compétence (Compétences) —
  // DessinerTableau choisit automatiquement sa position et sa taille selon l'orientation du
  // tableau, la préparation des données n'a pas à connaître ces détails de dessin.
  TPdfValeurCase = record
    Champ:      String;
    Valeur:     String;
    Grise:      Boolean;
    Annotation: String;
    Style:      TPdfStylePolice;
  end;

  // Une entrée du tableau (une caractéristique, une compétence...). Valeurs simule un
  // "enregistrement SQL" : les champs sont retrouvés par leur nom (TPdfColonne.Champ), pas
  // par position, pour que la préparation des données et la définition du tableau restent
  // indépendantes l'une de l'autre.
  TPdfEnregistrement = record
    Valeurs: array of TPdfValeurCase;
  end;
  TPdfRecordSet = array of TPdfEnregistrement;

  // Alignement du texte d'en-tête d'une colonne (orLigne uniquement) : alCentre utilise
  // PdfCentre (texte centré, taille fixe), alGauche utilise PdfEcrit (texte cadré à gauche,
  // rétréci jusqu'à Tableau.PoliceMin si besoin) — cas de la colonne "Nom".
  TPdfAlignementEntete = (alCentre, alGauche);

  // Définit une ligne (orColonne) ou une colonne (orLigne) du tableau.
  //  - Libelle : texte affiché dans la bande de libellés (orColonne) ou en en-tête de
  //    colonne (orLigne).
  //  - Champ : nom du champ à aller chercher dans chaque TPdfEnregistrement.
  //  - EnTete : la valeur de cette ligne/colonne est dessinée avec la police d'en-tête
  //    (Carlson gras) plutôt que la police de valeur normale par défaut (cas de la ligne
  //    "Code" des Caractéristiques, et des colonnes Nom/Attribut des Compétences).
  // Les champs suivants ne concernent que l'orientation orLigne :
  //  - Largeur : largeur propre de cette colonne (0 = largeur par défaut Tableau.LargeurEntree) ;
  //    permet une colonne plus large que les autres (ex : le nom d'une compétence).
  //  - FusionAvecSuivante : si vrai, le libellé de cette colonne est centré sur sa largeur ET
  //    celle de la colonne suivante, et le séparateur entre les deux ne descend qu'à partir de
  //    la première ligne de données (pas dans la bande d'en-tête) — cas de "Carac" qui chapeaute
  //    les colonnes Attribut + Valeur.
  //  - AlignementEntete : voir TPdfAlignementEntete.
  //  - DecalageValeurMin/Max : décalages ajoutés aux bords gauche/droit de la colonne pour
  //    positionner le texte d'une valeur (PdfEcrit) ; 0 = dessiné exactement dans les bords
  //    de la colonne. Chaque tableau a ses propres décalages (constatés colonne par colonne
  //    dans l'ancien code, pas de convention unique) — à renseigner à chaque définition de
  //    tableau, jamais de valeur par défaut "raisonnable" côté DessinerTableau.
  //  - DecalageEnteteMin/Max : même principe que DecalageValeurMin/Max, mais pour le texte
  //    d'en-tête d'une colonne AlignementEntete = alGauche (PdfEcrit) ; sans effet en alCentre.
  TPdfColonne = record
    Libelle:            String;
    Champ:              String;
    EnTete:             Boolean;
    Largeur:             Single;
    FusionAvecSuivante:  Boolean;
    AlignementEntete:    TPdfAlignementEntete;
    DecalageValeurMin:   Single;
    DecalageValeurMax:   Single;
    DecalageEnteteMin:   Single;
    DecalageEnteteMax:   Single;
  end;

  TPdfTableau = record
    X, Y:            Single;   // coin haut-gauche du tableau, bande de libellés incluse
    Orientation:      TPdfOrientationTableau;
    LargeurLibelles:  Single;  // largeur de la bande de libellés (orColonne)
    LargeurEntree:    Single;  // largeur par défaut d'une colonne "entrée" (orColonne) ou
                                // d'une colonne de donnée (orLigne, si Champ.Largeur = 0)
    HauteurLigne:     Single;
    Police:           Integer; // taille de police par défaut des valeurs (hors EnTete/Accent)
    Champs:           array of TPdfColonne;
    // orLigne uniquement :
    Titre:               String; // bandeau plein largeur au-dessus des en-têtes ('' = aucun)
    TitreDecalageGauche:  Single;
    PoliceMin:            Integer; // taille plancher pour le rétrécissement auto (PdfEcrit)
    NbLignesMax:          Integer; // nombre de lignes du cadre dessiné, si le tableau a une
                                    // capacité fixe supérieure au nombre d'entrées réellement
                                    // fournies (ex : grille de compétences à 28 lignes, dont
                                    // seules les premières sont remplies) ; 0 = cadre exactement
                                    // à la taille de Donnees.
  end;


Procedure PdfPersonnageCompetenceTri(ListPage: TStringList);
Function PdfAsterisquesCachees(Personnage: StructurePersonnage): Boolean;
Function PdfBonusAttributFiltrer(Personnage: StructurePersonnage; Texte: String): String;
Function PdfPersonnageAttribut(Personnage: StructurePersonnage; Attribut: String; var Bonus: String): StructureDonnee;
// Generalisation du case de calcul de talents (A FAIRE.txt "GENERICISER LE CASE DE CALCUL
// DES TALENTS", ChargeTalentEffet) : total pour une Cible (vocabulaire ferme, voir
// ChargeConstantes ConstCibleEffet*) toutes sources confondues (creation + augmentation),
// sans plus regarder le CODE du talent - n'importe quel talent portant <Effet Cible="..."/>
// contribue. Remplace le case cablé sur TalentDurACuire/TalentCostaud/etc.
Function PersonnageTalentEffet(Personnage: StructurePersonnage; Cible: String): Integer;
// Meme perimetre que ci-dessus mais renvoie le RANG BRUT (PersonnageTalent.Valeur) plutot
// que le total calcule - sert uniquement a l'affichage Feldo2P qui montre le rang du talent
// a cote du total (ex. Hardy/Dur a Cuire), CONTEXT.md.
Function PersonnageTalentEffetRang(Personnage: StructurePersonnage; Cible: String): Integer;
// Plafond de corruption (Bonus Endurance/10 + Bonus Force Mentale/10 + talent Âme Pure),
// même calcul que PdfBlocCorruption mais exposé pour être réutilisé hors PDF (WinPersonnage,
// CONTEXT.md §2.7) - PdfPersonnageCreationFeldo2P n'est PAS modifiée, nouvelle fonction
// indépendante pour ne rien risquer sur le PDF existant.
Function PersonnageCorruptionTotal(Personnage: StructurePersonnage): Integer;
// Mode lot (WarhammerHelp.exe --pdf) : ne pas ouvrir le lecteur PDF apres l'ecriture.
Var
  PdfSansOuverture: Boolean = False;
  // Habillage Warhammer du PDF Feldo (option {PdfStyle}) : fonds et couleurs seulement, le texte
  // et la geometrie restent identiques. Pose par PdfPersonnageCreationFeldo2P.
  PdfStyle: Boolean = False;
  PdfEconomie: Boolean = False;   // economie d'encre : aucun fond plein, les textes de bandeau passent en noir
  // Faux = meme habillage en niveaux de gris (impression noir et blanc), option {PdfNoColor}.
  PdfCouleur: Boolean = True;
  // Faux = pas de losanges aux extremites des bandeaux (bandeaux etroits ou texte pleine largeur).
  PdfOrnements: Boolean = True;

Procedure PdfPersonnageCreation(Personnage: StructurePersonnage; BackGround: Boolean; DessineTexteLigne: Boolean = True);
Procedure PdfPersonnageCreationFeldo2P(Personnage: StructurePersonnage);
Procedure PdfPersonnageV2(Personnage: StructurePersonnage);
Procedure PdfPersonnageV1(Personnage: StructurePersonnage);
Function PdfPersonnageCompetence(Personnage: StructurePersonnage; Competence: String; out NivMetier: Integer): StructureDonnee;
Function PdfPersonnageTalent(Personnage: StructurePersonnage; Talent: String; out NivMetier: Integer): StructureDonnee;
Function PdfPersonnageRemplaceBonus(Personnage: StructurePersonnage; ChW: String): String;
Function PdfPersonnageCompetenceBonus(Personnage: StructurePersonnage; CodeCompetence: String): String;
Function PdfPersonnageTalentBonus(Personnage: StructurePersonnage; CodeTalent: String): String;

// Calcule les astérisques numérotées liées aux malus de compétence de l'armure
// actuellement équipée (armures normales ET simplifiées, même résolution que
// PdfBlocArmuresDonnees mais sans rien dessiner - peut donc être appelée avant la page 1).
// Une astérisque par PIÈCE portée (pas par code de bonus), pour que deux pièces
// différentes portant le même code de malus (ex. plastron + jambières "Not discreet")
// gardent chacune leur propre numéro. Numérotation continuant après le maximum déjà
// utilisé par le système de talents (Personnage.Asterisque), sans jamais l'écrire dedans
// - conception validée avec Nono le 15-16/08/2026, voir CONTEXT.md §2.5. Renvoie une
// TStringList Name=CodeCompetence / Value=texte d'annotation à concaténer à celle des
// talents (ex. " (5) (6)", même format court que le système de talents - PdfEcrit
// wrap sur deux lignes si le texte est trop long pour la petite colonne d'annotation,
// donc pas de pourcentage ici). Renvoie aussi, en paramètre out, une deuxième
// TStringList Name=CodeEquipement / Value=numéro, pour afficher le même numéro à côté
// de la pièce d'armure elle-même (PdfBlocArmuresDonnees), comme (N) à côté d'un talent -
// permet de retrouver quelle pièce cause quel malus. Les deux listes sont à libérer par
// l'appelant.
// AsterisqueDepart (ajouté le 17/08/2026) : point de départ de la numérotation, pour
// enchaîner sans collision après une autre source d'astérisques déjà numérotée dans le
// même PDF (ex. les mutations, voir PdfPersonnageMutationAsterisques) - auparavant fixé
// en dur à Personnage.Asterisque (le seul baseline connu, celui des talents).
Function PdfPersonnageArmureAsterisques(Personnage: StructurePersonnage; AsterisqueDepart: Integer; out AsterisqueParEquipement: TStringList; out AsterisqueFinal: Integer): TStringList;

// Effets à delta pur des mutations obtenues, visibles sur une caractéristique ou une
// compétence (CONTEXT.md §2.7, étape 9) - même principe que PdfPersonnageArmureAsterisques :
// Result est une TStringList Name=CodeAttribut/CodeCompetence / Value=" (N)" (à concaténer à
// l'annotation existante), AsterisqueParMutation est Name=CodeCorruption / Value="(N)" pour
// l'afficher à côté du nom de la mutation elle-même (PdfBlocMutations). AsterisqueDepart
// permet d'enchaîner après une autre source déjà numérotée ; AsterisqueFinal renvoie le
// dernier numéro utilisé, pour qu'une source suivante (ex. les armures) puisse à son tour
// enchaîner sans collision. Les deux TStringList sont à libérer par l'appelant.
// AsterisqueArmure (ajouté le 17/08/2026, CONTEXT.md §2.7 étape 9) : concaténation des
// "(N)" des mutations qui affectent les Armour Points (ListCorruptionArmureModif, peu
// importe la case Tête/Bras/Corps/Jambes touchée) - un seul marqueur pour tout le bloc
// PdfBlocArmourPoints, pas un par case (choix de Nono, "pas mettre l'astérisque sur
// chaque partie de l'armure"). Même numéro que celui déjà utilisé pour la mutation si
// elle touche aussi un Attribut/une Compétence (AsterisqueMutation partagé par mutation).
Function PdfPersonnageMutationAsterisques(Personnage: StructurePersonnage; AsterisqueDepart: Integer; out AsterisqueParMutation: TStringList; out AsterisqueArmure: String; out AsterisqueFinal: Integer): TStringList;
// Asterisque du signe astral (definie plus bas, appelee par PdfPersonnageMutationAsterisques).
Procedure PdfSigneAstralAsterisque(Personnage: StructurePersonnage; var AsterisqueCourant: Integer; Annotation, ParPiece: TStringList);

// Blocs extraits de PdfPersonnageCreationFeldo2P (CONTEXT.md §2.4) — premier prototype
// de l'architecture Bloc/Tableau. PdfBlocResilience dessine le cadre partagé
// Résilience/Destin (les deux tableaux occupent une seule boîte dans ce gabarit) ET le
// contenu du côté Résilience ; PdfBlocDestin dessine uniquement le contenu du côté Destin,
// sans redessiner le cadre. Voir le commentaire sur PdfBlocResilience pour le détail.
Procedure PdfBlocResilience(PdfPage: TPDFPage; Personnage: StructurePersonnage; X, Y: Single; NbLignes: Integer; HauteurLigne: Single; MinPolice: Integer; Determine: Integer; out NbLignesPourSuite: Integer);
Procedure PdfBlocDestin(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, Y: Single; HauteurLigne: Single; MinPolice: Integer; Chance: Integer);

// Bloc Entête (panneau fixe en haut de la page 1 : nom, race, classe, carrière, niveau de
// carrière, voie, statut, âge/taille/cheveux/yeux). Grille à colonnes irrégulières selon la
// ligne (les séparateurs verticaux internes changent d'une ligne à l'autre) : ce n'est donc
// pas un TPdfTableau générique, juste un bloc simple comme Résilience/Destin. Renvoie le Y
// du bas du cadre, comme DessinerTableau (sans le -3 de marge, laissé à l'appelant).
Function PdfBlocEntete(PdfPage: TPDFPage; Personnage: StructurePersonnage; PRace: StructureRace; PMetier: StructureMetier; PMetierNiveau: StructureMetierNiveau; LocData: String; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; AnnotSigne: String): Single;

// Bloc Ambitions (panneau fixe : titre + 4 lignes court/long terme, personnage puis groupe -
// NbLignes fixe a 5, plus de parametre). Brique 1, CONTEXT.md §2.4. Renvoie le Y du bas du
// cadre, comme PdfBlocEntete (sans le -3 de marge, laissé à l'appelant). Deplace en page 2 le
// 27/09/2026 (a la demande de Nono, a cote du bloc Montures/Navires) et etendu aux ambitions
// de groupe (Personnage.AmbitionGroupeCourt/Long) a la meme occasion.
Function PdfBlocAmbitions(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; MinPolice: Integer): Single;

// Blocs Expérience / Mouvement / Corruption : trois panneaux "titre + lignes libellé/valeur"
// alignés côte à côte sur la même rangée (même Y de départ, calculé par l'appelant à partir
// du bas du bloc Résilience/Destin). Chacun ne connaît que son propre coin (XGauche/XDroite),
// brique 1, CONTEXT.md §2.4. Renvoient le Y du bas du cadre (sans le -3 de marge).
Function PdfBlocExperience(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer): Single;
Function PdfBlocMouvement(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; Mouv, BonusSprint: Integer): Single;
Function PdfBlocCorruption(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; BE, BFM, AmePure, Lost: Integer): Single;
Procedure PdfGabaritNormalPage1(PdfPage: TPDFPage; MinPolice: Integer);
Procedure PdfGabaritNormalPage2(PdfPage: TPDFPage; MinPolice: Integer);
Procedure PdfNormalEntete(PdfPage: TPDFPage; Personnage: StructurePersonnage; MinPolice: Integer);
Procedure PdfNormalCaracteristiques(PdfPage: TPDFPage; Personnage: StructurePersonnage);
Procedure PdfNormalDestinXpMouvement(PdfPage: TPDFPage; Personnage: StructurePersonnage; Chance, Determine, Mouv, BonusSprint: Integer);
Procedure PdfNormalCompetencesBase(PdfPage: TPDFPage; Personnage: StructurePersonnage; PMetier: StructureMetier; ListPage: TStringList; DessineTexteLigne: Boolean; MinPolice: Integer; out ListPris: String);
Procedure PdfNormalCompetencesGroupees(PdfPage: TPDFPage; Personnage: StructurePersonnage; PMetier: StructureMetier; ListPris: String; MinPolice: Integer);
Procedure PdfNormalTalents(PdfPage: TPDFPage; Personnage: StructurePersonnage; MinPolice: Integer);
Procedure PdfNormalBlessuresEncombrementRichesse(PdfPage: TPDFPage; Personnage: StructurePersonnage; BF, BE, BFM, DurACuire, BonusBlessureFab, BonusEncomb: Integer);
Procedure PdfNormalArme(PdfPage: TPDFPage; Personnage: StructurePersonnage; PersonnageEquipement: StructurePersonnageEquipement; BF, TBonusCC, TBonusCT, MinPolice: Integer; var EncArme, NbArme: Integer; var Quality, ArmeBonii, FabricationBonii: String);
Procedure PdfNormalArmure(PdfPage: TPDFPage; PersonnageEquipement: StructurePersonnageEquipement; MinPolice: Integer; var EncArmure, NbArmure, ArmureBras, ArmureCorps, ArmureJambe, ArmureTete: Integer; var Quality, ArmureBonii, FabricationBonii: String);
Procedure PdfNormalDivers(PdfPage: TPDFPage; PersonnageEquipement: StructurePersonnageEquipement; MinPolice: Integer; var IndDivers, EncDivers: Integer);
Procedure PdfNormalSort(PdfPage: TPDFPage; Personnage: StructurePersonnage; PersonnageEquipement: StructurePersonnageEquipement; MinPolice: Integer; var NbSort: Integer);
Procedure PdfNormalExplications(PdfPage: TPDFPage; ArmureBonii, ArmeBonii, FabricationBonii: String);
Procedure PdfNormalTotauxEncombrementArmure(PdfPage: TPDFPage; Personnage: StructurePersonnage; EncArmure, EncArme, EncDivers, ArmureTete, ArmureBras, ArmureCorps, ArmureJambe: Integer);
Procedure PdfBlocBlessure(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; BF, BE, BFM, DurACuire, ValDurACuire, BonusBlessureFab: Integer; AnnotBlessure: String);
Procedure PdfBlocCompetencesCombat(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; TotalEsquive, TotalCalme, TotalIntuition, TotalCommandement, TotalResitance: Integer);
Function PdfFeldoTableauCaracteristiques(DessinDebColCompG: Integer; DessinDebutHautCarac, DessinHauteurCarac, DessinLargeurCarac: Single): TPdfTableau;
Function PdfFeldoTableauCompetencesBase(DessinDebColCompG, DessinDebColG, DessinNbLigComp, MinPolice: Integer; DessinDebutHautComp, DessinLargeurComp, DessinHauteurComp: Single): TPdfTableau;
Procedure PdfFeldoRepartitionPage1(Personnage: StructurePersonnage; ListPris: String; DessinMinLignesVides: Integer; var DessinNbLigComg, DessinNbLigTal, DessinNbLigMut: Integer);
Function PdfFeldoTableauCompetencesGroupees(DessinDebColD, DessinNbLigComg, MinPolice: Integer; DessinDebutHautComg, DessinLargeurComg, DessinHauteurComg: Single): TPdfTableau;
Procedure PdfFeldoRepartitionPage2(Personnage: StructurePersonnage; ArmureSet: Boolean; NbLigExpl, DessinMinLignesVides: Integer; var DessinNbLigArm, DessinNbLigEqu, DessinNbLigWea, DessinNbLigSor: Integer);
Function PdfFeldoMetiersAnciens(Personnage: StructurePersonnage): String;
Procedure PdfFeldoImagesEntete(PDFDoc: TPDFDocument; PdfPage: TPDFPage; DessinDebutHautEntete: Single);
Procedure PdfFeldoEncombrement(PdfPage: TPDFPage; DessinDebColCompG: Integer; DessinLargeurEnc, DessinDebutHautEnc, DessinHauteurEnc: Single; DessinNbLigEnc, EncArmure, EncArme, EncDivers, BF, BE, BonusEncomb: Integer);
// Bloc Richesse (Feldo2P, page 1, sous Corruption) : titre + trois lignes CO / PA / SB avec
// les montants de Personnage.MonnaieCO/PA/SB. Renvoie le Y du bas du cadre.
Function PdfBlocRichesse(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; MinPolice: Integer): Single;

// Bloc Corruption Détail : tableau Montant | Libellé, une ligne par entrée de
// Personnage.Corruption, la plus récente en haut, CONTEXT.md §2.6. Si l'historique
// dépasse la capacité du cadre, les entrées les plus ANCIENNES au-delà ne sont pas
// affichées (même limite silencieuse que PdfBlocDiversDonnees pour Divers).
Function PdfBlocCorruptionDetail(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer): Single;

// Bloc Talents : liste répétitive comme les tableaux de compétences (deux passes : talents
// acquis d'abord, puis talents accessibles via le métier mais pas encore pris, grisés, tant
// qu'il reste de la place), mais gardée en bloc simple plutôt que réécrite avec
// DessinerTableau/TPdfRecordSet : la colonne Description a un décalage vertical qui dépend de
// la longueur du texte (résumé long → probablement affiché sur 2 lignes par PdfEcrit → +1.5
// au lieu de +1 pour recentrer), un cas que le tableau générique ne modélise pas aujourd'hui.
// Utilise les globales ListTalent/ListMetierTalent/ChercheTalent (déjà globales dans l'ancien
// code, pas de changement de portée). Renvoie le Y du bas du cadre, comme les autres blocs
// (sans le -3 de marge) ; rien ne le réutilise à ce jour (la page 2 repart de
// DessinDebutHautEntete), gardé pour la cohérence avec les autres blocs.
Function PdfBlocTalents(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer): Single;

// Bloc Armures (page 2, cadre uniquement : cadre + en-têtes de colonnes du tableau
// Armures). Contrairement aux autres blocs, DessinDebutHautArm (Y du haut) et
// DessinLargeurArm (X du bord droit) sont relus bien plus loin dans la procédure (cadre
// "DessinExplication") : l'appelant garde donc ses propres variables et les passe
// simplement en Y/XDroite, ce bloc ne fait que dessiner. Le remplissage des lignes (une
// par armure possédée) reste dans la procédure principale, dans la même boucle que
// Armes/Équipement/Sorts (elle calcule des totaux partagés réutilisés plus loin pour
// l'Encombrement et le cadre d'explication) : voir CONTEXT.md §2.4 pour la discussion sur
// pourquoi ce remplissage n'est pas encore découpé. Pas de MinPolice : ce bloc ne dessine
// que des libellés fixes (PdfCentre), aucun texte de largeur variable (PdfEcrit). Renvoie
// le Y du bas du cadre, comme les autres blocs (sans le -3 de marge, laissé à l'appelant).
Function PdfBlocArmures(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer): Single;

// Bloc Équipement (page 2, cadre uniquement) — même principe que PdfBlocArmures : cadre +
// en-têtes, remplissage laissé dans la procédure principale (voir CONTEXT.md §2.4). La
// grille de colonnes est doublée (Nom/Encombrement répété deux fois) parce que la liste
// "Divers" se répartit sur deux demi-colonnes quand elle dépasse la hauteur du cadre
// (voir le remplissage, `IndDivers`) — pas une erreur, préservé tel quel.
Function PdfBlocEquipement(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer): Single;

// Bloc Armes (page 2, cadre uniquement) — même principe que PdfBlocArmures/
// PdfBlocEquipement : cadre + en-têtes, remplissage laissé dans la procédure
// principale (voir CONTEXT.md §2.4).
Function PdfBlocArmes(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer): Single;

// Bloc Sorts (page 2, cadre uniquement) — même principe que PdfBlocArmures/
// PdfBlocEquipement/PdfBlocArmes : cadre + en-têtes, remplissage laissé dans la
// procédure principale (voir CONTEXT.md §2.4).
Function PdfBlocSorts(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer): Single;

// Bloc Encombrement (page 2, cadre uniquement) — dernier de la série cadre+en-têtes
// (Armures/Équipement/Armes/Sorts/Encombrement, CONTEXT.md §2.4). Contrairement aux 4
// précédents, ce bloc a des libellés de largeur variable (`PdfEcrit`), donc reprend
// `MinPolice`. Les valeurs (totaux d'encombrement) sont écrites bien plus loin dans la
// procédure, une fois la boucle de remplissage des tableaux passée — pas dans ce bloc.
Function PdfBlocEncombrement(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer): Single;

// Bloc Sorts (page 2, remplissage des données) — première des 4 boucles de
// remplissage à être séparée du passage unique d'origine sur Personnage.Equipement
// (Armes/Armures/Équipement-Divers/Sorts, CONTEXT.md §2.4 - décision du 15/08/2026 :
// 4 boucles indépendantes plutôt qu'un seul passage). Filtre sur TypeEquipSp et
// remplit les lignes du tableau dont le cadre est dessiné par PdfBlocSorts. Purement
// local : NbSort ne sert qu'à positionner les lignes dans cette boucle, personne
// d'autre ne le lit après dans la procédure principale (contrairement à EncArme/
// EncArmure/ArmureBonii/etc., qui restent dans PdfPersonnageCreationFeldo2P car
// réutilisés par l'Encombrement et DessinExplication).
Procedure PdfBlocSortsDonnees(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, Y, HauteurLigne: Single; MinPolice: Integer);

// Bloc Divers (page 2, remplissage des données) — deuxième des 4 boucles de remplissage
// à être séparée (CONTEXT.md §2.4). Filtre sur TypeEquipDI et remplit la liste Divers du
// cadre Équipement dessiné par PdfBlocEquipement, en basculant en deuxième demi-colonne
// au-delà de NbLignes lignes (voir le commentaire de PdfBlocEquipement sur la grille
// doublée — comportement préservé tel quel). Purement local : IndDivers ne sert qu'à
// positionner les lignes dans cette boucle, personne d'autre ne le lit après.
Procedure PdfBlocDiversDonnees(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; out EncDivers: Integer; MinPolice: Integer; var FabricationBonii: String);
// Encombrement total des objets confies a l'animal IdAnimal (PortePar), sans la reduction
// "Worn Items" : un objet confie n'est pas porte. CONTEXT.md 2.84.
// Encombrement brut d'UNE ligne (sans reduction Worn Items), utilise pour la charge d'un animal.
Function PdfEquipementEncombrementBrut(PersonnageEquipement: StructurePersonnageEquipement): Integer;
Function PdfAnimalCharge(Personnage: StructurePersonnage; IdAnimal: String): Integer;
// Libelle (catalogue si le code est un Trapping, sinon le code brut) et encombrement total
// (unitaire x quantite) d'une ligne Divers.
Function PdfDiversLibelle(PersonnageEquipement: StructurePersonnageEquipement): String;
Function PdfDiversEncombrement(PersonnageEquipement: StructurePersonnageEquipement): Integer;
Function PdfDiversTexteEnc(PersonnageEquipement: StructurePersonnageEquipement): String;

// Bloc Armes (page 2, remplissage des données) — troisième des 4 boucles de
// remplissage à être séparée (CONTEXT.md §2.4). Filtre sur TypeEquipWe et remplit le
// tableau dont le cadre est dessiné par PdfBlocArmes. Plus délicat que Sorts/Divers :
// FabricationBonii est accumulé par Armes ET Armures (les deux ajoutent au même texte
// d'explication affiché plus loin dans la page via FabricationDetail) - remonté en
// paramètre `var` plutôt que local, pour que les deux boucles s'y ajoutent sans
// s'écraser. EncArme et ArmeBonii sont remontés en `out` car réutilisés par le bloc
// Encombrement et DessinExplication, plus loin dans la procédure principale. BF (bonus
// Force) et TBonusCC/TBonusCT (bonus de dégât Corps-à-corps/Tir, déjà calculés plus
// haut dans la procédure principale) sont passés en lecture seule. NbArme, Quality
// restent purement locaux. ArmureBouclier (protection du bouclier, calculée ici quand
// une arme porte le bonus "protection") est désormais remonté en `out` lui aussi
// (15/08/2026, ajout du bloc "Armour Points") : il était déjà écrit mais jamais relu
// avant cet ajout - voir CONTEXT.md §2.4 - il sert maintenant à afficher la valeur du
// Bouclier dans le nouveau bloc PdfBlocArmourPoints.
Procedure PdfBlocArmesDonnees(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; BF, TBonusCC, TBonusCT: Integer; var FabricationBonii: String; out EncArme: Integer; out ArmeBonii: String; out ArmureBouclier: Integer; MinPolice: Integer; AsterisqueParPiece: TStringList);

// Bloc Armures (page 2, remplissage des données) — dernière des 4 boucles de
// remplissage à être séparée (CONTEXT.md §2.4). Filtre sur TypeEquipAR (armure
// détaillée) ou TypeEquipARS (armure simplifiée) selon `ArmureSet`, remplit le
// tableau dont le cadre est dessiné par PdfBlocArmures. Comme Armes, partage
// `FabricationBonii` (paramètre `var`, les deux boucles y ajoutent sans s'écraser).
// EncArmure, ArmureBras/Corps/Jambe/Tete et ArmureBonii sont remontés en `out` car
// réutilisés par le bloc Encombrement et DessinExplication, plus loin dans la
// procédure principale. NbArmure, Quality, Enc/EncP restent purement locaux. C'était
// la dernière clause (devenue unique, donc simple `if`) de la boucle partagée
// d'origine sur Personnage.Equipement - **les 4 boucles de remplissage sont
// maintenant toutes extraites.**
Procedure PdfBlocArmuresDonnees(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; ArmureSet: Boolean; var FabricationBonii: String; out EncArmure, ArmureBras, ArmureCorps, ArmureJambe, ArmureTete: Integer; out ArmureBonii: String; MinPolice: Integer; AsterisqueParEquipement: TStringList);

// Bloc DessinExplication (page 2, cadre + contenu) — dernier chantier convenu avec
// Nono (CONTEXT.md §2.4) : le cadre légendant les bonus/malus accumulés d'Armures,
// d'Armes et de Fabrication (qualité des objets). Contrairement aux 4 boucles de
// remplissage, ce bloc dessine SON PROPRE cadre (comme les blocs "cadre uniquement"
// PdfBlocArmures/etc.) et remplit son contenu dans la même procédure - il n'y a rien
// à séparer entre cadre et données ici. `ArmureBonii`/`ArmeBonii`/`FabricationBonii`
// sont reçus déjà construits et dédoublonnés (le dédoublonnage a lieu en amont, dans
// PdfBlocArmuresDonnees/PdfBlocArmesDonnees/FabricationDetail - rien à refaire ici,
// ce bloc ne fait que lire et afficher). `NbBonus` est un compteur de ligne PARTAGÉ
// entre les trois sections (Armures puis Armes puis Fabrication) : il n'est PAS
// réinitialisé entre les sections, contrairement à `NbSort`/`IndDivers`/etc. dans les
// autres blocs - comportement préservé tel quel. `NbLoca`/`IndLoca`/`PArmureBonus`/
// `PArmeBonus`/`PFabrication`/`TxtBonus` deviennent purement locaux (c'était leur
// dernier usage dans la procédure principale) ; `LocData` reste dans le bloc `var`
// principal car réutilisé ailleurs (bloc Métiers, plus haut dans la procédure).
// **Incohérence pré-existante repérée, signalée à Nono, pas corrigée** : l'en-tête de
// la section Fabrication est écrit à l'abscisse fixe 15 (`PdfPage.WriteText(15, ...)`)
// alors que les en-têtes Armures/Armes et toutes les lignes de détail utilisent
// `XGauche + 4` - l'en-tête Fabrication est donc décalé par rapport au reste du bloc.
// Reproduit à l'identique (littéral 15 conservé).
Procedure PdfBlocDessinExplication(PdfPage: TPDFPage; XGauche, XDroite, YHaut, YBas, HauteurLigne: Single; ArmureBonii, ArmeBonii, FabricationBonii: String);

// Bloc Armour Points (page 2, cadre + contenu) — silhouette/valeurs de protection par
// emplacement du corps (Tête/Bras/Corps/Jambes/Bouclier), demandée par Nono le
// 15/08/2026 pour compléter Feldo2P (absente jusqu'ici, contrairement à l'ancienne
// PdfPersonnageCreation - voir CONTEXT.md §2.4). Positionnée sous le bloc Encombrement.
// Comme DessinExplication, ce bloc dessine son propre "cadre" (ici une image + des
// petits encadrés vectoriels) et son contenu dans la même procédure. Contrairement aux
// autres blocs, il combine une image de fond (SHADOW.png, silhouette du personnage,
// chargée par l'appelant via PdfDoc.Images.AddFromFile car PdfDoc n'est pas accessible
// depuis un bloc séparé - seul l'identifiant d'image `PdfImgShadow` est passé ici) et
// des encadrés vectoriels dessinés par l'utilitaire déjà partagé `PdfEncadre`
// (PdfUtils.pas) - un appel par emplacement, dont un avec `Bouclier = true` qui dessine
// un losange au lieu d'un rectangle. (X, Y) est le coin bas-gauche de l'image (55x72mm,
// taille identique à l'ancien PDF), exactement comme (135,190) l'était dans l'ancien
// PdfPersonnageCreation - tous les décalages internes ci-dessous reproduisent à
// l'identique les coordonnées absolues de l'ancien bloc, simplement traduites par
// rapport à ce nouveau point d'ancrage (même tailles, mêmes écarts relatifs, validé
// avec Nono). PdfFontBack/PdfFontValue sont des globales (ChargeConstantes.pas), pas
// des paramètres - PdfEncadre écrit ses étiquettes avec la police d'en-tête
// (PdfFontBack, Carlson Bold 10, comme dans l'ancien PDF) puis on repasse en
// PdfFontValue/Arial 9 pour écrire les valeurs numériques, à l'identique de l'ancien
// bloc.
// AsterisqueArmure (17/08/2026, CONTEXT.md §2.7 étape 9) : un seul marqueur numéroté
// "(N)" pour tout le bloc (pas un par case, choix de Nono "on va pas faire compliqué") -
// affiché dans le coin haut-droit du cadre, même format/numérotation que les autres
// sources d'astérisques du PDF (voir PdfPersonnageMutationAsterisques). Chaîne vide =
// rien à afficher.
Procedure PdfBlocArmourPoints(PdfPage: TPDFPage; PdfImgShadow: Integer; X, Y: Single; ArmureTete, ArmureBras, ArmureCorps, ArmureJambe, ArmureBouclier, DegatRecu: Integer; AsterisqueArmure: String);

// Petite table des mutations obtenues (CONTEXT.md §2.7, étape 9) - à droite du bloc Armour
// Points, capacité fixe à NbLignes (les mutations les plus anciennes sont omises au-delà).
// AsterisqueParMutation (Name=CodeCorruption / Value="(N)", voir PdfPersonnageMutationAsterisques)
// affiche à côté du nom le même numéro que celui renvoyé sur la caractéristique/compétence
// affectée, même principe que Talents/Armures.
Function PdfBlocMutations(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; AsterisqueParMutation: TStringList): Single;

// Brique 2 (tableau de données, CONTEXT.md §2.4) — DessinerTableau est générique : elle
// dessine le cadre et le contenu à partir de Tableau (mise en page) et Donnees (valeurs déjà
// préparées), sans rien connaître du sens métier des champs. Elle renvoie le Y du bas du
// tableau, pour que l'appelant enchaîne le bloc suivant (comme DessinDebutHautComp).
// Les deux orientations (orColonne : Caractéristiques ; orLigne : Compétences) sont
// implémentées.
Function DessinerTableau(PdfPage: TPDFPage; const Tableau: TPdfTableau; const Donnees: TPdfRecordSet): Single;

// Prototype de préparation pour le tableau des Caractéristiques : transforme les données du
// personnage (via PdfPersonnageAttribut et ListMetierAttribut) en TPdfRecordSet prêt à être
// dessiné par DessinerTableau, sans aucun calcul de position/dessin.
// AnnotationMutation (ajouté le 17/08/2026, CONTEXT.md §2.7 étape 9) : Name=CodeAttribut /
// Value=" (N)" à concaténer à l'annotation existante (même mécanisme que AnnotationArmure
// pour les compétences, voir PdfPreparerRecordSetCompetencesBase) - calculée par
// PdfPersonnageMutationAsterisques.
Function PdfPreparerRecordSetCaracteristiques(Personnage: StructurePersonnage; PMetier: StructureMetier; AnnotationMutation: TStringList): TPdfRecordSet;

// Prépare le tableau des compétences de base (première grille de la page, celle qui liste
// ListPage). Renvoie aussi, en paramètres out, les totaux de 5 compétences (Esquive, Calme,
// Résistance, Commandement, Intuition) réutilisés plus loin dans PdfPersonnageCreationFeldo2P
// pour un autre encart, et ListPris (la liste des codes de compétences déjà affichées, pour
// que le tableau des compétences groupées ne les propose pas une deuxième fois) — c'est le
// même calcul que faisait l'ancien code, juste extrait ici.
Function PdfPreparerRecordSetCompetencesBase(Personnage: StructurePersonnage; PMetier: StructureMetier; ListPage: TStringList; AnnotationArmure: TStringList; out TotalEsquive, TotalCalme, TotalResitance, TotalCommandement, TotalIntuition: Integer; out ListPris: String): TPdfRecordSet;

// Prépare le tableau des compétences groupées (deuxième grille) : d'abord les compétences de
// ListCompetence déjà augmentées et pas déjà affichées dans le tableau de base (ListPris),
// puis, tant qu'il reste de la place (CapaciteMax lignes au total), les compétences
// accessibles via le métier mais pas encore augmentées, grisées. Contrairement au tableau de
// base, ni Nom ni Attribut n'ont de police "accent" ici (toujours police de valeur normale).
// Note : corrige un bug de l'ancien code, qui utilisait par erreur une variable non
// réassignée (`Comp`, reliquat du tableau précédent) pour l'astérisque de bonus — remplacé
// ici par le code de la compétence réellement affichée sur la ligne (validé avec Nono).
Function PdfPreparerRecordSetCompetencesGroupees(Personnage: StructurePersonnage; ListPris: String; CapaciteMax: Integer; AnnotationArmure: TStringList): TPdfRecordSet;

implementation

Function PdfNbTalentsAcquis(Personnage: StructurePersonnage): Integer; forward;

Procedure PdfPersonnageCompetenceTri(ListPage: TStringList);
  var
    ListComp:    TStringList;
    ListTri:     TStringList;
    IndC:        Integer;
    Comp:        String;
    PCompetence: StructureCompetence;
  Begin
    ListComp   := TStringList.Create;
    ListTri    := TStringList.Create;

    // Competences de base : balise <Basic> des competences et specialisations (donnee).
    for PCompetence in ListCompetence do
      if PCompetence.DeBase and (ListComp.IndexOf(PCompetence.CodeCompetence) < 0) then
        ListComp.Add(PCompetence.CodeCompetence);

    // chercher les libellés
    for IndC := 0 to ListComp.count-1 do
      begin
        Comp        := ListComp[IndC];
        PCompetence := ChercheCompetence(Comp);
        ListTri.Add(PCompetence.Libelle+Separateurtabulation+PCompetence.CodeCompetence);
      end;
    ListTri.Sort;
    ListComp.Destroy;

    // ajouter dans la liste finale
    for IndC := 0 to ListTri.count-1 do
      begin
        Comp        := ExtractStringAfter(ListTri[IndC],Separateurtabulation);
        ListPage.Add(Comp);
      end;
    ListTri.Destroy;
end;

Function PdfPersonnageRemplaceBonus(Personnage: StructurePersonnage; ChW: String): String;
  Var
    Res: String;
    Donnee: StructureDonnee;
    Bonus: String;
  Begin
    Res    := ChW;
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracCC, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracCC)+')',       InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracCC+')',  InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracCT, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracCT)+')',       InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracCT+')',  InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracF, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracF)+')',        InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracF+')',   InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracE, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracE)+')',        InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracE+')',   InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracI, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracI)+')',        InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracI+')',   InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracAg, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracAg)+')',       InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracAg+')',  InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracDex, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracDex)+')',      InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracDex+')', InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracInt, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracInt)+')',      InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracInt+')', InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracFM, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracFM)+')',       InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracFM+')',  InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Donnee := PdfPersonnageAttribut(Personnage, ConstCaracSoc, Bonus);
    Res    := StringReplace(Res, '('+CodeSansLivre(ConstCaracSoc)+')',      InttoStr(Donnee.Total), [rfIgnoreCase]);
    Res    := StringReplace(Res, '('+ConstBonusCaracSoc+')', InttoStr(floor(Donnee.Total/10)), [rfIgnoreCase]);
    Result := Res;
  end;


Function PdfPersonnageTalent(Personnage: StructurePersonnage; Talent: String; out NivMetier: Integer): StructureDonnee;
  var
    PersonnageTalent: StructurePersonnageTalent;
    PMetierTalent:    StructureMetierTalent;
    Res:              StructureDonnee;
  begin
    NivMetier        := 0;
    Res.Base         := 0;
    Res.Augmentation := 0;
    for PersonnageTalent in Personnage.CreationTalent do
      if MemeTalent(Talent, PersonnageTalent.CodeTalent) then
        Res.Augmentation := Res.Augmentation + PersonnageTalent.Valeur;
    For PersonnageTalent in Personnage.AugmentationTalent do
      if MemeTalent(Talent, PersonnageTalent.CodeTalent) then
        Res.Augmentation := Res.Augmentation + PersonnageTalent.Valeur;
    For PMetierTalent in ListMetierTalent do
      if CompareRechercheValeur(PMetierTalent.CodeMetier, Personnage.MetierEnCours.CodeMetier) then
        if MemeTalent(PMetierTalent.CodeTalent, Talent) then
          begin
            NivMetier := PMetierTalent.NiveauMetier;
            break;
          end
       else if Pos(ValeurGenerique, PMetierTalent.CodeTalent) > 0 then
         if RadicalTalent(PMetierTalent.CodeTalent) = RadicalTalent(Talent) then
           begin
             NivMetier := PMetierTalent.NiveauMetier;
             break;
           end;
    // Abs() : une Vertu nommee (Knightly Virtue, Virtue of the Quest - CONTEXT.md 2.78)
    // porte un NbAugm negatif volontaire (deja comptee en cout ailleurs, ou gratuite),
    // jamais lu comme un vrai total negatif - meme correctif que l'affichage du "Number"
    // au rechargement (XmlChargePersonnage). Sans effet sur les autres talents, dont
    // Augmentation n'est jamais negatif.
    Res.Total := Abs(Res.Base + Res.Augmentation);
    Result := res;
  end;


Function PdfPersonnageCompetence(Personnage: StructurePersonnage; Competence: String; out NivMetier: Integer): StructureDonnee;
  var
    PersonnageCompetence: StructurePersonnageCompetence;
    PCompetence:          StructureCompetence;
    Res:                  StructureDonnee;
    DonneeAttribut:       StructureDonnee;
    CodeCompetence:       String;
    Bonus:                String;
    UniqueCompetence: Integer;
    PrisesV2:         Integer;
    AttributPropre:   String;
  begin
    Res.Base         := 0;
    Res.Augmentation := 0;
    NivMetier        := 0;
    PCompetence      := ChercheCompetence(Competence);
    // Attribut de la specialisation elle-meme (ex. Trade (Cook) = Int, la mere Trade (Various)
    // n'en a pas) : prioritaire sur celui de la mere.
    AttributPropre   := PCompetence.CodeAttribut;
    if PCompetence.SousCompetence then
      begin
        // Lien explicite (CONTEXT.md 2.67) prioritaire sur la deduction par radical - seul
        // repli quand <Generique> n'est pas renseigne.
        if PCompetence.CodeGenerique <> '' then
          CodeCompetence := PCompetence.CodeGenerique
        else
          CodeCompetence := CodeGeneriqueDeduit(PCompetence.CodeCompetence);
        PCompetence    := ChercheCompetence(CodeCompetence);
      end;
    if AttributPropre = '' then
      AttributPropre := PCompetence.CodeAttribut;
    DonneeAttribut := PdfPersonnageAttribut(Personnage, AttributPropre, Bonus);
    Res.Base       := DonneeAttribut.Total;
    // V2 : les valeurs de creation sont un nombre de PRISES (1 = acquise, 2 = +10 %) ; la
    // carriere compte la prise de la race (2 = race + carriere) : on garde la plus grande.
    PrisesV2 := 0;
    for PersonnageCompetence in Personnage.CreationCompetence35 do
      if CompareRechercheValeur(Competence, PersonnageCompetence.CodeCompetence) then
        begin
          if ValVersion = 'WFRP2' then
            PrisesV2 := Max(PrisesV2, PersonnageCompetence.Valeur)
          else
            Res.Augmentation := Res.Augmentation + PersonnageCompetence.Valeur;
          break;
        end;
    for PersonnageCompetence in Personnage.CreationCompetence40 do
      if CompareRechercheValeur(Competence, PersonnageCompetence.CodeCompetence) then
        begin
          if ValVersion = 'WFRP2' then
            PrisesV2 := Max(PrisesV2, PersonnageCompetence.Valeur)
          else
            Res.Augmentation := Res.Augmentation + PersonnageCompetence.Valeur;
          break;
        end;
    if PrisesV2 > 1 then
      Res.Augmentation := Res.Augmentation + 10 * (PrisesV2 - 1);
    For PersonnageCompetence in Personnage.AugmentationCompetence do
      if CompareRechercheValeur(Competence, PersonnageCompetence.CodeCompetence) then
        begin
          Res.Augmentation := Res.Augmentation + PersonnageCompetence.Valeur;
          break;
        end;
    For PersonnageCompetence in Personnage.MetierCompetence do
      if CompareRechercheValeur(Competence, PersonnageCompetence.CodeCompetence) then
        begin
          NivMetier := PersonnageCompetence.Valeur;
          break;
        end;

    Res.Total := Res.Base + Res.Augmentation;

    // Tous les modificateurs de competence (mutation, affliction, appartenance, talent, arme,
    // armure, fabrication) viennent du collecteur unique. Les qualites d'armure a malus ne
    // s'appliquent pas au Total (colonne "avec equipement", decision du 12/09/2026).
    UniqueCompetence := PersonnageCompetenceModificateur(Personnage, Competence);
    Res.Total := Res.Total + UniqueCompetence;

    Result := res;
  end;


Function PdfPersonnageAttribut(Personnage: StructurePersonnage; Attribut: String; var Bonus: String): StructureDonnee;
  var
    PersonnageAttribut: StructurePersonnageAttribut;
    Res:                StructureDonnee;
    PRaceAttribut:      StructureRaceAttribut;
    Unique:             Integer;
  begin
    Res.Base         := 0;
    Res.Augmentation := 0;

    PRaceAttribut := ChercheRaceAttribut(Personnage.Race, Attribut);
    // V1 : la valeur enregistree a la creation contient deja la base de la race
    if ValVersion <> 'WFRP1' then
      Res.Base    := StrToIntDef(ExtractStringAfter(PRaceAttribut.CalculRace,'+'),0);

    Bonus := '';
    for PersonnageAttribut in Personnage.CreationAttribut do
      if CompareRechercheValeur(PersonnageAttribut.CodeAttribut, Attribut) then
        begin
          // V2 : Blessures et Destin sont stockes en jet de d10 ; la table de la race
          // ("1-3: 11; 4-6: 12...") donne la valeur (meme regle que WinPersonnage).
          if Pos(':', PRaceAttribut.CalculRace) > 0 then
            Res.Base := Res.Base + ValeurTableD10(PRaceAttribut.CalculRace, PersonnageAttribut.Valeur)
          else
            Res.Base := Res.Base + PersonnageAttribut.Valeur;
          if PersonnageAttribut.Bonus <> '' then
            Bonus := PdfBonusAttributFiltrer(Personnage, PersonnageAttribut.Bonus);
          break;
        end;

    // ORDRE DES ARGUMENTS : meme sens que la boucle sur CreationAttribut plus haut.
    // CompareRechercheValeur n'est pas symetrique, sa tolerance au code nu ne porte que
    // sur le SECOND argument : le code stocke (prefixe a l'ecriture, chargepersonnage.pas)
    // va en PREMIER, le parametre Attribut en SECOND. Il arrive nu depuis
    // PdfPersonnageRemplaceBonus, qui passe les constantes ConstCaracXxx ('ATTR_WS'...) :
    // en sens inverse aucune ligne ne matchait, Res.Augmentation restait a 0, et la valeur
    // substituee dans les TEXTES du PDF etait amputee des augmentations achetees a l'XP
    // (les tableaux, eux, passent un code prefixe et etaient justes). CONTEXT.md 2.49.
    For PersonnageAttribut in Personnage.AugmentationAttribut do
      if CompareRechercheValeur(PersonnageAttribut.CodeAttribut, Attribut) then
        Res.Augmentation := Res.Augmentation + PersonnageAttribut.Valeur;
    // V2 : avance gratuite de creation (liste dediee, voir chargepersonnage.pas)
    Res.Augmentation := Res.Augmentation + PersonnageAvanceGratuite(Personnage, Attribut);

    // Toutes les sources possedees (talent, mutation, affliction, maladie, appartenance, arme,
    // armure, fabrication) viennent du collecteur unique.
    Unique := PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, Attribut);
    Res.Base := Res.Base + Unique;

    // Signe astral (Archives of the Empire II p.39) : +2 / -3 en caracteristique, calcule au vol.
    Res.Base := Res.Base + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, Attribut);

    Res.Total := Res.Base + Res.Augmentation;
    Result := res;
  end;

// Etape d : bonus de competence propre a UNE arme (ModifyWeapon, filtre par type d'arme), toutes
// sources possedees. Une seule fonction pour les deux gabarits du PDF.
Function PdfPersonnageArmeModif(Personnage: StructurePersonnage; PArme: StructureArme): Integer;
  begin
    Result := 0;
    if Trim(PArme.TypeArme) = '' then
      Exit;
    Result := PersonnageModificateurUnique(Personnage, ConstXmlModifieArme, PArme.TypeArme, PArme.CodeCompetence);
  end;

// Etape d : Points d'Armure donnes par les sources possedees (mutation, talent, fabrication
// portee, ...) sur un emplacement, pour les deux gabarits.
Function PdfPersonnageArmureModif(Personnage: StructurePersonnage; Emplacement: String): Integer;
  begin
    // Bouclier : un seul sert a la fois pour parer, on retient la meilleure piece (regles relues par Nono le 04/10/2026)
    Result := PersonnageModificateurUnique(Personnage, ConstXmlModifieArmure, Emplacement, '', False, Emplacement = BonusBouclier);
  end;

Function PersonnageTalentEffet(Personnage: StructurePersonnage; Cible: String): Integer;
  var
    PersonnageTalent: StructurePersonnageTalent;
    IndiceEffet:      Integer;
    AttributDonnee:   StructureDonnee;
    Bonus:            String;
  begin
    Result := 0;
    for PersonnageTalent in Personnage.CreationTalent do
      for IndiceEffet := 0 to (ListTalentEffet.Count - 1) do
        if CompareRechercheValeur(ListTalentEffet[IndiceEffet].CodeTalent, PersonnageTalent.CodeTalent)
           and (ListTalentEffet[IndiceEffet].Cible = Cible) then
          case ListTalentEffet[IndiceEffet].Forme of
            ConstFormeEffetAdditif:
              Result := Result + ListTalentEffet[IndiceEffet].Facteur * PersonnageTalent.Valeur;
            ConstFormeEffetProportionnelAttribut:
              begin
                AttributDonnee := PdfPersonnageAttribut(Personnage, ListTalentEffet[IndiceEffet].Carac, Bonus);
                Result := Result + Floor(AttributDonnee.Total/10) * PersonnageTalent.Valeur * ListTalentEffet[IndiceEffet].Facteur;
              end;
            ConstFormeEffetDrapeau:
              Result := 1;
          end;
    for PersonnageTalent in Personnage.AugmentationTalent do
      for IndiceEffet := 0 to (ListTalentEffet.Count - 1) do
        if CompareRechercheValeur(ListTalentEffet[IndiceEffet].CodeTalent, PersonnageTalent.CodeTalent)
           and (ListTalentEffet[IndiceEffet].Cible = Cible) then
          case ListTalentEffet[IndiceEffet].Forme of
            ConstFormeEffetAdditif:
              Result := Result + ListTalentEffet[IndiceEffet].Facteur * PersonnageTalent.Valeur;
            ConstFormeEffetProportionnelAttribut:
              begin
                AttributDonnee := PdfPersonnageAttribut(Personnage, ListTalentEffet[IndiceEffet].Carac, Bonus);
                Result := Result + Floor(AttributDonnee.Total/10) * PersonnageTalent.Valeur * ListTalentEffet[IndiceEffet].Facteur;
              end;
            ConstFormeEffetDrapeau:
              Result := 1;
          end;
  end;

Function PersonnageTalentEffetRang(Personnage: StructurePersonnage; Cible: String): Integer;
  var
    PersonnageTalent: StructurePersonnageTalent;
    IndiceEffet:      Integer;
  begin
    Result := 0;
    for PersonnageTalent in Personnage.CreationTalent do
      for IndiceEffet := 0 to (ListTalentEffet.Count - 1) do
        if CompareRechercheValeur(ListTalentEffet[IndiceEffet].CodeTalent, PersonnageTalent.CodeTalent)
           and (ListTalentEffet[IndiceEffet].Cible = Cible) then
          Result := Result + PersonnageTalent.Valeur;
    for PersonnageTalent in Personnage.AugmentationTalent do
      for IndiceEffet := 0 to (ListTalentEffet.Count - 1) do
        if CompareRechercheValeur(ListTalentEffet[IndiceEffet].CodeTalent, PersonnageTalent.CodeTalent)
           and (ListTalentEffet[IndiceEffet].Cible = Cible) then
          Result := Result + PersonnageTalent.Valeur;
  end;

Function PersonnageCorruptionTotal(Personnage: StructurePersonnage): Integer;
  var
    Bonus:            String;
    BE:               Integer;
    BFM:              Integer;
    AmePure:          Integer;
    AttributDonnee:   StructureDonnee;
    PAttribut:        StructureAttribut;
  begin
    // PdfPersonnageAttribut compare en interne le code d'attribut passé en argument à
    // PTalent.Attribut (liste ';' de codes AVEC préfixe livre, ex. "RULES-ATTR_WP") via une
    // simple égalité de chaîne (pas CompareRechercheValeur) - il faut donc lui donner un code
    // complet avec préfixe, pas la constante nue ConstCaracE/ConstCaracFM ('ATTR_T'/'ATTR_WP'),
    // sinon les bonus d'attribut donnés par certains talents sont silencieusement ignorés (bug
    // trouvé le 16/08/2026 : WinPersonnage affichait 7 alors que le PDF, qui utilise
    // PAttribut.CodeAttribut complet via ListeAttribut, affichait 8). ChercheAttribut fait le
    // même travail que ChercheRaceAttribut/CompareRechercheValeur pour retrouver le code complet
    // à partir du code nu.
    PAttribut      := ChercheAttribut(ConstCaracE);
    AttributDonnee := PdfPersonnageAttribut(Personnage, PAttribut.CodeAttribut, Bonus);
    BE             := AttributDonnee.Total;
    PAttribut      := ChercheAttribut(ConstCaracFM);
    AttributDonnee := PdfPersonnageAttribut(Personnage, PAttribut.CodeAttribut, Bonus);
    BFM            := AttributDonnee.Total;

    AmePure := PersonnageTalentEffet(Personnage, ConstCibleEffetAmePure);

    Result := Floor(BE/10) + Floor(BFM/10) + AmePure;
  end;

Procedure PdfEcritTient(PdfPage: TPDFPage; X, XMax, Y: Single; Texte: String); forward;
Function PdfTeinte(Couleur: TARGBColor): TARGBColor; forward;
Procedure PdfStyleFond(PdfPage: TPDFPage; X1, X2, YHaut, YBas: Single; Couleur: TARGBColor); forward;
Procedure PdfStyleTitre(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single); forward;
Procedure PdfStyleEntete(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single); forward;
Procedure PdfStyleZebra(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single; PremiereLigne, DerniereLigne: Integer); forward;
Procedure PdfStyleEncre(PdfPage: TPDFPage); forward;
Procedure PdfStyleCadrePage(PdfPage: TPDFPage); forward;
Procedure PdfStylePied(PdfPage: TPDFPage; Texte: String); forward;
Procedure PdfStyleLosange(PdfPage: TPDFPage; XC, YC, R: Single); forward;
Procedure PdfStyleBloc(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single; NbRangs: Integer); forward;
Procedure PdfTitreCentre(PdfPage: TPDFPage; Min, Max, Y: Single; Texte: String); forward;
Procedure PdfEcritTitre(PdfPage: TPDFPage; X, Y: Single; Texte: String); forward;
Procedure PdfCentreValeur(PdfPage: TPDFPage; Min, Max, Y: Single; Texte: String); forward;
Procedure PdfStyleEtiquette(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single); forward;
Procedure PdfStyleValeur(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single); forward;
Procedure PdfValeurGras(PdfPage: TPDFPage; Actif: Boolean); forward;

// Ecrit le panneau Entete de la page 1 du PDF normal (nom, espece, classe, metier, schema, statut, details
// physiques). Extrait de PdfPersonnageCreation, CONTEXT.md §2.4.
Procedure PdfNormalEntete(PdfPage: TPDFPage; Personnage: StructurePersonnage; MinPolice: Integer);
  var
    PRace:          StructureRace;
    PMetier:        StructureMetier;
    PMetierNiveau:  StructureMetierNiveau;
    PersonnageMetier: StructurePersonnageMetier;
    DernierMetier:  String = '';
    LocData:        String;
  begin
    PRace          := ChercheRace(Personnage.Race);
    LocData        := '';
    for PersonnageMetier in Personnage.MetierAncien do
      begin
        if (DernierMetier <> PersonnageMetier.CodeMetier) then
          begin
            PMetier       := ChercheMetier(PersonnageMetier.CodeMetier);
            if Locdata <> '' then
              LocData     := LocData + ' - ';
            LocData       := LocData + PMetier.Libelle + ':';
            DernierMetier := PersonnageMetier.CodeMetier;
          end
        else if LocData <> '' then
          LocData         := LocData + ',';
         LocData          := LocData + IntToStr(PersonnageMetier.NiveauMetier);
      end;
    PMetier        := ChercheMetier(Personnage.MetierEnCours.CodeMetier);
    PMetierNiveau  := ChercheMetierNiveau(Personnage.MetierEnCours.CodeMetier, Personnage.MetierEnCours.NiveauMetier);

    PdfPage.WriteText( 50, 246, Personnage.NomPersonnage);                               // Nom
    PdfPage.WriteText(118, 246, PersonnageRaceLibelle(Personnage, PRace.Libelle));                                      // Race
    PdfPage.WriteText(165, 246, GetTexteLibelle(PMetier.LibelleGroupe));                 // Classe
    if Trim(Personnage.Appartenance) <> '' then
      PdfPage.WriteText( 50, 241, PMetier.Libelle + ' (' + LibelleAppartenances(Personnage.Appartenance) + ')')
    else
      PdfPage.WriteText( 50, 241, PMetier.Libelle);                                // Métier
    PdfPage.WriteText(135, 241, IntToStr(Personnage.MetierEnCours.NiveauMetier)+' - '+ LibelleNiveauSelonSexe(PMetierNiveau, Personnage.SexeV2));     // Niveau
    PdfPage.WriteText( 50, 236, LocData);     // Schéma
    // Prefixe RULES- ajoute le 12/09/2026 : SalaireMetier ('TIERS_BRASS 2', etc.) est stocke
    // NU dans le Xml (xmlexportimport.pas), sans prefixe de livre, alors que le libelle
    // catalogue est RULES-TIERS_BRASS/SILVER/GOLD (seul livre a les definir) - VerifieRecherche
    // exige que LivreRecherche = LivreValeur (chargeconstantes.pas), pas seulement le code, donc
    // sans prefixe le code brut "TIERS_BRASS 2" s'affichait tel quel (meme famille de bug que
    // CONTEXT.md 2.49). Signale par Nono sur les deux PDF.
    PdfPage.WriteText(165, 236, GetTexteLibelle('RULES-' + StatutAdapte(PMetierNiveau.SalaireMetier, PMetier.CodeMetier, Personnage.Race, Personnage.ChoixAdaptation), '', ' '));  // Salaire
    // Details physiques (WinPhysique) : rien d'ecrit tant qu'ils n'ont pas ete definis
    if Personnage.Age > 0 then
      PdfPage.WriteText( 30, 231, IntToStr(Personnage.Age));                                // Age
    if Personnage.Height > 0 then
      PdfPage.WriteText( 78, 231, FormateTaille(Personnage.Height, Personnage.HeightUnit));                        // Taille
    PdfEcrit(PdfPage, 118, 164, 231, Personnage.HairColors, MinPolice);                       // Cheveux
    PdfEcrit(PdfPage, 165, 195, 231, Personnage.EyeColors, MinPolice);                        // Yeux
  end;

// Ecrit les valeurs du tableau Caracteristiques de la page 1 du PDF normal (base / avancees / total).
// Extrait de PdfPersonnageCreation, CONTEXT.md §2.4.
Procedure PdfNormalCaracteristiques(PdfPage: TPDFPage; Personnage: StructurePersonnage);
  var
    Ind:            Integer;
    PAttribut:      StructureAttribut;
    AttributDonnee: StructureDonnee;
    Bonus:          String;
  begin
    for Ind := 1 to 10 do
      begin
        PAttribut      := ListeAttribut[Ind-1];
        AttributDonnee := PdfPersonnageAttribut(Personnage, PAttribut.CodeAttribut, Bonus);
        PdfPage.WriteText(26+(Ind*6.5), 210, IntToStr(AttributDonnee.Base));        // Base
        if AttributDonnee.Augmentation <> 0 then
          PdfPage.WriteText(26+(Ind*6.5), 203, IntToStr(AttributDonnee.Augmentation));// Bonus
        PdfPage.WriteText(26+(Ind*6.5), 195, IntToStr(AttributDonnee.Total));       // Total
        //if TabAttribut.Cells[Ind+1, LigAttAsterisc] <> '' then
        //  begin
        //    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 5);
        //    PdfPage.WriteText(29+(Ind*6.5), 198, '('+TabAttribut.Cells[Ind+1, LigAttAsterisc]+')'); // Talent
        //    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        //  end;

      end;
  end;

// Ecrit les valeurs des panneaux Destin, Resilience, Experience et Mouvement de la page 1 du PDF normal.
// Extrait de PdfPersonnageCreation, CONTEXT.md §2.4.
Procedure PdfNormalDestinXpMouvement(PdfPage: TPDFPage; Personnage: StructurePersonnage; Chance, Determine, Mouv, BonusSprint: Integer);
  var
    AttributDonnee: StructureDonnee;
    Bonus:          String;
  begin
    // Destin
    AttributDonnee := PdfPersonnageAttribut(Personnage, ConstCaracDestin, Bonus);
    PdfPage.WriteText(115, 216, IntToStr(AttributDonnee.Total));          // Destin
    PdfPage.WriteText(115, 210, IntToStr(Chance));                        // Chance

    // Destin
    AttributDonnee := PdfPersonnageAttribut(Personnage, ConstCaracResil, Bonus);
    PdfPage.WriteText(128, 210, IntToStr(AttributDonnee.Total));          // Résilience
    PdfPage.WriteText(142, 210, IntToStr(Determine));                     // Détermination

    // Expérience
    PdfCentre(PdfPage,165,176,210,IntToStr(Personnage.XpTotal));                       // Total Xp
    PdfCentre(PdfPage,176,185,210,IntToStr(Personnage.XpTotal - personnage.XpActuel)); // Utilisé
    PdfCentre(PdfPage,185,194,210,IntToStr(Personnage.XpActuel));                      // Restant

    // Mouvement
    PdfPage.WriteText(127, 194, IntToStr(Mouv));                              // Mouvement
    PdfPage.WriteText(157, 194, IntToStr(Mouv*2));                            // Marche
    PdfPage.WriteText(188, 194, IntToStr((Mouv + BonusSprint)*4));            // Course
  end;

// Dessine le gabarit statique de la page 2 du PDF normal (Armure, Equipement, Armes, Sorts... : traits et
// libelles, sans donnee du personnage). Extrait de PdfPersonnageCreation, CONTEXT.md §2.4.
Procedure PdfGabaritNormalPage2(PdfPage: TPDFPage; MinPolice: Integer);
  var
    Ind: Integer;
  begin
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);

    // Armure
      // H
    PdfPage.DrawLine(17,260,134,260,1);
    for ind := 0 to 4 do
      PdfPage.DrawLine(17,254 - (ind*5),134,254 - (ind*5),1);
      // V
    PdfPage.DrawLine(50,260,50,229,1);
    PdfPage.DrawLine(72,260,72,229,1);
    PdfPage.DrawLine(79,260,79,229,1);
    PdfPage.DrawLine(89,260,89,229,1);
      // T
    PdfCentre(PdfPage,17,134,262,GetTexteLibelle('RULES-PDF_ARMOUR1_ARMOUR'));
    PdfPage.WriteText(18,255,GetTexteLibelle('RULES-PDF_ARMOUR2_NAME'));
    PdfCentre(PdfPage,50,72,255,GetTexteLibelle('RULES-PDF_ARMOUR2_LOCATIONS'));
    PdfCentre(PdfPage,72,79,255,GetTexteLibelle('RULES-PDF_ARMOUR2_ENCUMBRANCE'));
    PdfCentre(PdfPage,79,89,255,GetTexteLibelle('RULES-PDF_ARMOUR2_ARMOURPOINT'));
    PdfPage.WriteText(90,255,GetTexteLibelle('RULES-PDF_ARMOUR2_QUALITIES'));
    // Equipement
      // H
    PdfPage.DrawLine(17,218,73,218,1);
    PdfPage.DrawLine(17,212,73,212,1);
      // V
    PdfPage.DrawLine(65,218,65,136,1);
      // T
    PdfCentre(PdfPage,17,73,220,GetTexteLibelle('RULES-PDF_TRAPPING1_TRAPPINGS'));
    PdfPage.WriteText(18,213,GetTexteLibelle('RULES-PDF_TRAPPING2_NAME'));
    PdfCentre(PdfPage,65,73,213,GetTexteLibelle('RULES-PDF_TRAPPING2_ENCUMBRANCE'));
    // Psychologie
      // H
    for ind := 0 to 2 do
      PdfPage.DrawLine(77,218 - (ind * 5),134,218 - (ind * 5),1);
    // T
    PdfCentre(PdfPage,77,134,220,GetTexteLibelle('RULES-PDF_PSYCHOLOGY'));
    // Corruption
      // H
    PdfPage.DrawLine(77,192,134,192,1);
      // T
    PdfCentre(PdfPage,77,134,194,GetTexteLibelle('RULES-PDF_CORRUPTION'));
    // Points d'Armure
    PdfCentre(PdfPage,138,194,262,GetTexteLibelle('RULES-PDF_ARMOURPOINT_ARMOURPOINT'));
    PdfEncadre(PdfPage, 145, 250, false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_HEAD'),'','01-09');
    PdfEncadre(PdfPage, 145, 229, false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_RIGHTARM1'),GetTexteLibelle('RULES-PDF_ARMOURPOINT_RIGHTARM2'),'25-44');
    PdfEncadre(PdfPage, 145, 207.5, false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_RIGHTLEG'),'','90-00');
    PdfEncadre(PdfPage, 145, 190, true, GetTexteLibelle('RULES-PDF_ARMOURPOINT_SHIELD'),'','');
    PdfEncadre(PdfPage, 184.5, 241, false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_LEFTARM1'),GetTexteLibelle('RULES-PDF_ARMOURPOINT_LEFTARM2'),'10-24');
    PdfEncadre(PdfPage, 184.5, 219.5, false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_BODY'),'','45-79');
    PdfEncadre(PdfPage, 184.5, 195.5, false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_LEFTLEG'),'','80-89');
    // Richesse
      // H
    for ind := 0 to 2 do
      PdfPage.DrawLine(77,167 - (ind * 11),102,167 - (ind * 11),1);
      // V
    PdfPage.DrawLine(88,167,88,136,1);
      // T
    PdfCentre(PdfPage,77,102,169,GetTexteLibelle('RULES-PDF_WEALTH1_WEALTH'));
    PdfPage.WriteText(78,160,GetTexteLibelle('RULES-PDF_WEALTH2_D'));
    PdfPage.WriteText(78,149,GetTexteLibelle('RULES-PDF_WEALTH3_SS'));
    PdfPage.WriteText(78,138,GetTexteLibelle('RULES-PDF_WEALTH4_GC'));
    // Encombrement
      // H
    for ind := 0 to 4 do
      PdfPage.DrawLine(106,167 - (ind * 6.1),134,167 - (ind * 6.1),1);
      // V
    PdfPage.DrawLine(120,167,120,136,1);
      // T
    PdfCentre(PdfPage,106,134,169,GetTexteLibelle('RULES-PDF_ENCUMBRANCE1_ENCUMBRANCE'));
    PdfPage.WriteText(107,163,GetTexteLibelle('RULES-PDF_ENCUMBRANCE2_ARMOUR'));
    PdfPage.WriteText(107,157,GetTexteLibelle('RULES-PDF_ENCUMBRANCE3_WEAPONS'));
    PdfPage.WriteText(107,151,GetTexteLibelle('RULES-PDF_ENCUMBRANCE4_TRAPPINGS'));
    PdfPage.WriteText(107,144.2,GetTexteLibelle('RULES-PDF_ENCUMBRANCE5_MAXENC'));
    PdfPage.WriteText(107,137.6,GetTexteLibelle('RULES-PDF_ENCUMBRANCE6_TOTAL'));
    // Blessure
      // H
    PdfPage.DrawLine(138,167,194,167,1);
    for ind := 1 to 4 do
      PdfPage.DrawLine(138,167 - (ind * 6.1),160,167 - (ind * 6.1),1);
      // V
    PdfPage.DrawLine(152,167,152,136,1);
    PdfPage.DrawLine(160,167,160,136,1);
      // T
    PdfCentre(PdfPage,138,160,169,GetTexteLibelle('RULES-PDF_WOUNDS1_WOUNDS'));
    PdfPage.WriteText(139,163,GetTexteLibelle('RULES-PDF_WOUNDS2_SB'));
    PdfPage.WriteText(139,157,GetTexteLibelle('RULES-PDF_WOUNDS3_TBX2'));
    PdfPage.WriteText(139,151,GetTexteLibelle('RULES-PDF_WOUNDS4_WPB'));
    PdfPage.WriteText(139,144.2,GetTexteLibelle('RULES-PDF_WOUNDS5_HARDY'));
    PdfPage.WriteText(139,137.6,GetTexteLibelle('RULES-PDF_WOUNDS6_WOUNDS'));
    // Armes
      // H
    for ind := 0 to 7 do
      PdfPage.DrawLine(17,125 - (ind*5),194,125 - (ind*5),1);
      // V
    PdfPage.DrawLine(66,125,66,85,1);
    PdfPage.DrawLine(79,125,79,85,1);
    PdfPage.DrawLine(90,125,90,85,1);
    PdfPage.DrawLine(108,125,108,85,1);
    PdfPage.DrawLine(128,125,128,85,1);
      // T
    PdfCentre(PdfPage,17,194,127,GetTexteLibelle('RULES-PDF_WEAPONS1_WEAPONS'));
    PdfPage.WriteText(18,121,GetTexteLibelle('RULES-PDF_WEAPONS2_NAME'));
    PdfCentre(PdfPage,66,79,121,GetTexteLibelle('RULES-PDF_WEAPONS2_GROUP'));
    PdfCentre(PdfPage,79,90,121,GetTexteLibelle('RULES-PDF_WEAPONS2_ENCUMBRANCE'));
    PdfCentre(PdfPage,90,108,121,GetTexteLibelle('RULES-PDF_WEAPONS2_RANGE'));
    PdfCentre(PdfPage,108,128,121,GetTexteLibelle('RULES-PDF_WEAPONS2_DAMAGE'));
    PdfPage.WriteText(129,121,GetTexteLibelle('RULES-PDF_WEAPONS2_QUALITIES'));
    // Sorts
      // H
    for ind := 0 to 8 do
      PdfPage.DrawLine(17,75 - (ind*5),194,75 - (ind*5),1);
      // V
    for ind := 0 to 4 do
      PdfPage.DrawLine(55 + (ind*15),75,55 + (ind*15),30,1);
    PdfPage.DrawLine(170,35,170,30,1);
    PdfPage.DrawLine(179,35,179,30,1);
      // T
    PdfCentre(PdfPage,17,194,77,GetTexteLibelle('RULES-PDF_SPELL1_SPELL'));
    PdfPage.WriteText(18,71,GetTexteLibelle('RULES-PDF_SPELL2_NAME'));
    PdfCentre(PdfPage,55,70,71,GetTexteLibelle('RULES-PDF_SPELL2_CN'));
    PdfCentre(PdfPage,70,85,71,GetTexteLibelle('RULES-PDF_SPELL2_RANGE'));
    PdfCentre(PdfPage,85,100,71,GetTexteLibelle('RULES-PDF_SPELL2_TARGET'));
    PdfCentre(PdfPage,100,115,71,GetTexteLibelle('RULES-PDF_SPELL2_DURATION'));
    PdfPage.WriteText(116,71,GetTexteLibelle('RULES-PDF_SPELL2_EFFECT'));
    PdfPage.WriteText(171,31,GetTexteLibelle('RULES-PDF_SPELL3_SIN'));
  end;

// Dessine le gabarit statique de la page 1 du PDF normal (traits et libelles, sans donnee du personnage).
// Extrait de PdfPersonnageCreation, CONTEXT.md §2.4. Les coordonnees suivent le fond BACK.png : rien
// ne se deplace ni ne s ajuste entre blocs.
Procedure PdfGabaritNormalPage1(PdfPage: TPDFPage; MinPolice: Integer);
  var
    Ind: Integer;
  begin
    // Écrire du texte sur la page PDF
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);

    // Haut
      // H
    PdfPage.DrawLine(17,235,194,235,1);
    PdfPage.DrawLine(17,240,194,240,1);
    PdfPage.DrawLine(17,245,194,245,1);
    PdfPage.DrawLine(105,250,105,240,1);
    PdfPage.DrawLine(105,235,105,230,1);
      // V
    PdfPage.DrawLine(149.5,250,149.5,245,1);
    PdfPage.DrawLine(149.5,240,149.5,230,1);
    PdfPage.DrawLine(61.5,235,61.5,230,1);
      // T
    PdfPage.WriteText( 18, 246, GetTexteLibelle('RULES-PDF_MAIN1_NAME'));
    PdfPage.WriteText(106.5, 246, GetTexteLibelle('RULES-PDF_MAIN1_SPECIES'));
    PdfPage.WriteText(151.5, 246, GetTexteLibelle('RULES-PDF_MAIN1_CLASS'));

    PdfPage.WriteText( 18, 241, GetTexteLibelle('RULES-PDF_MAIN2_CAREER'));
    PdfPage.WriteText(106.5, 241, GetTexteLibelle('RULES-PDF_MAIN2_CAREERLEVEL'));

    PdfPage.WriteText( 18, 236, GetTexteLibelle('RULES-PDF_MAIN3_CAREERPATH'));
    PdfPage.WriteText(151.5, 236, GetTexteLibelle('RULES-PDF_MAIN3_STATUS'));

    PdfPage.WriteText( 18, 231, GetTexteLibelle('RULES-PDF_MAIN4_AGE'));
    PdfPage.WriteText(63, 231, GetTexteLibelle('RULES-PDF_MAIN4_HEIGHT'));
    PdfPage.WriteText(106.5, 231, GetTexteLibelle('RULES-PDF_MAIN4_HAIR'));
    PdfPage.WriteText(151.5, 231, GetTexteLibelle('RULES-PDF_MAIN4_EYES'));

    // caractéristiques
      // H
    PdfPage.DrawLine(17,219,96,219,1);
    PdfPage.DrawLine(17,214,96,214,1);
    PdfPage.DrawLine(17,207,96,207,1);
    PdfPage.DrawLine(17,200,96,200,1);
      // V
    For ind := 0 to 9 do
      PdfPage.DrawLine(31.5+(ind * 6.5),219,31.5+(ind * 6.5),193,1);
       // T
    PdfCentre(PdfPage,17,96,221,GetTexteLibelle('RULES-PDF_CHARAC1_CHARAC'));
    PdfCentre(PdfPage,31,38,215,GetTexteLibelle('RULES-SHORTATTR_WS'));

    PdfCentre(PdfPage,38,45,215, GetTexteLibelle('RULES-SHORTATTR_BS'));
    PdfCentre(PdfPage,45,51,215, GetTexteLibelle('RULES-SHORTATTR_S'));
    PdfCentre(PdfPage,51,58,215, GetTexteLibelle('RULES-SHORTATTR_T'));
    PdfCentre(PdfPage,58,64,215, GetTexteLibelle('RULES-SHORTATTR_I'));
    PdfCentre(PdfPage,64,71,215, GetTexteLibelle('RULES-SHORTATTR_Ag'));
    PdfCentre(PdfPage,71,77,215, GetTexteLibelle('RULES-SHORTATTR_Dex'));
    PdfCentre(PdfPage,78,85,215, GetTexteLibelle('RULES-SHORTATTR_Int'));
    PdfCentre(PdfPage,84,90,215, GetTexteLibelle('RULES-SHORTATTR_WP'));
    PdfCentre(PdfPage,91,97,215, GetTexteLibelle('RULES-SHORTATTR_Fel'));
    PdfPage.WriteText( 18, 209, GetTexteLibelle('RULES-PDF_CHARAC3_INITIAL'));
    PdfPage.WriteText( 18, 202, GetTexteLibelle('RULES-PDF_CHARAC3_ADVANCES'));
    PdfPage.WriteText( 18, 195, GetTexteLibelle('RULES-PDF_CHARAC3_CURRENT'));
    // Destin
      // H
    PdfPage.DrawLine(101,219,118,219,1);
    PdfPage.DrawLine(101,214,118,214,1);
      // V
    PdfPage.DrawLine(111,209,111,219,1);
      // T
    PdfCentre(PdfPage,101,118,221,GetTexteLibelle('RULES-PDF_FATE1_FATE'));
    PdfPage.WriteText(101,215,GetTexteLibelle('RULES-PDF_FATE2_FATE'));
    PdfPage.WriteText(101,210,GetTexteLibelle('RULES-PDF_FATE3_FORTUNE'));
    // Résilience
      // H
    PdfPage.DrawLine(123,219,162,219,1);
    PdfPage.DrawLine(123,214,162,214,1);
      // V
    PdfPage.DrawLine(137,209,137,219,1);
    PdfPage.DrawLine(148,209,148,219,1);
      // T
    PdfCentre(PdfPage,123,163,221,GetTexteLibelle('RULES-PDF_RESIL1_RESILIENCE'));
    PdfCentre(PdfPage,123,137,215,GetTexteLibelle('RULES-PDF_RESIL2A_RESILIENCE'));
    PdfCentre(PdfPage,137,148,215,GetTexteLibelle('RULES-PDF_RESIL2B_RESOLVE'));
    PdfCentre(PdfPage,148,162,215,GetTexteLibelle('RULES-PDF_RESIL2C_MOTIVATION'));
    // Expérience
      // H
    PdfPage.DrawLine(165,219,194,219,1);
    PdfPage.DrawLine(165,214,194,214,1);
      // V
    PdfPage.DrawLine(176,209,176,219,1);
    PdfPage.DrawLine(185,209,185,219,1);
      // T
    PdfCentre(PdfPage,165,194,221,GetTexteLibelle('RULES-PDF_XP1_EXPERIENCE'));
    PdfCentre(PdfPage,165,176,215,GetTexteLibelle('RULES-PDF_XP2A_CURRENT'));
    PdfCentre(PdfPage,176,185,215,GetTexteLibelle('RULES-PDF_XP2B_SPENT'));
    PdfCentre(PdfPage,185,194,215,GetTexteLibelle('RULES-PDF_XP2C_TOTAL'));
    // Mouvement
      // H
    PdfPage.DrawLine(101,198,194,198,1);
      // V
    PdfPage.DrawLine(121.5,198,121.5,193,1);
    PdfPage.DrawLine(132.5,198,132.5,193,1);
    PdfPage.DrawLine(149.5,198,149.5,193,1);
    PdfPage.DrawLine(164.5,198,164.5,193,1);
    PdfPage.DrawLine(181.5,198,181.5,193,1);
      // T

    PdfCentre(PdfPage,101,194,200,GetTexteLibelle('RULES-PDF_MV1_MOVEMENT'));
    PdfPage.WriteText(102,194,GetTexteLibelle('RULES-PDF_MV2A_MOVEMENT'));
    PdfPage.WriteText(133.5,194,GetTexteLibelle('RULES-PDF_MV2B_WALK'));
    PdfPage.WriteText(165.5,194,GetTexteLibelle('RULES-PDF_MV2C_RUN'));
    // Basic 1
      // H
    For Ind := 0 to 13 do
      PdfPage.DrawLine(17,181.5 - (ind * 5),72,181.5 - (ind * 5),1);
      // V
    PdfPage.DrawLine(41,181.5,41,111.5,1);
    PdfPage.DrawLine(49,176.5,49,111.5,1);
    PdfPage.DrawLine(57,181.5,57,111.5,1);
    PdfPage.DrawLine(64,181.5,64,111.5,1);
     // T
    PdfCentre(PdfPage,17,72,183.5,GetTexteLibelle('RULES-PDF_SKILLS1_BASIC'));
    PdfEcrit(PdfPage,18,41,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_NAME'),MinPolice);
    PdfCentre(PdfPage,42,57,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_CHARAC'));
    PdfCentre(PdfPage,57,64,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_ADV'));
    PdfCentre(PdfPage,64,72,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_SKILL'));
    // Basic 2
      // H
    For Ind := 0 to 13 do
      PdfPage.DrawLine(78,181.5 - (ind * 5),133,181.5 - (ind * 5),1);
      // V
    PdfPage.DrawLine(102,181.5,102,111.5,1);
    PdfPage.DrawLine(110,176.5,110,111.5,1);
    PdfPage.DrawLine(118,181.5,118,111.5,1);
    PdfPage.DrawLine(125,181.5,125,111.5,1);
     // T
     PdfCentre(PdfPage,78,133.5,183.5,GetTexteLibelle('RULES-PDF_SKILLS1_BASIC'));
     PdfEcrit(PdfPage,78,102,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_NAME'),MinPolice);
     PdfCentre(PdfPage,102,118,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_CHARAC'));
     PdfCentre(PdfPage,118,125,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_ADV'));
     PdfCentre(PdfPage,125,133,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_SKILL'));
    // Groupé
      // H
    For Ind := 0 to 1 do
      PdfPage.DrawLine(139,181.5 - (ind * 5),194,181.5 - (ind * 5),1);
      // V
    PdfPage.DrawLine(162,181.5,162,111.5,1);
    PdfPage.DrawLine(170,176.5,170,111.5,1);
    PdfPage.DrawLine(178,181.5,178,111.5,1);
    PdfPage.DrawLine(185,181.5,185,111.5,1);
      // T
    PdfCentre(PdfPage,139,194,183.5,GetTexteLibelle('RULES-PDF_SKILLS1_ADVANCED'));
    PdfEcrit(PdfPage,139,162,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_NAME'),MinPolice);
    PdfCentre(PdfPage,162,178,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_CHARAC'));
    PdfCentre(PdfPage,178,185,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_ADV'));
    PdfCentre(PdfPage,185,194,177.5,GetTexteLibelle('RULES-PDF_SKILLS2_SKILL'));
    // Talents
      // H
    PdfPage.DrawLine(17,100,100,100,1);
    PdfPage.DrawLine(17,92,100,92,1);
      // V
    PdfPage.DrawLine(45,100,45,20,1);
    PdfPage.DrawLine(56,100,56,20,1);
      // T
    PdfCentre(PdfPage,17,100,102,GetTexteLibelle('RULES-PDF_TALENT1_TALENTS'));
    PdfPage.WriteText(18,95,GetTexteLibelle('RULES-PDF_TALENT2_TALENTNAME'));
    PdfCentre(PdfPage,45,56,96,GetTexteLibelle('RULES-PDF_TALENT2A_TAKEN'));
    PdfCentre(PdfPage,45,56,93,GetTexteLibelle('RULES-PDF_TALENT2B_TAKEN'));
    PdfPage.WriteText(58,95,GetTexteLibelle('RULES-PDF_TALENT2_DESC'));
     // Ambitions
      // H
    PdfPage.DrawLine(106,100,194,100,1);
    PdfPage.DrawLine(106,88,194,88,1);
      // T
    PdfCentre(PdfPage,106,194,102,GetTexteLibelle('RULES-PDF_AMBITION1_AMBITIONS'));
    PdfPage.WriteText(108,94,GetTexteLibelle('RULES-PDF_AMBITION2A_SHORT'));
    PdfPage.WriteText(108,91,GetTexteLibelle('RULES-PDF_AMBITION2B_SHORT'));
    PdfPage.WriteText(108,83,GetTexteLibelle('RULES-PDF_AMBITION3A_LONG'));
    PdfPage.WriteText(108,80,GetTexteLibelle('RULES-PDF_AMBITION3B_LONG'));
    // Party
      // H
    PdfPage.DrawLine(106,65,194,65,1);
    PdfPage.DrawLine(106,59,194,59,1);
    PdfPage.DrawLine(106,47,194,47,1);
    PdfPage.DrawLine(106,36,194,36,1);
      // T
    PdfCentre(PdfPage,106,194,67,GetTexteLibelle('RULES-PDF_PARTY1_PARTY'));
    PdfPage.WriteText(108,61,GetTexteLibelle('RULES-PDF_PARTY2_PARTYNAME'));
    PdfPage.WriteText(108,53,GetTexteLibelle('RULES-PDF_PARTY3A_SHORT'));
    PdfPage.WriteText(108,50,GetTexteLibelle('RULES-PDF_PARTY3B_SHORT'));
    PdfPage.WriteText(108,42,GetTexteLibelle('RULES-PDF_PARTY4A_LONG'));
    PdfPage.WriteText(108,39,GetTexteLibelle('RULES-PDF_PARTY4B_LONG'));
    PdfPage.WriteText(108,30,GetTexteLibelle('RULES-PDF_PARTY5_MEMBERS'));
  end;

Procedure PdfNormalCompetencesBase(PdfPage: TPDFPage; Personnage: StructurePersonnage; PMetier: StructureMetier; ListPage: TStringList; DessineTexteLigne: Boolean; MinPolice: Integer; out ListPris: String);
var
  NbLigne, IndC, DebPage: Integer;
  Comp, ValStat, ValBonus, ValTotal, Asterisc: String;
  PCompetence: StructureCompetence;
  PAttribut: StructureAttribut;
  CompetenceDonnee: StructureDonnee;
  Bidon: Integer = 0;
begin
  Asterisc := '';
  NbLigne := 0;
  ListPris:= '';
  for IndC := 0 to ListPage.count-1 do
    begin
      Asterisc    := '';
      Comp        := ListPage[IndC];
      PCompetence := ChercheCompetence(Comp);
      CompetenceDonnee := PdfPersonnageCompetence(Personnage, Comp, Bidon);
      ValStat     := IntToStr(CompetenceDonnee.Base);
      ValBonus    := IntToStr(CompetenceDonnee.Augmentation);
      ValTotal    := IntToStr(CompetenceDonnee.Total);
      ListPris    := ListPris + Separateurtabulation + Comp;
      //Asterisc := TabCompetence.Cells[ColCompAsterisc, IndT];

      // premier ou seconde colonne
      if IndC <= 12 then
        DebPage := 51
      else
        DebPage := 112;
      if IndC = 13 then
        NbLigne := 0;
      if ValBonus = '0' then
        ValBonus := '';
      if (StrToIntDef(ValBonus,0) >= 0) and (StrToIntDef(ValBonus,0) < 10) then
        ValBonus := ' ' + ValBonus;
      if DessineTexteLigne then
        begin
          if CompareCompetence(PCompetence.CodeCompetence,PMetier.CodeCompetence) then
            PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceArial+ConstPoliceGras, 8)
          else
            PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
          PdfEcrit(PdfPage,DebPage - 33, DebPage - 9, 173-(NbLigne*5), PdfSupprimeGenerique(PCompetence.CodeCompetence, PCompetence.Libelle),MinPolice);
          PAttribut                              := ChercheAttribut(PCompetence.CodeAttribut);
          PdfPage.WriteText(DebPage - 9, 173-(NbLigne*5), GetTexteLibelle(PAttribut.Resume)); // PdfPage.WriteText(DebPage - 9, 173-(NbLigne*5), GetTexteLibelle('SHORT'+PCompetence.CodeAttribut));
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        end;
      PdfPage.WriteText(DebPage,    173-(NbLigne*5), ValStat);  // Compétence Caractéristique
      PdfPage.WriteText(DebPage+7,  173-(NbLigne*5), ValBonus); // Compétence Bonus
      if Pos(ValeurGenerique, PCompetence.codeCompetence) > 0 then
        PdfPage.DrawLine(DebPage+6.5,  172-(NbLigne*5), DebPage+12.5,  176-(NbLigne*5), 1);
      PdfPage.WriteText(DebPage+14, 173-(NbLigne*5), ValTotal); // Compétence Total
      if Asterisc <> '' then
        begin
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 5);
          PdfPage.WriteText(DebPage+19, 174.5-(NbLigne*5), '('+Asterisc+')'); // Talent
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        end;

      NbLigne := NbLigne + 1;
    end;
end;

Procedure PdfNormalCompetencesGroupees(PdfPage: TPDFPage; Personnage: StructurePersonnage; PMetier: StructureMetier; ListPris: String; MinPolice: Integer);
var
  NbLigne, IndC: Integer;
  ValBonus, LibComp: String;
  PCompetence: StructureCompetence;
  PAttribut: StructureAttribut;
  CompetenceDonnee: StructureDonnee;
  Bidon: Integer = 0;
begin
  NbLigne := 0;
  for IndC := 0 to ListCompetence.Count-1 do
    begin
      PCompetence   := ListCompetence[IndC];
      if (pos(PCompetence.CodeCompetence, ListPris) = 0) then
        begin
          CompetenceDonnee := PdfPersonnageCompetence(Personnage, PCompetence.CodeCompetence, Bidon);
          // gabarit imposé par les auteurs du jeu : 18 lignes, les suivantes ne sont pas écrites
          if (CompetenceDonnee.Augmentation <> 0) and (NbLigne < 18) then
          begin
            ValBonus := IntToStr(CompetenceDonnee.Augmentation);
            if (StrToIntDef(ValBonus,0) >= 0) and (StrToIntDef(ValBonus,0) < 10) then
              ValBonus := ' ' + ValBonus;
            PCompetence := ChercheCompetence(PCompetence.CodeCompetence);
            LibComp     := PCompetence.Libelle;
            if CompareCompetence(PCompetence.CodeCompetence,PMetier.CodeCompetence) then
              PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceArial+ConstPoliceGras, 6)
            else
              PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
            PdfEcrit(PdfPage,137, 163, 173-(NbLigne*3.5), LibComp,MinPolice);                                // Gr_Av Libellé
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
            PAttribut := ChercheAttribut(PCompetence.CodeAttribut);
            PdfPage.WriteText(163, 173-(NbLigne*3.5), PAttribut.Resume);                   // Gr_Av Attribut
            PdfPage.WriteText(172, 173-(NbLigne*3.5), IntToStr(CompetenceDonnee.Base));                 // Gr_Av Caractéristique
            PdfPage.WriteText(180, 173-(NbLigne*3.5), IntToStr(CompetenceDonnee.Augmentation));         // Gr_Av Bonus
            PdfPage.WriteText(188, 173-(NbLigne*3.5), IntToStr(CompetenceDonnee.Total));                // Gr_Av Total
            NbLigne := NbLigne + 1;
          end;
      end;
    end;

end;

Procedure PdfNormalTalents(PdfPage: TPDFPage; Personnage: StructurePersonnage; MinPolice: Integer);
var
  NbLigne, IndC, Bidon: Integer;
  PTalent: StructureTalent;
  TalentDonnee: StructureDonnee;
  ListeRegle: TListCareerBonusSpecialRule;
  PRegle: StructureCareerBonusSpecialRule;
  PMutationTalent: StructurePersonnageTalent;
  PArmureBonusTalent: StructurePersonnageTalent;
begin
  Bidon := 0;
  NbLigne := 0;
  For IndC := 0 to ListTalent.count - 1 do
    begin
      PTalent := ListTalent[IndC];
      TalentDonnee := PdfPersonnageTalent(Personnage, PTalent.CodeTalent, Bidon);
      if (TalentDonnee.Total <> 0) and (NbLigne < 20) then
      begin
        inc(NbLigne);
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
        PdfEcrit(PdfPage, 16, 49, 92-(NbLigne*3.5), PTalent.Libelle,MinPolice);              // Gr_Av Libellé
        // Virtue of the Quest (CONTEXT.md 2.78) : talent possede mais dont les effets
        // sont en sommeil hors de la carriere+niveau qui l'a accorde - barre plutot
        // que retire (le vrai retrait n'est pas encore mecanise).
        if PersonnageTalentEstBarre(Personnage, PTalent.CodeTalent) then
          PdfPage.DrawLine(16, 92-(NbLigne*3.5)+0.8, 49, 92-(NbLigne*3.5)+0.8, 0.5);
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        PdfPage.WriteText(49, 92-(NbLigne*3.5), IntToStr(TalentDonnee.Total));              // Gr_Av Attribut
        //if TabTalent.Cells[ColTalAsterisk, IndC] <> '' then
        //  begin
        //    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
        //    PdfPage.WriteText(12.5, 92.5-(IndC*3.5), '('+TabTalent.Cells[ColTalAsterisk, IndC]+')');
        //    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        //  end;
        if PTalent.SousTalent then
          PTalent := ChercheTalent(CodeTalentGenerique(PTalent));
        if PTalent.Resume <> '' then
          begin
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
            PdfEcrit(PdfPage, 58, 105, 92-(NbLigne*3.5), PTalent.Resume,MinPolice);
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
          end;
      end;
    end;

  // Regles speciales des appartenances (palier "Knight of the Inner Circle" et
  // equivalents, sans bonus chiffre) - affichees comme des talents virtuels
  // supplementaires, meme bloc, meme mise en forme. CONTEXT.md 2.51, 08/09/2026.
  ListeRegle := PersonnageCareerBonusSpecialRule(Personnage);
  try
    for IndC := 0 to ListeRegle.Count - 1 do
      begin
        PRegle := ListeRegle[IndC];
        inc(NbLigne);
        if NbLigne > 20 then Break;
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
        PdfEcrit(PdfPage, 16, 49, 92-(NbLigne*3.5), PRegle.Libelle,MinPolice);
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        if PRegle.Texte <> '' then
          begin
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
            PdfEcrit(PdfPage, 58, 105, 92-(NbLigne*3.5), PRegle.Texte,MinPolice);
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
          end;
      end;
  finally
    ListeRegle.Free;
  end;

  // Signe astral (Archives of the Empire II p.39) : une ligne en lecture seule, comme les regles
  // speciales ci-dessus. Le libelle porte le nom du signe, le texte ses modificateurs.
  if Personnage.SigneAstral <> '' then
    begin
      inc(NbLigne);
      if NbLigne <= 20 then
        begin
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
          PdfEcrit(PdfPage, 16, 49, 92-(NbLigne*3.5), GetTexteLibelle('RULES-LAB_272') + ': ' + ChercheSigneAstral(Personnage.SigneAstral).Libelle, MinPolice);
          PdfEcrit(PdfPage, 58, 105, 92-(NbLigne*3.5), SigneAstralTextePdf(Personnage.SigneAstral, Personnage.SigneAstralVariante), MinPolice);
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        end;
    end;

  // Talents accordes par une mutation (ex. Fleshy Tentacle -> Tentacles), meme bloc, meme
  // mise en forme que les regles speciales d'appartenance juste au-dessus. Calcule a la
  // volee (PersonnageMutationTalent, chargepersonnage.pas) - CONTEXT.md, chantier
  // "traits de creature".
  for PMutationTalent in PersonnageMutationTalent(Personnage) do
    begin
      PTalent := ChercheTalent(PMutationTalent.CodeTalent);
      inc(NbLigne);
      if NbLigne > 20 then Break;
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
      PdfEcrit(PdfPage, 16, 49, 92-(NbLigne*3.5), PTalent.Libelle,MinPolice);
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
      if PTalent.SousTalent then
        PTalent := ChercheTalent(CodeTalentGenerique(PTalent));
      if PTalent.Resume <> '' then
        begin
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
          PdfEcrit(PdfPage, 58, 105, 92-(NbLigne*3.5), PTalent.Resume,MinPolice);
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        end;
    end;

  // Talents accordes par une qualite d'objet porte (ex. NATIO-ARMOB_16 "Fear" -> Frightening,
  // Skull Trophies), meme bloc, meme mise en forme que les talents de mutation juste au-dessus.
  // Calcule a la volee (PersonnageArmureBonusTalent, chargepersonnage.pas) - CONTEXT.md,
  // chantier "traits de creature".
  for PArmureBonusTalent in PersonnageArmureBonusTalent(Personnage) + PersonnageArmeBonusTalent(Personnage) do
    begin
      PTalent := ChercheTalent(PArmureBonusTalent.CodeTalent);
      inc(NbLigne);
      if NbLigne > 20 then Break;
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
      PdfEcrit(PdfPage, 16, 49, 92-(NbLigne*3.5), PTalent.Libelle,MinPolice);
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
      if PTalent.SousTalent then
        PTalent := ChercheTalent(CodeTalentGenerique(PTalent));
      if PTalent.Resume <> '' then
        begin
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
          PdfEcrit(PdfPage, 58, 105, 92-(NbLigne*3.5), PTalent.Resume,MinPolice);
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        end;
    end;
end;

Procedure PdfNormalBlessuresEncombrementRichesse(PdfPage: TPDFPage; Personnage: StructurePersonnage; BF, BE, BFM, DurACuire, BonusBlessureFab, BonusEncomb: Integer);
var
  Ch: String;
  PRaceAttribut: StructureRaceAttribut;
begin
  // afficher les blessure
  Ch := IntToStr(Floor(BF/10));
  if Length(Ch) = 1 then Ch := ' '+Ch;
  PdfPage.WriteText(154,163, Ch);
  Ch := IntToStr(Floor(BE/10)*2);
  if Length(Ch) = 1 then Ch := ' '+Ch;
  PdfPage.WriteText(154,157, Ch);
  Ch := IntToStr(Floor(BFM/10));
  if Length(Ch) = 1 then Ch := ' '+Ch;
  PdfPage.WriteText(154,150.5, Ch);
  if DurACuire > 0 then
    begin
      Ch := IntToStr(DurACuire);
      if Length(Ch) = 1 then Ch := ' '+Ch;
      PdfPage.WriteText(154,144, Ch);
    end;
  PRaceAttribut := ChercheRaceAttribut(Personnage.Race, ConstCaracBlessure);
  Ch := IntToStr(CalculBlessure(PRaceAttribut.CalculRace, BF, BE, BFM) + DurACuire + BonusBlessureFab);
  if Length(Ch) = 1 then Ch := ' '+Ch;
  PdfPage.WriteText(154,137.5, Ch);

  // afficher l'encombrement
  Ch := IntToStr(Floor(BF/10) + Floor(BE/10) + BonusEncomb);
  if Length(Ch) = 1 then Ch := ' '+Ch;
  PdfPage.WriteText(125,144, Ch);

  // Richesse (cadre Wealth : D = sous de laiton, SS = pistoles d'argent, GC = couronnes d'or)
  if Personnage.MonnaieSB <> 0 then PdfPage.WriteText(90,160, IntToStr(Personnage.MonnaieSB));
  if Personnage.MonnaiePA <> 0 then PdfPage.WriteText(90,149, IntToStr(Personnage.MonnaiePA));
  if Personnage.MonnaieCO <> 0 then PdfPage.WriteText(90,138, IntToStr(Personnage.MonnaieCO));
end;

Procedure PdfNormalArme(PdfPage: TPDFPage; Personnage: StructurePersonnage; PersonnageEquipement: StructurePersonnageEquipement; BF, TBonusCC, TBonusCT, MinPolice: Integer; var EncArme, NbArme: Integer; var Quality, ArmeBonii, FabricationBonii: String);
var
  TexteRange1, TexteRange2, Portee, Pourcent, LigneBonus, LocData, ListMalii, LibelleReload: String;
  PArme: StructureArme;
  PArmeBonus: StructureArmeBonus;
  PCompetence: StructureCompetence;
  CompetenceDonnee: StructureDonnee;
  PorteMoyenne, Enc, Deg, NbLoca, IndLoca, ReloadBase, ReloadEffectif, Bidon: Integer;
  RangeX: Single;
  PasBonus: Boolean;
begin
  Bidon := 0;
  TexteRange1:= '';
  TexteRange2:= '';
  PArme      := ChercheArme(PersonnageEquipement.CodeEquipement);

  Portee     := PArme.Portee;
  if Pos('('+ConstBonusCaracF+')',Portee) > 0 then
    begin
      Portee       := StringReplace(Portee, '('+ConstBonusCaracF+')', IntToStr(Trunc(BF/10)), [rfReplaceAll]);;
      PorteMoyenne := MultiChaine(Portee);
      Portee       := IntToStr(PorteMoyenne);
    end
  else
    PorteMoyenne   := StrToIntDef(Portee,0);

  // Accessoires d arme (fabrication) : bonus de portee et qualites ajoutees.
  if (PorteMoyenne > 0) and (FabricationPortee(PersonnageEquipement.QualiteEquipement) <> 0) then
    begin
      PorteMoyenne := PorteMoyenne + FabricationPortee(PersonnageEquipement.QualiteEquipement);
      Portee       := IntToStr(PorteMoyenne);
    end;
  ArmeAjouteQualites(PArme.ListeBonus, FabricationQualitesArme(PersonnageEquipement.QualiteEquipement));
  Enc        := PArme.Encombrement + FabricationEncombrement(PersonnageEquipement.QualiteEquipement, Quality);
  // Ligne alternative d'un accessoire (Bayonet = Spear) : pas d'encombrement propre, l'accessoire pese 0.
  if EquipementAlternatifFabrication(PersonnageEquipement) <> '' then
    begin
      Enc     := 0;
      Quality := ' (' + ChercheFabrication(EquipementAlternatifFabrication(PersonnageEquipement)).Libelle + ')';
    end;
  if PersonnageEquipement.PortePar = '' then // confie a un animal : compte pour lui
    EncArme    := EncArme + Enc;

  Inc(NbArme);

  // Ligne grisee si l'arme n'est pas "portee" (case decochee sur la fiche) -
  // meme visibilite demandee par Nono que sur TabEquipementAffichage
  // (winpersonnage.pas), suite au signalement "armure a 0 PA" du 26/09/2026.
  if not PersonnageEquipement.Porte then
    PdfPage.SetColor(RGB(150,150,150), False);

  Pourcent := '';

  CompetenceDonnee := PdfPersonnageCompetence(Personnage, PArme.CodeCompetence, Bidon);

  // Bonus des Ordres de Chevalerie/appartenances filtre par TYPE d'arme
  // (ex. "+10 CC avec les lances" - Reiksguard, palier Knight) : ajoute ICI,
  // ligne d'arme par ligne d'arme, et non dans PdfPersonnageCompetence (qui
  // reste le total de competence generique affiche ailleurs sur la feuille) -
  // CONTEXT.md 2.50 etape 3 (3d-3). CompetenceDonnee.Augmentation reste base
  // sur le total generique, ce bonus ne change pas l'affichage "pas de bonus".
  // PersonnageTalentArmeModif ajoute ici depuis le 11/09/2026 (ModifyWeapon sur
  // Talent, moteur generique) - meme reflexe "les DEUX blocs" que le bug
  // ModifyWeapon/Feldo2P du 08/09/2026 (CONTEXT.md).
  // Rune of Accuracy (chargefabrication.pas via ModifyAccurate/ACCURATE) : meme
  // effet que la Qualite catalogue BonusAccurate, generalise a une fabrication -
  // 27/09/2026.
  Pourcent := IntToStr(CompetenceDonnee.Total + PdfPersonnageArmeModif(Personnage, PArme) + FabricationModificateurQualite(PersonnageEquipement.QualiteEquipement, ConstXmlModifieCompetence, ConstCibleModifieDegatCC) + FabricationModificateurQualite(PArme.ListeBonus, ConstXmlModifieAccuracy, ConstCibleModifieAccuracy) + FabricationModificateurQualite(PersonnageEquipement.QualiteEquipement, ConstXmlModifieAccuracy, ConstCibleModifieAccuracy));
// Une arme accordee par une mutation est une partie du corps, pas un choix
  // d'entrainement : le malus "pas de competence" ne s'applique pas, ses qualites
  // s'affichent toujours. CONTEXT.md, chantier "traits de creature".
  PasBonus := (CompetenceDonnee.Augmentation = 0) and (PersonnageEquipement.Source = '');

  if pos(EquipementCT, PArme.CodeArme) > 0 then
    begin
      TexteRange1 := '< : '+ChaineSur(3,IntToStr(Trunc(PorteMoyenne/10)))+'m '+IntToStr(StrToInt(Pourcent)+40)+'% / '+ChaineSur(3,IntToStr(Trunc(PorteMoyenne/2 )))+'m '+IntToStr(StrToInt(Pourcent)+20)+'%';
      TexteRange2 := '> : '+ChaineSur(3,IntToStr(Trunc(PorteMoyenne*2 )))+'m '+IntToStr(StrToInt(Pourcent)-10)+'% / '+ChaineSur(3,IntToStr(Trunc(PorteMoyenne*3 )))+'m '+IntToStr(StrToInt(Pourcent)-30)+'%';
    end;

  PdfEcrit(PdfPage,18,70,121-(NbArme*5), PArme.Libelle+Quality,MinPolice);

  LigneBonus := '';

  PdfPage.WriteText(70,121-(NbArme*5), Pourcent + ' %');
  if PArme.Encombrement <> 0 then
    PdfPage.WriteText(84,121-(NbArme*5), IntToStr(Enc));
  PdfPage.WriteText(92,121-(NbArme*5), GetAllTexteLibelle(Portee));

  Deg   := CalculDegat(PArme.CalculDegat, BF);
  if pos(EquipementCC, PArme.CodeArme) > 0 then
    Deg := Deg + TBonusCC + FabricationModificateurQualite(PersonnageEquipement.QualiteEquipement, ConstXmlModifieDegat, ConstCibleModifieDegatCC)
  else if pos(EquipementCT, PArme.CodeArme) > 0 then
    Deg := Deg + TBonusCT + FabricationModificateurQualite(PersonnageEquipement.QualiteEquipement, ConstXmlModifieDegat, ConstCibleModifieDegatCT);

  if Deg = 0 then
    PdfPage.WriteText(114,121-(NbArme*5), '-')
  else
    PdfPage.WriteText(114,121-(NbArme*5), 'DR + '+IntToStr(Deg));

  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);

  RangeX := 170;
  if TexteRange1 <> '' then
    begin
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 5);
      // TailleTexte surestime d'environ 30 % la largeur dessinee : 0,77 (mesure Feldo, 20/09/2026).
      RangeX := 193.5 - 0.77 * TailleTexte(TexteRange1, 5);
      if 193.5 - 0.77 * TailleTexte(TexteRange2, 5) < RangeX then
        RangeX := 193.5 - 0.77 * TailleTexte(TexteRange2, 5);
      PdfPage.WriteText(RangeX,122.5-(NbArme*5), TexteRange1);
      PdfPage.WriteText(RangeX,120.5-(NbArme*5), TexteRange2);
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);
    end;

  if PasBonus = false then
    begin
      LigneBonus := PArme.Listebonus;
      if (PArme.ListeBonus <> '') and (PArme.ListeBonus <> '-') then
        begin
          NbLoca  := CountOccurrences(PArme.ListeBonus,',') + 1;
          for IndLoca := 1 to NbLoca do
            begin
              LocData := ExtractChaine(',',PArme.ListeBonus,IndLoca);
              if Pos(SeparateurMulti, LocData) > 0 then
                begin
                  // qualites alternatives "A 2/B 3" : "A 2 or B 3", chaque partie garde sa valeur et son explication
                  LigneBonus := StringReplace(LigneBonus, LocData, LibelleAlternatives(LocData), [rfReplaceAll]);
                  AjouteArmeBonii(ArmeBonii, CodesAlternatives(LocData));
                end
              else
                begin
                  if pos(' ',LocData) <> 0 then
                    LocData := copy(LocData,1,Pos(' ',LocData)-1);
                  PArmeBonus := ChercheArmeBonus(LocData);
                  LigneBonus := StringReplace(LigneBonus, LocData, PArmeBonus.Libelle, [rfReplaceAll]);
                  AjouteArmeBonii(ArmeBonii, PArmeBonus.CodeArmeBonus);
                end;
            end;
        end;
      FabricationDetail(PersonnageEquipement.QualiteEquipement, LigneBonus, FabricationBonii);
      // Rune of Reloading (chargefabrication.pas, ArmeReloadEffectif) : remplace le
      // chiffre brut "Reload N" par le chiffre effectif une fois les runes de
      // rechargement appliquees, ou retire la Qualite si elle tombe a 0. 26/09/2026.
      ReloadEffectif := ArmeReloadEffectif(PArme, PersonnageEquipement.QualiteEquipement, ReloadBase);
      if (ReloadEffectif >= 0) and (ReloadEffectif <> ReloadBase) then
        begin
          LibelleReload := ChercheArmeBonus(ArmeQualiteDuModificateur(PArme.ListeBonus, ConstXmlModifieRechargement, ConstCibleModifieRechargement)).Libelle;
          if ReloadEffectif = 0 then
            LigneBonus := StringReplace(LigneBonus, LibelleReload + ' ' + IntToStr(ReloadBase), '', [])
          else
            LigneBonus := StringReplace(LigneBonus, LibelleReload + ' ' + IntToStr(ReloadBase), LibelleReload + ' ' + IntToStr(ReloadEffectif), []);
          LigneBonus := StringReplace(LigneBonus, ',,', ',', [rfReplaceAll]);
          if (LigneBonus <> '') and (LigneBonus[1] = ',') then Delete(LigneBonus, 1, 1);
          if (LigneBonus <> '') and (LigneBonus[Length(LigneBonus)] = ',') then Delete(LigneBonus, Length(LigneBonus), 1);
        end;
      // Arme a distance : la zone Qualities s arrete ou commence le texte des portees (RangeX, cale a droite)
      if TexteRange1 <> '' then
        PdfEcrit(PdfPage, 132, RangeX - 1, 121.5-(NbArme*5), LigneBonus, 5)
      else
        PdfPage.WriteText(132,121-(NbArme*5), LigneBonus);
    end
  else
    begin
      PCompetence := ChercheCompetence(PArme.CodeCompetence);
      ListMalii := 'pas ' + PCompetence.Libelle;

      if (PArme.ListeBonus <> '') and (PArme.ListeBonus <> '-') then
        begin
          NbLoca  := CountOccurrences(PArme.ListeBonus,',') + 1;
          for IndLoca := 1 to NbLoca do
            begin
              LocData := ExtractChaine(',',PArme.ListeBonus,IndLoca);
              if pos(' ',LocData) <> 0 then
                LocData := copy(LocData,1,Pos(' ',LocData)-1);
              PArmeBonus := ChercheArmeBonus(LocData);
              if PArmeBonus.PlusMoins = '-' then
                begin
                  if Pos(PArmeBonus.Libelle, ArmeBonii) = 0 then
                    begin
                      if ArmeBonii <> '' then ArmeBonii := ArmeBonii + ',';
                      ArmeBonii := ArmeBonii + LocData;
                    end;
                  ListMalii  := ListMalii + ',' + PArmeBonus.Libelle;
                end;
            end;
        end;
      FabricationDetail(PersonnageEquipement.QualiteEquipement, ListMalii, FabricationBonii);
      // Arme a distance : la zone Qualities s arrete ou commence le texte des portees (RangeX, cale a droite)
      if TexteRange1 <> '' then
        PdfEcrit(PdfPage, 132, RangeX - 1, 121.5-(NbArme*5), ListMalii, 5)
      else
        PdfPage.WriteText(132,121-(NbArme*5), ListMalii);
    end;
  if not PersonnageEquipement.Porte then
    PdfPage.SetColor(clBlack, False);
  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
end;

Procedure PdfNormalArmure(PdfPage: TPDFPage; PersonnageEquipement: StructurePersonnageEquipement; MinPolice: Integer; var EncArmure, NbArmure, ArmureBras, ArmureCorps, ArmureJambe, ArmureTete: Integer; var Quality, ArmureBonii, FabricationBonii: String);
var
  PArmure: StructureArmure;
  PArmureSimplifiee: StructureArmureSimplifiee;
  PArmureBonus: StructureArmureBonus;
  LigneBonus, LocData: String;
  Enc, EncP, NbLoca, IndLoca: Integer;
begin
  if PersonnageEquipement.TypeEquipement = TypeEquipAR then
    begin
      PArmure   := ChercheArmure(PersonnageEquipement.CodeEquipement);
      Enc       := PArmure.Encombrement + FabricationEncombrement(PersonnageEquipement.QualiteEquipement,Quality);
    end
  else
    begin
      PArmureSimplifiee   := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement);
      Enc                 := PArmureSimplifiee.Encombrement + FabricationEncombrement(PersonnageEquipement.QualiteEquipement,Quality);
    end;

  // Regle "Worn Items" (Rulebook p.292) : seule une piece PORTEE voit son
  // Encombrement reduit de 1 (plancher 0) - transportee, elle compte plein pot.
  // Exception Bulky (RULES-DEFECT_04) : la piece reste a Enc 1 meme portee,
  // le plancher est 1 et non 0.
  EncP      := Enc;
  if PersonnageEquipement.Porte and (EncP > 0) then
    begin
      EncP := EncP - 1;
      if (EncP < 1) and FabricationEstBulky(PersonnageEquipement.QualiteEquipement) then
        EncP := 1;
    end;
  if PersonnageEquipement.PortePar = '' then
    EncArmure := EncArmure + EncP;
  NbLoca    := CountOccurrences(PArmure.Emplacement,',') + 1;
  if PersonnageEquipement.TypeEquipement = TypeEquipAR then
    begin
      if PersonnageEquipement.Porte then
        For IndLoca := 1 to NbLoca do
          begin
            LocData := ExtractChaine(',',PArmure.Emplacement,IndLoca);
            // 05/09/2026 - ex-"case LocData of" : egalite stricte, incompatible
            // avec un <Location> prefixe par son livre (RULES-ARMOL_ARM).
            // CompareRechercheValeur tolere le libelle nu en SECOND argument,
            // donc ceci marche avec les donnees prefixees comme avec les nues.
            if CompareRechercheValeur(LocData, BonusBras) then
              ArmureBras  := ArmureBras  + PArmure.Protection
            else if CompareRechercheValeur(LocData, BonusCorps) then
              ArmureCorps := ArmureCorps + PArmure.Protection
            else if CompareRechercheValeur(LocData, BonusJambes) then
              ArmureJambe := ArmureJambe + PArmure.Protection
            else if CompareRechercheValeur(LocData, BonusTete) then
              ArmureTete  := ArmureTete  + PArmure.Protection;
          end
    end
  else if PersonnageEquipement.Porte then
    begin
      ArmureBras  := ArmureBras  + PArmureSimplifiee.Protection;
      ArmureCorps := ArmureCorps + PArmureSimplifiee.Protection;
      ArmureJambe := ArmureJambe + PArmureSimplifiee.Protection;
      ArmureTete  := ArmureTete  + PArmureSimplifiee.Protection;
    end;

  Inc(NBArmure);
  // Ligne grisee si l'armure n'est pas "portee" (meme mecanisme que le bloc
  // arme ci-dessus - signalement Nono du 26/09/2026, "armure a 0 PA").
  if not PersonnageEquipement.Porte then
    PdfPage.SetColor(RGB(150,150,150), False);
  if PersonnageEquipement.TypeEquipement = TypeEquipAR then
    begin
      PdfEcrit(PdfPage,18,52,255-(NbArmure*5), Parmure.Libelle+Quality,MinPolice);
      PdfPage.WriteText(52,255-(NbArmure*5), GetAllTexteLibelle(PArmure.Emplacement));
      PdfPage.WriteText(83.5,255-(NbArmure*5), IntToStr(PArmure.Protection));
      LigneBonus := PArmure.Listebonus;
    end
  else
    begin
      PdfEcrit(PdfPage,18,52,255-(NbArmure*5), ParmureSimplifiee.Libelle+Quality,MinPolice);
      PdfPage.WriteText(83.5,255-(NbArmure*5), IntToStr(PArmureSimplifiee.Protection));
      LigneBonus := PArmureSimplifiee.Listebonus;
    end;
  if Enc <> 0 then
    if EncP <> Enc then
      PdfPage.WriteText(73,255-(NbArmure*5), IntToStr(EncP)+ '('+IntToStr(Enc)+')')
    else
      PdfPage.WriteText(73,255-(NbArmure*5), IntToStr(Enc));
  if (PersonnageEquipement.TypeEquipement = TypeEquipAR) and (PArmure.ListeBonus <> '') and (PArmure.ListeBonus <> '-') or
     (PersonnageEquipement.TypeEquipement = TypeEquipARS) and (PArmureSimplifiee.ListeBonus <> '') and (PArmureSimplifiee.ListeBonus <> '-') then
    begin
      if (PersonnageEquipement.TypeEquipement = TypeEquipAR) then
        NbLoca  := CountOccurrences(PArmure.ListeBonus,',') + 1
      else
        NbLoca  := CountOccurrences(PArmureSimplifiee.ListeBonus,',') + 1;
      for IndLoca := 1 to NbLoca do
        begin
          if (PersonnageEquipement.TypeEquipement = TypeEquipAR) then
            LocData := ExtractChaine(',',PArmure.ListeBonus,IndLoca)
          else
            LocData := ExtractChaine(',',PArmureSimplifiee.ListeBonus,IndLoca);
          if pos(' ',LocData) <> 0 then
            LocData := copy(LocData,1,Pos(' ',LocData)-1);
          PArmureBonus := ChercheArmureBonus(LocData);
          LigneBonus := StringReplace(LigneBonus, LocData, PArmureBonus.Libelle, [rfReplaceAll]);
          if pos(LocData, ArmureBonii) = 0 then
            begin
              if ArmureBonii <> '' then
               ArmureBonii := ArmureBonii + ',';
              ArmureBonii := ArmureBonii + LocData;
            end;
        end;
    end;
  FabricationDetail(PersonnageEquipement.QualiteEquipement, LigneBonus, FabricationBonii);
  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);
  PdfPage.WriteText(90,255-(NbArmure*5), LigneBonus);
  if not PersonnageEquipement.Porte then
    PdfPage.SetColor(clBlack, False);
  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
end;

Procedure PdfNormalDivers(PdfPage: TPDFPage; PersonnageEquipement: StructurePersonnageEquipement; MinPolice: Integer; var IndDivers, EncDivers: Integer);
begin
  Inc(IndDivers);
  PdfEcrit(PdfPage,18,65,212-(IndDivers*3.5), PdfDiversLibelle(PersonnageEquipement),MinPolice);
  if PersonnageEquipement.PortePar = '' then
    EncDivers := EncDivers + PdfDiversEncombrement(PersonnageEquipement);
  if PdfDiversTexteEnc(PersonnageEquipement) <> '' then
    PdfCentre(PdfPage,65,73,212-(IndDivers*3.5), PdfDiversTexteEnc(PersonnageEquipement));
end;

Procedure PdfNormalSort(PdfPage: TPDFPage; Personnage: StructurePersonnage; PersonnageEquipement: StructurePersonnageEquipement; MinPolice: Integer; var NbSort: Integer);
var
  PSort: StructureSort;
begin
  // gérer les sorts
  Inc(NbSort);
  PSort := ChercheSort(PersonnageEquipement.CodeEquipement);
  PdfEcrit (PdfPage, 18   , 59.5,71.5-(NbSort*5), PSort.Libelle, MinPolice);
  PdfCentre(PdfPage, 59.5 , 73  ,71.5-(NbSort*5), LibelleValeurLivre(PSort.Niveau));
  PdfCentre(PdfPage, 73   , 85.5,71.5-(NbSort*5), PdfPersonnageRemplaceBonus(Personnage, PSort.Portee));
  PdfCentre(PdfPage, 85.5 ,100  ,71.5-(NbSort*5), PdfPersonnageRemplaceBonus(Personnage, PSort.Cible));
  PdfCentre(PdfPage,101   ,117  ,71.5-(NbSort*5), PdfPersonnageRemplaceBonus(Personnage, PSort.Duree));
  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
end;

Procedure PdfNormalExplications(PdfPage: TPDFPage; ArmureBonii, ArmeBonii, FabricationBonii: String);
var
  NbBonus, NbLoca, IndLoca: Integer;
  LocData, TxtBonus: String;
  PArmureBonus: StructureArmureBonus;
  PArmureBonusModif: StructureModificateur;
  PArmeBonus: StructureArmeBonus;
  PFabrication: StructureFabrication;
begin
  // Écrire du texte sur la page PDF
  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);

  NbBonus := 0;
  if ArmureBonii <> '' then
    begin
      NbLoca := CountOccurrences(ArmureBonii,',')+1;
      For IndLoca := 1 to NbLoca do
        begin
          Inc(NbBonus);
          LocData      := ExtractChaine(',',ArmureBonii,IndLoca);
          PArmureBonus := ChercheArmureBonus(LocData);
          TxtBonus     := PArmureBonus.Libelle+':'+PArmureBonus.Malus;
          if PArmureBonus.Malus = '' then
            // Modifier structuré (attribut name="CodeCompetence", 15/08/2026) : plus de
            // texte libre dans .Malus pour ces entrées, on reconstruit un texte lisible
            // à partir de ListArmureBonusModif (même principe que WinArmor/Feldo2P)
            for PArmureBonusModif in ListModificateur do
              if EntreeCompetenceEquip(PArmureBonusModif) and CompareRechercheValeur(PArmureBonusModif.CodeSource, PArmureBonus.CodeArmureBonus) then
                begin
                  if TxtBonus <> PArmureBonus.Libelle+':' then
                    TxtBonus := TxtBonus + ', ';
                  TxtBonus := TxtBonus + ChercheCompetence(PArmureBonusModif.Cible).Libelle
                                        + ' ' + IntToStr(PArmureBonusModif.Facteur) + '%';
                end;
          PdfEcritTient(PdfPage, 15, 74, 133+(NbBonus*2), TxtBonus);
        end;
      Inc(NbBonus);
      PdfPage.WriteText(15,133+(NbBonus*2), ' --------- ' + GetTexteLibelle('RULES-LAB_122') + ' --------- ');
    end;

  if ArmeBonii <> '' then
    begin
      NbLoca := CountOccurrences(ArmeBonii,',')+1;
      For IndLoca := 1 to NbLoca do
        begin
          Inc(NbBonus);
          LocData     := ExtractChaine(',',ArmeBonii,IndLoca);
          PArmeBonus  := ChercheArmeBonus(LocData);
          TxtBonus    := PArmeBonus.Libelle+':'+PArmeBonus.Resume;
          PdfEcritTient(PdfPage, 15, 74, 133+(NbBonus*2), TxtBonus);
        end;
      Inc(NbBonus);
      PdfPage.WriteText(15,133+(NbBonus*2), ' ---------- ' + GetTexteLibelle('RULES-LAB_123') + ' ---------- ');
    end;

  if FabricationBonii <> '' then
    begin
      NbLoca := CountOccurrences(FabricationBonii,',')+1;
      For IndLoca := 1 to NbLoca do
        begin
          Inc(NbBonus);
          LocData     := ExtractChaine(',',FabricationBonii,IndLoca);
          PFabrication:= ChercheFabrication(LocData);
          TxtBonus    := PFabrication.Libelle+':'+PFabrication.Resume;
          // Rune a effet conditionnel (Might, Grudge) : l'effet chiffre par rune remplace le resume.
          if FabricationEffetsConditionnels(PFabrication.CodeFabrication, '') <> '' then
            TxtBonus  := FabricationEffetsConditionnels(PFabrication.CodeFabrication, '') + ' (' + GetTexteLibelle('RULES-LAB_244') + ')';
          PdfEcritTient(PdfPage, 15, 74, 133+(NbBonus*2), TxtBonus);
        end;
      Inc(NbBonus);
      PdfPage.WriteText(15,133+(NbBonus*2), ' ---------- ' + GetTexteLibelle('RULES-LAB_124') + ' ---------- ');
    end;

  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
end;

Procedure PdfNormalTotauxEncombrementArmure(PdfPage: TPDFPage; Personnage: StructurePersonnage; EncArmure, EncArme, EncDivers, ArmureTete, ArmureBras, ArmureCorps, ArmureJambe: Integer);
var
  ArmureBouclier: Integer;
begin
  // Effets de mutation sur les Points d'Armure (CORPHY_012/016/017, CONTEXT.md §2.7,
  // étape 8) - ajoutés après le calcul de l'équipement, ne concernent que le PDF
  ArmureTete := ArmureTete + PdfPersonnageArmureModif(Personnage, BonusTete);
  ArmureBras := ArmureBras + PdfPersonnageArmureModif(Personnage, BonusBras);
  ArmureCorps := ArmureCorps + PdfPersonnageArmureModif(Personnage, BonusCorps);
  ArmureJambe := ArmureJambe + PdfPersonnageArmureModif(Personnage, BonusJambes);
  // Talents (trait Armour, marque de Quetzl), fabrications (Rune of Stone) : meme collecteur.

  PdfPage.WriteText(126,163, IntToStr(EncArmure));
  PdfPage.WriteText(126,157, IntToStr(EncArme));
  PdfPage.WriteText(126,151, IntToStr(EncDivers));
  PdfPage.WriteText(126,137.5, IntToStr(EncArme + EncArmure + EncDivers));

  ArmureBouclier := PdfPersonnageArmureModif(Personnage, BonusBouclier);
  if ArmureBouclier > 0 then
    PdfPage.WriteText(145, 190, IntToStr(ArmureBouclier));
  if ArmureJambe > 0 then
   begin
    PdfPage.WriteText(145, 207.5, IntToStr(ArmureJambe));
    PdfPage.WriteText(184.5, 195.5, IntToStr(ArmureJambe));
   end;
  if ArmureBras > 0 then
   begin
    PdfPage.WriteText(145, 229, IntToStr(ArmureBras));
    PdfPage.WriteText(184.5, 241, IntToStr(ArmureBras));
   end;
  if ArmureTete > 0 then
    PdfPage.WriteText(145, 250, IntToStr(Armuretete));
  if ArmureCorps > 0 then
   PdfPage.WriteText(184.5, 219.5, IntToStr(ArmureCorps));
end;

Procedure PdfPersonnageCreation(Personnage: StructurePersonnage; BackGround: Boolean; DessineTexteLigne: Boolean = True);
  var
    PDFDoc:               TPDFDocument;
    PdfSection:           TPDFSection;
    PdfPage:              TPDFPage;
    PDFOption:            TPDFOptions;
    PdfChemin:            String;
    BF, BE, BFM:     Integer;
    DurACuire:       Integer = 0;
    BonusBlessureFab: Integer = 0;   // Rune of Iron et autres fabrications portees
    BonusEncomb:     Integer = 0;
    TBonusCC:        Integer=0;
    TBonusCT:        Integer=0;
    MinPolice:       Integer=5;
    ArmureSet:       Boolean = false;

  // Page 1 : fond, entete, caracteristiques, competences, talents. Calcule BF/BE/BFM et les bonus
  // que la page 2 reutilise.
  procedure PdfNormalPage1;
    var
      PdfFront:        Integer;
      PMetier:         StructureMetier;
      PRaceAttribut:   StructureRaceAttribut;
      Mouv:            Integer = 0;
      ListPage:        TStringList;
      ListPris:        String;
      Ind:             Integer;
      PAttribut:       StructureAttribut;
      Chance:          Integer;
      Determine:       Integer;
      Val:             Integer;
      BonusSprint:     Integer=0;
      PersonnageAttribut:   StructurePersonnageAttribut;
      AttributDonnee:       StructureDonnee;
      Bonus:                String;
    begin
      PdfPage         := PDFDoc.Pages.AddPage;
      PdfPolicesDeRepli;
      PdfFontBack     := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Bold.ttf'), ConstPoliceCarlson+ConstPoliceGras);
      PdfFontValue    := PdfDoc.AddFont(PdfCheminPolice('ariali.ttf'), ConstPoliceArial);
      PdfFontBold     := PdfDoc.AddFont(PdfCheminPolice('arialbd.ttf'), ConstPoliceArial+ConstPoliceGras);

      PdfSection.AddPage(PdfPage);
      PdfPage.PaperType:= ptA4;
      PdfPage.UnitOfMeasure := uomMillimeters;

      // Paramétrages : liste des compétences de la page 1
      ListPage       := TStringList.Create;

      PdfPersonnageCompetenceTri(ListPage);
      // charger l'image de fond
      if BackGround = true then
        begin
          PdfFront         := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+StringReplace(ConstCheminPdfFront, ConstLangue, ValLangue, [rfReplaceAll])),false);
          PdfPage.DrawImage(0, 0, 210, 297, PdfFront);
        end;

      // gérer les lignes
      if DessineTexteLigne then
        PdfGabaritNormalPage1(PdfPage, MinPolice);

      // Écrire du texte sur la page PDF
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);

      // Entête
      PMetier        := ChercheMetier(Personnage.MetierEnCours.CodeMetier);
      PRaceAttribut  := ChercheRaceAttribut(Personnage.Race, IfThen(ValVersion = 'WFRP2', 'RULES-ATTR_M', ConstCaracMouvement));
      Mouv           := StrToIntDef(PRaceAttribut.CalculRace, 0);
      // Modificateurs de toutes les sources possedees (collecteur unique, CONTEXT.md 2.105 etape c)
      Mouv           := Mouv + PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracMouvement)
                              + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracMouvement);

      Chance         := 0;
      Determine      := 0;
      For PRaceAttribut in ListRaceAttribut do
        if PRaceAttribut.CodeRace = Personnage.Race then
          case PRaceAttribut.CodeAttribut of
            ConstCaracDestin: Chance    := Chance    + StrToIntDef(PRaceAttribut.CalculRace,0);
            ConstCaracResil:  Determine := Determine + StrToIntDef(PRaceAttribut.CalculRace,0);
          end;
      for PersonnageAttribut in Personnage.CreationAttribut do
        case PersonnageAttribut.CodeAttribut of
          ConstCaracDestin: Chance    := Chance    + PersonnageAttribut.Valeur;
          ConstCaracResil:  Determine := Determine + PersonnageAttribut.Valeur;
        end;

      // chercher les Valeur d'attributs
      for Ind := 0 to 9 do
        begin
          PAttribut      := ListeAttribut[Ind];
          AttributDonnee := PdfPersonnageAttribut(Personnage, PAttribut.CodeAttribut, Bonus);
          val            := AttributDonnee.Total;
          case PAttribut.CodeAttribut of
            ConstCaracE:  BE  := Val;
            ConstCaracF:  BF  := Val;
            ConstCaracFM: BFM := Val;
          end;
        end;

      // chercher les talents et calculer les bonus correspondants - genericise le
      // 10/09/2026 (A FAIRE.txt "GENERICISER LE CASE DE CALCUL DES TALENTS") : plus de code
      // de talent en dur, PersonnageTalentEffet lit <Effet Cible="..."/> sur n'importe quel
      // talent (ChargeTalentEffet), creation et augmentation confondues.
      DurACuire   := PersonnageTalentEffet(Personnage, ConstCibleEffetDurACuire);
      BonusBlessureFab := PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracBlessure)
                          + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracBlessure);
      BonusEncomb := PersonnageTalentEffet(Personnage, ConstCibleEffetBonusEncomb);
      // Mighty Blow/Accurate Shot migres du mecanisme Effet vers le moteur generique "par
      // source" (ConstXmlModifieDegat = ModifyDamage) le 11/09/2026 - meme pathway que
      // ModifyWeapon, Cible = categorie large (CC/CT) plutot qu'un type d'arme precis.
      TBonusCC    := PersonnageModificateurUnique(Personnage, ConstXmlModifieDegat, ConstCibleModifieDegatCC, '', True);
      TBonusCT    := PersonnageModificateurUnique(Personnage, ConstXmlModifieDegat, ConstCibleModifieDegatCT, '', True);
      BonusSprint := PersonnageTalentEffet(Personnage, ConstCibleEffetBonusSprint);
      // Talents portant <ModifyCarac name="RULES-ATTR_Fate"/"RULES-ATTR_Resil"> (ex. Luck/Chanceux
      // RULES-T0020, Strong-Minded/Obstiné RULES-T0107) - ajouté le 06/09/2026, remplace les cas
      // TalentChanceux/TalentObstine du case ci-dessus, même mécanisme que Mouvement (§2.50).
      Chance    := Chance    + PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracDestin)
                             + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracDestin);
      Determine := Determine + PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracResil)
                             + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracResil);

      // Entête (extrait dans PdfNormalEntete, CONTEXT.md §2.4)
      PdfNormalEntete(PdfPage, Personnage, MinPolice);

      // Caractéristiques (extrait dans PdfNormalCaracteristiques, CONTEXT.md §2.4)
      PdfNormalCaracteristiques(PdfPage, Personnage);

      // Destin, Résilience, Expérience, Mouvement (extraits dans PdfNormalDestinXpMouvement, CONTEXT.md §2.4)
      PdfNormalDestinXpMouvement(PdfPage, Personnage, Chance, Determine, Mouv, BonusSprint);

      // Compétences page 1 (extraites dans PdfNormalCompetencesBase, CONTEXT.md §2.4)
      PdfNormalCompetencesBase(PdfPage, Personnage, PMetier, ListPage, DessineTexteLigne, MinPolice, ListPris);
      ListPage.Destroy;

      // compétences groupées et avancées (extraites dans PdfNormalCompetencesGroupees)
      PdfNormalCompetencesGroupees(PdfPage, Personnage, PMetier, ListPris, MinPolice);

      // talents, règles d'appartenance, signe astral, mutations, qualités (extraits dans PdfNormalTalents)
      PdfNormalTalents(PdfPage, Personnage, MinPolice);

    end;

  // Page 2 : blessures, encombrement, richesse, puis equipement (armes, armures, divers, sorts).
  procedure PdfNormalPage2;
    var
      PdfBack:              Integer;
      PdfShadow:            Integer;
      EncArme:         Integer;
      EncArmure:       Integer;
      EncDivers:       Integer = 0;
      ArmureTete:      Integer;
      ArmureBras:      Integer;
      ArmureCorps:     Integer;
      ArmureJambe:     Integer;
      NbArme:          Integer;
      NbArmure:        Integer;
      ArmeBonii:       String = '';
      ArmureBonii:     String = '';
      FabricationBonii:String = '';
      IndDivers:       Integer = 0;
      NBSort:          Integer;
      Quality:         String;
      PersonnageEquipement: StructurePersonnageEquipement;
      PdfPageBlanc:         TPDFPage;
      PageSauvee:           TPDFPage;
    begin

      // charger l'image de fond
      PdfPage          := PDFDoc.Pages.AddPage;
      PdfPolicesDeRepli;
      PdfFontBack      := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Bold.ttf'), ConstPoliceCarlson+ConstPoliceGras);
      PdfFontValue     := PdfDoc.AddFont(PdfCheminPolice('ariali.ttf'), ConstPoliceArial);
      PdfSection.AddPage(PdfPage);

      if BackGround = true then
        begin
          PdfBack          := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+StringReplace(ConstCheminPdfBack, ConstLangue, ValLangue, [rfReplaceAll])),false);
          PdfPage.DrawImage(0, 0, 210, 297, PdfBack);

          PdfShadow          := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+ConstCheminPdfShadow),false);
          PdfPage.DrawImage(135, 190, 55, 72, PdfShadow);
        end;


      // gérer les lignes
      if DessineTexteLigne then
        PdfGabaritNormalPage2(PdfPage, MinPolice);

      // Écrire du texte sur la page PDF
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);

      // Blessures, encombrement, richesse (extraits dans PdfNormalBlessuresEncombrementRichesse)
      PdfNormalBlessuresEncombrementRichesse(PdfPage, Personnage, BF, BE, BFM, DurACuire, BonusBlessureFab, BonusEncomb);

      // Afficher l'équipement
      EncArme     := 0;
      EncArmure   := 0;
      ArmureBras  := 0;
      ArmureCorps := 0;
      ArmureJambe := 0;
      ArmureTete  := 0;
      NbArme      := 0;
      NbArmure    := 0;
      NbSort      := 0;
      Quality     := '';
      // Inclut les armes accordees par une mutation (ex. Fleshy Tentacle -> Tentacles),
      // calculees a la volee - CONTEXT.md, chantier "traits de creature".
      // Gabarit imposé par les auteurs du jeu : capacité des cadres Armes (7), Armure (5), Équipement
      // (21) et Sorts (7). Au-delà, l'objet est traité normalement (encombrement, points d'armure)
      // mais dessiné sur une page jetable, jamais ajoutée à la section, donc non écrite.
      PdfPageBlanc := PDFDoc.Pages.AddPage;
      PdfPageBlanc.PaperType := ptA4;
      PdfPageBlanc.UnitOfMeasure := uomMillimeters;
      PdfTaillePolice(PdfPageBlanc, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
      for PersonnageEquipement in (Personnage.Equipement + PersonnageMutationEquipement(Personnage) + PersonnageAccessoireEquipement(Personnage)) do
        begin
          PageSauvee := PdfPage;
          if ((PersonnageEquipement.TypeEquipement = TypeEquipWe) and (NbArme >= 7)) or
             ((((ArmureSet = false) and (PersonnageEquipement.TypeEquipement = TypeEquipAR)) or
               ((ArmureSet = true)  and (PersonnageEquipement.TypeEquipement = TypeEquipARS))) and (NbArmure >= 5)) or
             (((PersonnageEquipement.TypeEquipement = TypeEquipDI) or (PersonnageEquipement.TypeEquipement = TypeEquipAN)) and (IndDivers >= 21)) or
             ((PersonnageEquipement.TypeEquipement = TypeEquipSp) and (NbSort >= 7)) then
            PdfPage := PdfPageBlanc;
          if PersonnageEquipement.TypeEquipement = TypeEquipWe then
            // gérer les armes (extraites dans PdfNormalArme)
            PdfNormalArme(PdfPage, Personnage, PersonnageEquipement, BF, TBonusCC, TBonusCT, MinPolice, EncArme, NbArme, Quality, ArmeBonii, FabricationBonii)

            else if ((ArmureSet = false) and (PersonnageEquipement.TypeEquipement = TypeEquipAR)) or
                    ((ArmureSet = true)  and (PersonnageEquipement.TypeEquipement = TypeEquipARS)) then
              // gérer les armures (extraites dans PdfNormalArmure)
              PdfNormalArmure(PdfPage, PersonnageEquipement, MinPolice, EncArmure, NbArmure, ArmureBras, ArmureCorps, ArmureJambe, ArmureTete, Quality, ArmureBonii, FabricationBonii)

            else if (PersonnageEquipement.TypeEquipement = TypeEquipDI) or (PersonnageEquipement.TypeEquipement = TypeEquipAN) then
              // gérer les divers (extraits dans PdfNormalDivers)
              PdfNormalDivers(PdfPage, PersonnageEquipement, MinPolice, IndDivers, EncDivers)

            else if PersonnageEquipement.TypeEquipement = TypeEquipSp then
              // gérer les sorts (extraits dans PdfNormalSort)
              PdfNormalSort(PdfPage, Personnage, PersonnageEquipement, MinPolice, NbSort);
          PdfPage := PageSauvee;
        end;

      // Explications des qualités et fabrications (extraites dans PdfNormalExplications)
      PdfNormalExplications(PdfPage, ArmureBonii, ArmeBonii, FabricationBonii);

      // Points d'armure par emplacement et totaux d'encombrement (extraits dans PdfNormalTotauxEncombrementArmure)
      PdfNormalTotauxEncombrementArmure(PdfPage, Personnage, EncArmure, EncArme, EncDivers, ArmureTete, ArmureBras, ArmureCorps, ArmureJambe);
    end;

  begin
    // V1 / V2 : le PDF est ecrit sur l'image de la feuille officielle (non livree, hors licence).
    // Sans elle (PICTURES absent ou DEFAULTLICENSELESS=1), on previent au lieu de sortir une page de
    // valeurs sans libelles.
    if ((ValVersion = 'WFRP2') or (ValVersion = 'WFRP1')) and
       not FileExists(CheminImage(GetCurrentDir + '\PICTURES\' + ValVersion + '\PDF\FRONT.png')) then
      begin
        ShowMessage(GetTexteLibelle('RULES-MESS_122') + LineEnding + 'PICTURES\' + ValVersion + '\PDF\');
        Exit;
      end;
    if ValVersion = 'WFRP2' then
      begin
        PdfPersonnageV2(Personnage);
        Exit;
      end;
    if ValVersion = 'WFRP1' then
      begin
        PdfPersonnageV1(Personnage);
        Exit;
      end;
    Personnage := PersonnageSansMunitions(Personnage);
    PdfChemin        := GetCurrentDir+ConstCheminPersonnage+Personnage.NomPersonnage+'\'+Personnage.NomPersonnage+' '+FormatDateTime('yyyymmdd-hhnnss', Now)+'.PDF';

    if (Pos(AjouteAccolade(ConstXmlOptionQuickArmor),Personnage.Options) > 0) then
      ArmureSet := True;

    if FileExists(PdfChemin) then
      if not DeleteFile(PdfChemin) then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_038'));
          exit;
        end;

    PDFDoc          := TPDFDocument.Create(nil);
    PDFOption       := [poUseImageTransparency, poCompressImages, poCompressFonts, poCompressText ];
    PDFDoc.Options  := PDFOption;
    PDFDoc.StartDocument;
    PdfSection      := PDFDoc.Sections.AddSection;

    PdfNormalPage1;
    PdfNormalPage2;

    PDFDoc.SaveToFile(PdfChemin);
    PDFDoc.Free;
    PdfPurgeAnciens(PdfChemin);

    if not PdfSansOuverture then
      OpenDocument(PdfChemin);
  end;

// PDF officiel de la V2 : recto et verso de la feuille du Rulebook V2 (Letter), fonds
// PICTURES\WFRP2\PDF\FRONT.png et BACK.png rendus a 200 dpi. Coordonnees en pixels de ces images
// (carte des zones : CONTEXT.md 2.123c), converties en mm. Procedure separee des gabarits V4/V5.
Procedure PdfPersonnageV2(Personnage: StructurePersonnage);
  const
    Px = 25.4 / 200;          // 1 pixel du fond = 0,127 mm
    HauteurPage = 279.4;      // Letter, mm
  var
    PDFDoc:      TPDFDocument;
    PdfSection:  TPDFSection;
    PdfPage:     TPDFPage;
    PdfChemin:   String;
    PdfImage:    Integer;
    MinPolice:   Integer = 5;

  function MX(Pix: Single): Single;
    begin
      Result := Pix * Px;
    end;

  function MY(Pix: Single): Single;
    begin
      Result := HauteurPage - (Pix + 12) * Px;   // +12 : fpPDF ecrit la ligne de base plus haut que Y
    end;

  // Texte dans une zone [X0, X1] (pixels), ligne de base a Y (pixels), reduit si trop long.
  procedure Champ(X0, X1, Y: Single; Texte: String);
    begin
      if Trim(Texte) = '' then
        Exit;
      PdfEcrit(PdfPage, MX(X0), MX(X1), MY(Y), Texte, MinPolice);
    end;

  // Texte centre sur XCentre (pixels).
  procedure Centre(XCentre, Y: Single; Texte: String);
    begin
      // TailleTexte surestime la largeur d'environ 30 % (mesure du 20/09/2026) : 0,77 la ramene au reel
      PdfTraceTexte(MX(XCentre), MY(Y), Texte);
      PdfPage.WriteText(MX(XCentre) - 0.77 * TailleTexte(Texte, PdfFontTaille) / 2, MY(Y), Texte);
    end;

  procedure NouvellePage(const CheminFond: String);
    begin
      PdfPage := PDFDoc.Pages.AddPage;
      PdfSection.AddPage(PdfPage);
      PdfPage.PaperType := ptLetter;
      PdfPage.UnitOfMeasure := uomMillimeters;
      PdfImage := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+StringReplace(CheminFond, ConstLangue, ValLangue, [rfReplaceAll])), false);
      PdfPage.DrawImage(0, 0, 215.9, 279.4, PdfImage);
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 10);
    end;

  procedure Page1;
    const
      CodePrincipal: array[0..7] of String = ('RULES-ATTR_WS', 'RULES-ATTR_BS', 'RULES-ATTR_S', 'RULES-ATTR_T',
                                              'RULES-ATTR_Ag', 'RULES-ATTR_Int', 'RULES-ATTR_WP', 'RULES-ATTR_Fel');
      CodeSecondaire: array[0..7] of String = ('RULES-ATTR_A', 'RULES-ATTR_W', 'RULES-ATTR_SB', 'RULES-ATTR_TB',
                                               'RULES-ATTR_M', 'RULES-ATTR_Mag', 'RULES-ATTR_IP', 'RULES-ATTR_FP');
    var
      PRace:    StructureRace;
      PMetier:  StructureMetier;
      Donnee:   StructureDonnee;
      Bonus:    String;
      Mouv:     Integer;

    // Armes : 6 lignes de 48 px a partir de y = 1247 (Name, Enc, Group, Damage, Range, Qualities).
    procedure LignesArmes;
      var
        Equip:   StructurePersonnageEquipement;
        PArme:   StructureArme;
        NbArme:  Integer = 0;
        Y:       Single;
        Degat:   String;
        Qualite: String;
        I:       Integer;
        Code:    String;
        CibleDegat: String;
        BonusDegat: Integer;
      begin
        for Equip in Personnage.Equipement do
          if (Equip.TypeEquipement = TypeEquipWe) and (NbArme < 6) then
            begin
              PArme := ChercheArme(Equip.CodeEquipement);
              Y     := 1283 + 48 * NbArme;
              Degat := StringReplace(PArme.CalculDegat, '(BATTR_S)', 'SB', [rfReplaceAll]);
              if (Degat <> '') and (Degat[1] = '+') then
                Delete(Degat, 1, 1);
              // ModifyDamage des qualites de l'arme (catalogue ou ajoutees a l'objet) : +N sur la formule
              if Pos(EquipementCT, PArme.CodeArme) > 0 then
                CibleDegat := ConstCibleModifieDegatCT
              else
                CibleDegat := ConstCibleModifieDegatCC;
              BonusDegat := FabricationModificateurQualite(PArme.ListeBonus, ConstXmlModifieDegat, CibleDegat)
                            + FabricationModificateurQualite(Equip.QualiteEquipement, ConstXmlModifieDegat, CibleDegat);
              if BonusDegat <> 0 then
                Degat := Degat + IfThen(BonusDegat > 0, '+', '') + IntToStr(BonusDegat);
              Champ(170, 340, Y, PArme.Libelle);
              if PArme.Encombrement <> 0 then
                Centre(382, Y, IntToStr(PArme.Encombrement));
              // Qualites : libelle de chaque code (valeur eventuelle conservee), petite police
              Qualite := '';
              // accessoires et qualites d'arme qui en accordent d'autres (Parry = Balanced + Defensive)
              ArmeAjouteQualites(PArme.ListeBonus, FabricationQualitesArme(Equip.QualiteEquipement));
              if (PArme.ListeBonus <> '') and (PArme.ListeBonus <> '-') then
                for I := 1 to CountOccurrences(PArme.ListeBonus, ',') + 1 do
                  begin
                    Code := ExtractChaine(',', PArme.ListeBonus, I);
                    if Qualite <> '' then
                      Qualite := Qualite + ', ';
                    if Pos(' ', Code) > 0 then
                      Qualite := Qualite + ChercheArmeBonus(Copy(Code, 1, Pos(' ', Code) - 1)).Libelle + Copy(Code, Pos(' ', Code), Length(Code))
                    else
                      Qualite := Qualite + ChercheArmeBonus(Code).Libelle;
                  end;
              PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);
              // Groupe : ecrit tel quel (WriteText), PdfEcrit couperait un mot long comme Gunpowder en lignes
              PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 5);
              PdfPage.WriteText(MX(426), MY(Y), GetAllTexteLibelle(PArme.TypeArme));
              PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);
              Champ(508, 558, Y, Degat);
              if (PArme.Portee <> '') and (PArme.Portee <> '-') then
                Champ(572, 630, Y, PArme.Portee);
              Champ(716, 848, Y, Qualite);
              PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 10);
              Inc(NbArme);
            end;
      end;

    // Armures detaillees : 6 lignes de 48 px a partir de y = 1774 (Type, Enc, Locations, AP) ;
    // les points d'armure par zone ne comptent que les pieces portees.
    procedure LignesArmures;
      var
        Equip:    StructurePersonnageEquipement;
        PArmure:  StructureArmure;
        NbArm:    Integer = 0;
        Y:        Single;
        Loc:      String;
        I:        Integer;
        Tete, Corps, Bras, Jambes: Integer;
      begin
        Tete := 0; Corps := 0; Bras := 0; Jambes := 0;
        for Equip in Personnage.Equipement do
          if Equip.TypeEquipement = TypeEquipAR then
            begin
              PArmure := ChercheArmure(Equip.CodeEquipement);
              if NbArm < 6 then
                begin
                  Y := 1810 + 48 * NbArm;
                  Champ(170, 364, Y, PArmure.Libelle);
                  if PArmure.Encombrement <> 0 then
                    Centre(405, Y, IntToStr(PArmure.Encombrement));
                  Champ(458, 770, Y, StringReplace(GetAllTexteLibelle(PArmure.Emplacement), ',', ', ', [rfReplaceAll]));
                  Centre(812, Y, IntToStr(PArmure.Protection));
                  Inc(NbArm);
                end;
              if Equip.Porte then
                for I := 1 to CountOccurrences(PArmure.Emplacement, ',') + 1 do
                  begin
                    Loc := ExtractChaine(',', PArmure.Emplacement, I);
                    if CompareRechercheValeur(Loc, BonusTete) then
                      Tete := Tete + PArmure.Protection
                    else if CompareRechercheValeur(Loc, BonusCorps) then
                      Corps := Corps + PArmure.Protection
                    else if CompareRechercheValeur(Loc, BonusBras) then
                      Bras := Bras + PArmure.Protection
                    else if CompareRechercheValeur(Loc, BonusJambes) then
                      Jambes := Jambes + PArmure.Protection;
                  end;
            end;
        // Points d'armure donnes par les sources possedees (qualite d'arme portee, talent, mutation...), comme le gabarit V4
        Tete   := Tete   + PdfPersonnageArmureModif(Personnage, BonusTete);
        Corps  := Corps  + PdfPersonnageArmureModif(Personnage, BonusCorps);
        Bras   := Bras   + PdfPersonnageArmureModif(Personnage, BonusBras);
        Jambes := Jambes + PdfPersonnageArmureModif(Personnage, BonusJambes);
        // Armour Points : une case par zone du tirage d100 (tete, corps, deux bras, deux jambes)
        Centre( 979,  850, IntToStr(Tete));
        Centre(1506,  850, IntToStr(Corps));
        Centre( 979, 1186, IntToStr(Bras));
        Centre(1506, 1186, IntToStr(Bras));
        Centre( 979, 1546, IntToStr(Jambes));
        Centre(1506, 1546, IntToStr(Jambes));
      end;

    // Starting (valeur de depart), Advance (avances), Current (total) : trois lignes de 48 px.
    procedure LigneProfil(const Codes: array of String; YDepart: Single);
      var
        I:       Integer;
        XCentre: Single;
      begin
        for I := 0 to 7 do
          begin
            // SB et TB ne sont pas stockes : dizaine de F et de E (comme WinPersonnage).
            if Codes[I] = 'RULES-ATTR_SB' then
              Donnee := PdfPersonnageAttribut(Personnage, 'RULES-ATTR_S', Bonus)
            else if Codes[I] = 'RULES-ATTR_TB' then
              Donnee := PdfPersonnageAttribut(Personnage, 'RULES-ATTR_T', Bonus)
            else
              Donnee := PdfPersonnageAttribut(Personnage, Codes[I], Bonus);
            if (Codes[I] = 'RULES-ATTR_SB') or (Codes[I] = 'RULES-ATTR_TB') then
              begin
                Donnee.Augmentation := Donnee.Total div 10 - Donnee.Base div 10;
                Donnee.Base         := Donnee.Base div 10;
                Donnee.Total        := Donnee.Base + Donnee.Augmentation;
              end;
            XCentre := 272 + 72 * I + 36;
            Centre(XCentre, YDepart,      IntToStr(Donnee.Base));
            if Donnee.Augmentation <> 0 then
              Centre(XCentre, YDepart + 48, IntToStr(Donnee.Augmentation));
            Centre(XCentre, YDepart + 96, IntToStr(Donnee.Total));
          end;
      end;

    begin
      NouvellePage(ConstCheminPdfFront);

      PRace   := ChercheRace(Personnage.Race);
      PMetier := ChercheMetier(Personnage.MetierEnCours.CodeMetier);

      // Character
      Champ(215, 840, 143, Personnage.NomPersonnage);
      Champ(215, 840, 191, PersonnageRaceLibelle(Personnage, PRace.Libelle));
      Champ(310, 840, 239, PMetier.Libelle);
      Champ(315, 840, 287, PdfFeldoMetiersAnciens(Personnage));

      // Personal Details (valeur sous le libelle)
      if Personnage.Age > 0 then
        Champ(165, 490, 419, IntToStr(Personnage.Age));
      if Personnage.SexeV2 <> '' then
        Champ(512, 840, 419, GetTexteLibelle(IfThen(Personnage.SexeV2 = 'F', 'RULES-LAB_743', 'RULES-LAB_744')));
      Champ(165, 490, 467, Personnage.EyeColors);
      Champ(165, 490, 515, Personnage.HairColors);
      Champ(165, 490, 563, Personnage.AstreV2);
      Champ(165, 840, 611, Personnage.NaissanceV2);
      Champ(165, 840, 659, Personnage.SigneDistinctifV2);
      if Personnage.PoidsV2 > 0 then
        Champ(512, 840, 467, IntToStr(Personnage.PoidsV2));
      if Personnage.Height > 0 then
        Champ(512, 840, 515, FormateTaille(Personnage.Height, Personnage.HeightUnit));
      Champ(512, 840, 563, Personnage.FratrieV2);

      // Experience Points
      Champ(915, 1105, 540, IntToStr(Personnage.XpActuel));
      Champ(1138, 1585, 540, IntToStr(Personnage.XpTotal));

      // Combat Movement : Move/Disengage = M, Charge = 2 M, Run = 3 M
      Donnee := PdfPersonnageAttribut(Personnage, 'RULES-ATTR_M', Bonus);
      Mouv   := Donnee.Total;
      Champ(925, 1105, 657, IntToStr(Mouv));
      Champ(1140, 1345, 657, IntToStr(Mouv * 2));
      Champ(1380, 1585, 657, IntToStr(Mouv * 3));

      // Character Profile : Main puis Secondary (Starting / Advance / Current)
      LigneProfil(CodePrincipal, 826);
      LigneProfil(CodeSecondaire, 1018);

      LignesArmes;
      LignesArmures;
    end;

  procedure Page2;
    const
      // Les 20 competences de base imprimees sur le verso, dans l'ordre de la feuille.
      CodeBase: array[0..19] of String = (
        'ANIMAL_CARE', 'CHARM', 'COMMAND', 'CONCEALMENT', 'CONSUME_ALCOHOL', 'DISGUISE', 'DRIVE',
        'EVALUATE', 'GAMBLE', 'GOSSIP', 'HAGGLE', 'INTIMIDATE', 'OUTDOOR_SURVIVAL', 'PERCEPTION',
        'RIDE', 'ROW', 'SCALE_SHEER_SURFACE', 'SEARCH', 'SILENT_MOVE', 'SWIM');
      Pas       = 48.5;     // hauteur d'une ligne du verso (px)
      XTaken    = 445;      // centres des trois cases Taken / +10 / +20
      XPlus10   = 517;
      XPlus20   = 590;
    var
      Possedees:  TStringList;
      Code:       String;
      Comp:       StructureCompetence;
      Donnee:     StructureDonnee;
      Ind, Bidon: Integer;
      Bonus:      String;
      Ligne:      Integer;
      PerComp:    StructurePersonnageCompetence;
      PerTal:     StructurePersonnageTalent;
      Equip:      StructurePersonnageEquipement;
      Talents:    TStringList;
      Attr:       String;

    // Pourcentage total, a gauche de la colonne Related Talents.
    procedure Pourcent(YCentre: Single; Valeur: Integer);
      begin
        PdfPage.WriteText(MX(648), MY(YCentre - 2), IntToStr(Valeur) + ' %');
      end;

    // Croix dans une case (centre XC, YC en pixels) ; le X italique est decale de 6 px pour paraitre centre.
    procedure Croix(XC, YC: Single);
      begin
        PdfPage.WriteText(MX(XC - 7), MY(YC + 9), 'X');
      end;

    // Croix dans les cases d'une competence : Taken si possedee, +10 / +20 selon les avances.
    procedure Cases(YCentre: Single; Code: String; DeBase: Boolean);
      begin
        Donnee := PdfPersonnageCompetence(Personnage, Code, Bidon);
        if Possedees.IndexOf(Code) < 0 then
          begin
            // Rulebook V2 p.91 : competence de base non acquise = moitie de la caracteristique
            // (arrondie au superieur) ; une competence avancee non acquise ne s'utilise pas.
            if DeBase then
              Pourcent(YCentre, (Donnee.Base + 1) div 2);
            Exit;
          end;
        Pourcent(YCentre, Donnee.Total);
        Croix(XTaken, YCentre);
        if Donnee.Augmentation >= 10 then
          Croix(XPlus10, YCentre);
        if Donnee.Augmentation >= 20 then
          Croix(XPlus20, YCentre);
      end;

    procedure AjoutePossedee(const CodeComp: String);
      begin
        // une competence a choisir (A/B non tranche) ou a specialiser n'est pas imprimee
        if (Pos('/', CodeComp) = 0) and (Pos('*', CodeComp) = 0) and (Possedees.IndexOf(CodeComp) < 0) then
          Possedees.Add(CodeComp);
      end;

    begin
      NouvellePage(ConstCheminPdfBack);

      Possedees := TStringList.Create;
      Talents   := TStringList.Create;
      try
        for PerComp in Personnage.CreationCompetence35 do
          AjoutePossedee(PerComp.CodeCompetence);
        for PerComp in Personnage.CreationCompetence40 do
          AjoutePossedee(PerComp.CodeCompetence);
        for PerComp in Personnage.AugmentationCompetence do
          AjoutePossedee(PerComp.CodeCompetence);

        // Competences de base : cases a cocher
        for Ind := 0 to High(CodeBase) do
          Cases(216 + Pas * Ind, 'RULES-COMP_' + CodeBase[Ind], True);

        // Competences avancees (toutes les autres, jusqu'a 17 lignes)
        Ligne := 0;
        for Code in Possedees do
          begin
            Comp := ChercheCompetence(Code);
            if Comp.DeBase then
              Continue;
            if Ligne > 16 then
              Break;
            Attr := Comp.CodeAttribut;
            if SameText(Copy(Attr, 1, 10), 'RULES-ATTR') then
              Attr := Copy(Attr, 12, Length(Attr));
            Champ(115, 325, 1282 + Pas * Ligne - 4, Comp.Libelle);
            Centre(363, 1282 + Pas * Ligne + 4, Attr);
            Cases(1282 + Pas * Ligne, Code, False);
            Inc(Ligne);
          end;

        // Talents : creation, carriere et achats, hors choix non tranches
        for PerTal in Personnage.CreationTalent do
          if (Pos('/', PerTal.CodeTalent) = 0) and (Talents.IndexOf(PerTal.CodeTalent) < 0) then
            Talents.Add(PerTal.CodeTalent);
        for PerTal in Personnage.MetierTalent do
          if (Pos('/', PerTal.CodeTalent) = 0) and (Talents.IndexOf(PerTal.CodeTalent) < 0) then
            Talents.Add(PerTal.CodeTalent);
        for PerTal in Personnage.AugmentationTalent do
          if (Pos('/', PerTal.CodeTalent) = 0) and (Talents.IndexOf(PerTal.CodeTalent) < 0) then
            Talents.Add(PerTal.CodeTalent);
        // Talents accordes par une mutation ou une qualite d'objet porte (Howling -> Frightening),
        // calcules a la volee comme dans la feuille V4 (PdfNormalTalents).
        for PerTal in PersonnageMutationTalent(Personnage) do
          if Talents.IndexOf(PerTal.CodeTalent) < 0 then
            Talents.Add(PerTal.CodeTalent);
        for PerTal in PersonnageArmureBonusTalent(Personnage) do
          if Talents.IndexOf(PerTal.CodeTalent) < 0 then
            Talents.Add(PerTal.CodeTalent);
        for PerTal in PersonnageArmeBonusTalent(Personnage) do
          if Talents.IndexOf(PerTal.CodeTalent) < 0 then
            Talents.Add(PerTal.CodeTalent);
        for Ind := 0 to Min(Talents.Count, 16) - 1 do
          begin
            Champ(872, 1114, 211 + Pas * Ind, ChercheTalent(Talents[Ind]).Libelle);
          end;

        // Trappings : objets divers, jusqu'a 15 lignes
        Ligne := 0;
        for Equip in Personnage.Equipement do
          if (Equip.TypeEquipement = TypeEquipDI) and (Ligne < 15) then
            begin
              Champ(872, 1095, 1134 + Pas * Ligne, PdfDiversLibelle(Equip));
              if PdfDiversEncombrement(Equip) <> 0 then
                Centre(1121, 1139 + Pas * Ligne, IntToStr(PdfDiversEncombrement(Equip)));
              Inc(Ligne);
            end;

        // Money
        if Personnage.MonnaieCO <> 0 then
          Champ(1062, 1540, 1962, IntToStr(Personnage.MonnaieCO));
        if Personnage.MonnaiePA <> 0 then
          Champ(1062, 1540, 2010, IntToStr(Personnage.MonnaiePA));
        if Personnage.MonnaieSB <> 0 then
          Champ(1062, 1540, 2058, IntToStr(Personnage.MonnaieSB));
      finally
        Possedees.Free;
        Talents.Free;
      end;
    end;

  // La feuille V2 officielle n'a pas de zone Sorts : page 3 sans fond, creee seulement si le
  // personnage a des sorts (nom, niveau de lancement, temps d'incantation et ingredient).
  procedure Page3;
    const
      Pas     = 50;
      MaxLig  = 44;
    var
      Equip:  StructurePersonnageEquipement;
      PSort:  StructureSort;
      Ligne:  Integer = 0;
      Y:      Single;
      Detail: String;
    begin
      for Equip in Personnage.Equipement do
        if Equip.TypeEquipement = TypeEquipSp then
          begin
            if Ligne = 0 then
              begin
                PdfPage := PDFDoc.Pages.AddPage;
                PdfSection.AddPage(PdfPage);
                PdfPage.PaperType := ptLetter;
                PdfPage.UnitOfMeasure := uomMillimeters;
                PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 10);
                Champ(100, 1600, 150, GetTexteLibelle('RULES-LAB_083'));
                Champ(100, 700, 230, GetTexteLibelle('RULES-LAB_014'));
                Champ(720, 920, 230, GetTexteLibelle('RULES-LAB_335'));
              end;
            if Ligne >= MaxLig then
              Break;
            PSort  := ChercheSort(Equip.CodeEquipement);
            Y      := 290 + Pas * Ligne;
            Detail := Trim(PSort.TempsIncantation);
            if Trim(PSort.Ingredient) <> '' then
              Detail := Trim(Detail + ' - ' + PSort.Ingredient);
            Champ(100, 700, Y, PSort.Libelle);
            Champ(720, 920, Y, LibelleValeurLivre(PSort.Niveau));
            Champ(940, 1600, Y, Detail);
            Inc(Ligne);
          end;
    end;

  begin
    // Mode lot (--pdf) : les fonds ne sont pas encore suivis par la version, on les fixe ici.
    PdfCheminsSelonVersion(ValVersion);
    Personnage := PersonnageSansMunitions(Personnage);
    PdfChemin  := GetCurrentDir+ConstCheminPersonnage+Personnage.NomPersonnage+'\'+Personnage.NomPersonnage+' '+FormatDateTime('yyyymmdd-hhnnss', Now)+'.PDF';
    if FileExists(PdfChemin) then
      if not DeleteFile(PdfChemin) then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_038'));
          Exit;
        end;

    PDFDoc          := TPDFDocument.Create(nil);
    PDFDoc.Options  := [poUseImageTransparency, poCompressImages, poCompressFonts, poCompressText];
    PDFDoc.StartDocument;
    PdfSection      := PDFDoc.Sections.AddSection;
    PdfPolicesDeRepli;
    PdfFontBack     := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Bold.ttf'), ConstPoliceCarlson+ConstPoliceGras);
    PdfFontValue    := PdfDoc.AddFont(PdfCheminPolice('ariali.ttf'), ConstPoliceArial);
    PdfFontBold     := PdfDoc.AddFont(PdfCheminPolice('arialbd.ttf'), ConstPoliceArial+ConstPoliceGras);

    Page1;
    Page2;
    Page3;

    PDFDoc.SaveToFile(PdfChemin);
    PDFDoc.Free;
    PdfPurgeAnciens(PdfChemin);

    if not PdfSansOuverture then
      OpenDocument(PdfChemin);
  end;

// PDF officiel de la V1 : recto et verso de la feuille du Core V1 (Letter), fonds
// PICTURES\WFRP1\PDF\FRONT.png et BACK.png (pages 382 et 383 du PDF, rendues a 200 dpi).
// Coordonnees en pixels de ces images (carte des zones : CONTEXT.md), converties en mm.
Procedure PdfPersonnageV1(Personnage: StructurePersonnage);
  const
    Px = 25.4 / 200;          // 1 pixel du fond = 0,127 mm
    HauteurPage = 279.4;      // Letter, mm
    // centres des 14 colonnes du profil (M, WS, BS, S, T, W, I, A, Dex, Ld, Int, Cl, WP, Fel)
    XProfil: array[0..13] of Integer = (479, 558, 633, 710, 788, 867, 944, 1021, 1097, 1175, 1249, 1326, 1403, 1482);
    CodeProfil: array[0..13] of String = ('RULES-ATTR_M', 'RULES-ATTR_WS', 'RULES-ATTR_BS', 'RULES-ATTR_S',
                                          'RULES-ATTR_T', 'RULES-ATTR_W', 'RULES-ATTR_I', 'RULES-ATTR_A',
                                          'RULES-ATTR_Dex', 'RULES-ATTR_Ld', 'RULES-ATTR_Int', 'RULES-ATTR_Cl',
                                          'RULES-ATTR_WP', 'RULES-ATTR_Fel');
  var
    PDFDoc:      TPDFDocument;
    PdfSection:  TPDFSection;
    PdfPage:     TPDFPage;
    PdfChemin:   String;
    PdfImage:    Integer;
    MinPolice:   Integer = 6;

  function MX(Pix: Single): Single;
    begin
      Result := Pix * Px;
    end;

  function MY(Pix: Single): Single;
    begin
      Result := HauteurPage - (Pix + 12) * Px;   // +12 : fpPDF ecrit la ligne de base plus haut que Y
    end;

  procedure Champ(X0, X1, Y: Single; Texte: String);
    begin
      if Trim(Texte) = '' then
        Exit;
      PdfEcrit(PdfPage, MX(X0), MX(X1), MY(Y), Texte, MinPolice);
    end;

  procedure Centre(XCentre, Y: Single; Texte: String);
    begin
      PdfTraceTexte(MX(XCentre), MY(Y), Texte);
      PdfPage.WriteText(MX(XCentre) - 0.77 * TailleTexte(Texte, PdfFontTaille) / 2, MY(Y), Texte);
    end;

  procedure NouvellePage(const CheminFond: String);
    begin
      PdfPage := PDFDoc.Pages.AddPage;
      PdfSection.AddPage(PdfPage);
      PdfPage.PaperType := ptLetter;
      PdfPage.UnitOfMeasure := uomMillimeters;
      PdfImage := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+StringReplace(CheminFond, ConstLangue, ValLangue, [rfReplaceAll])), false);
      PdfPage.DrawImage(0, 0, 215.9, 279.4, PdfImage);
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 10);
    end;

  // Langues du perso : toute competence dont le code contient LANGUAGE__ (Old Worlder, Eltharin,
  // Secret Language, Arcane Language...). Elles vont dans le cadre Languages, pas dans les competences.
  function EstLangueV1(const CodeComp: String): Boolean;
    begin
      Result := Pos('LANGUAGE__', CodeComp) > 0;
    end;

  procedure ListeLangues(Langues: TStringList);
    var
      PerComp: StructurePersonnageCompetence;

    procedure Ajoute(const CodeComp: String);
      begin
        if EstLangueV1(CodeComp) and (Langues.IndexOf(CodeComp) < 0) then
          Langues.Add(CodeComp);
      end;

    begin
      for PerComp in Personnage.CreationCompetence35 do
        Ajoute(PerComp.CodeCompetence);
      for PerComp in Personnage.CreationCompetence40 do
        Ajoute(PerComp.CodeCompetence);
      for PerComp in Personnage.MetierCompetence do
        Ajoute(PerComp.CodeCompetence);
      for PerComp in Personnage.AugmentationCompetence do
        Ajoute(PerComp.CodeCompetence);
    end;

  procedure Page1;
    var
      PRace:   StructureRace;
      PMetier: StructureMetier;
      Donnee:  StructureDonnee;
      Bonus:   String;

    // Sorties listees de la carriere en cours (libelles, separes par des virgules)
    function SortiesCarriereV1: String;
      var
        PSortie: StructureMetierSortie;
      begin
        Result := '';
        for PSortie in ListMetierSortie do
          if CompareRechercheValeur(PSortie.CodeMetier, Personnage.MetierEnCours.CodeMetier) then
            Result := Result + IfThen(Result = '', '', ', ') + ChercheMetier(PSortie.CodeSortie).Libelle;
      end;

    // Armes de melee (7 lignes) et de tir (6 lignes) : nom et degats seulement, les modificateurs
    // du livre (I, WS, D, PY / S, L, E, ES, Load) ne sont pas portes par StructureArme.
    procedure LignesArmes;
      var
        Equip:  StructurePersonnageEquipement;
        PArme:  StructureArme;
        NbCC:   Integer = 0;
        NbCT:   Integer = 0;
        Degat:  String;
        PObjet: StructureObjetV1;
        Y:      Single;

      // valeur d'un modificateur (« RULES-V1MOD_PARRY -1; RULES-V1MOD_DAMAGE +2 ») : '' s'il n'y en a pas
      function ModifCombatV1(const Combat, Stat: String): String;
        var
          I:    Integer;
          Elem: String;
        begin
          Result := '';
          for I := 1 to CountOccurrences(Combat, ';') + 1 do
            begin
              Elem := Trim(ExtractChaine(';', Combat, I));
              if Pos('V1MOD_' + Stat + ' ', Elem) > 0 then
                Exit(Trim(Copy(Elem, Pos(' ', Elem) + 1, Length(Elem))));
            end;
        end;

      begin
        for Equip in Personnage.Equipement do
          if Equip.TypeEquipement = TypeEquipWe then
            begin
              PArme := ChercheArme(Equip.CodeEquipement);
              Degat := StringReplace(PArme.CalculDegat, '(BATTR_S)', 'SB', [rfReplaceAll]);
              if (Degat <> '') and (Degat[1] = '+') then
                Delete(Degat, 1, 1);
              if (Pos(EquipementCT, PArme.CodeArme) > 0) or (Pos('PROJ', PArme.CodeArme) > 0) then
                begin
                  if NbCT < 6 then
                    begin
                      Champ(198, 425, 1364 + 46 * NbCT, PArme.Libelle);
                      if (PArme.Portee <> '') and (PArme.Portee <> '-') then
                        Champ(440, 700, 1364 + 46 * NbCT, PArme.Portee);
                      Inc(NbCT);
                    end;
                end
              else if NbCC < 7 then
                begin
                  Champ(198, 500, 1000 + 44 * NbCC, PArme.Libelle);
                  Champ(644, 713, 1000 + 44 * NbCC, Degat);
                  Inc(NbCC);
                end;
            end
          else if TrimRight(Equip.TypeEquipement) = TrimRight(TypeEquipDi) then
            begin
              // objet de la liste de prix (code EquipmentV1) : si c'est une arme, valeurs du livre recopiees
              PObjet := ChercheObjetV1(Equip.CodeEquipement);
              if (PObjet.Code <> '') and ValeurLivreEgale(PObjet.Categorie, 'WEAPON') then
                begin
                  if ValeurLivreEgale(PObjet.SousCategorie, 'MELEE') then
                    begin
                      if NbCC < 7 then
                        begin
                          Y := 1000 + 44 * NbCC;
                          Champ(198, 500, Y, PObjet.Libelle);
                          Champ(506, 568, Y, ModifCombatV1(PObjet.Combat, 'INITIATIVE'));
                          Champ(574, 640, Y, ModifCombatV1(PObjet.Combat, 'TOHIT'));
                          Champ(646, 713, Y, ModifCombatV1(PObjet.Combat, 'DAMAGE'));
                          Champ(719, 781, Y, ModifCombatV1(PObjet.Combat, 'PARRY'));
                          Inc(NbCC);
                        end;
                    end
                  else if NbCT < 6 then
                    begin
                      Y := 1364 + 46 * NbCT;
                      Champ(198, 425, Y, PObjet.Libelle);
                      Champ(432, 498, Y, PObjet.PorteeCourte);
                      Champ(504, 570, Y, PObjet.PorteeLongue);
                      Champ(576, 642, Y, PObjet.PorteeExtreme);
                      Champ(648, 713, Y, PObjet.ForceTir);
                      Champ(719, 781, Y, PObjet.Rechargement);
                      Inc(NbCT);
                    end;
                end;
            end;
      end;

    // Armures : 7 lignes (nom, zones, encombrement) et points d'armure par zone sur le schema.
    procedure LignesArmures;
      var
        Equip:   StructurePersonnageEquipement;
        PArmure: StructureArmure;
        NbArm:   Integer = 0;
        Loc:     String;
        J:       Integer;
        Tete, Corps, Bras, Jambes: Integer;
        // V1 : points variables « 0/1 » (cuir : -1 aux coups de 3 degats ou moins, rien au-dela) ; on cumule le bas et le haut
        // par zone (0 tete, 1 corps, 2 bras, 3 jambes) et on ecrit « a/b » si les deux different
        VarBas, VarHaut: array[0..3] of Integer;
        PObjV1: StructureObjetV1;
        Zone, Pts, Lieu: String;
        Bas, Haut, Z: Integer;

        function TexteZone(N, Fixe: Integer): String;
          begin
            if VarBas[N] = VarHaut[N] then
              Result := IntToStr(Fixe + VarBas[N])
            else
              Result := IntToStr(Fixe + VarBas[N]) + '/' + IntToStr(Fixe + VarHaut[N]);
          end;

        procedure AjouteV1(N: Integer);
          begin
            VarBas[N] := VarBas[N] + Bas;
            VarHaut[N] := VarHaut[N] + Haut;
          end;

      begin
        Tete := 0; Corps := 0; Bras := 0; Jambes := 0;
        for Z := 0 to 3 do
          begin
            VarBas[Z] := 0;
            VarHaut[Z] := 0;
          end;
        for Equip in Personnage.Equipement do
          if TrimRight(Equip.TypeEquipement) = TrimRight(TypeEquipDi) then
            begin
              // armure V1 (objet de la liste de prix, code EquipmentV1)
              PObjV1 := ChercheObjetV1(Equip.CodeEquipement);
              if (PObjV1.Code <> '') and ValeurLivreEgale(PObjV1.Categorie, 'ARMOUR') then
                begin
                  Zone := PObjV1.Zones;
                  Lieu := '';
                  for J := 1 to CountOccurrences(Zone, '/') + 1 do
                    begin
                      if Lieu <> '' then Lieu := Lieu + ',';
                      Lieu := Lieu + ExtractChaine('/', Zone, J);
                    end;
                  if NbArm < 7 then
                    begin
                      Champ(198, 500, 1740 + 46 * NbArm, PObjV1.Libelle);
                      Champ(504, 710, 1740 + 46 * NbArm, StringReplace(GetAllTexteLibelle(Lieu), ',', ', ', [rfReplaceAll]));
                      if PObjV1.Encombrement <> '' then
                        Centre(748, 1740 + 46 * NbArm, PObjV1.Encombrement);
                      Inc(NbArm);
                    end;
                  if Equip.Porte then
                    begin
                      Pts := PObjV1.PointsArmure;
                      if Pos('/', Pts) > 0 then
                        begin
                          Bas := StrToIntDef(Trim(ExtractChaine('/', Pts, 1)), 0);
                          Haut := StrToIntDef(Trim(ExtractChaine('/', Pts, 2)), 0);
                        end
                      else
                        begin
                          Bas := StrToIntDef(Trim(Pts), 0);
                          Haut := Bas;
                        end;
                      for J := 1 to CountOccurrences(Zone, '/') + 1 do
                        begin
                          Pts := ExtractChaine('/', Zone, J);
                          if ValeurLivreEgale(Pts, 'HEAD') or ValeurLivreEgale(Pts, 'ALL') then AjouteV1(0);
                          if ValeurLivreEgale(Pts, 'BODY') or ValeurLivreEgale(Pts, 'ALL') then AjouteV1(1);
                          if ValeurLivreEgale(Pts, 'ARMS') or ValeurLivreEgale(Pts, 'ALL') then AjouteV1(2);
                          if ValeurLivreEgale(Pts, 'LEGS') or ValeurLivreEgale(Pts, 'ALL') then AjouteV1(3);
                        end;
                    end;
                end;
            end
          else if Equip.TypeEquipement = TypeEquipAR then
            begin
              PArmure := ChercheArmure(Equip.CodeEquipement);
              if NbArm < 7 then
                begin
                  Champ(198, 500, 1740 + 46 * NbArm, PArmure.Libelle);
                  Champ(504, 710, 1740 + 46 * NbArm, StringReplace(GetAllTexteLibelle(PArmure.Emplacement), ',', ', ', [rfReplaceAll]));
                  if PArmure.Encombrement <> 0 then
                    Centre(748, 1740 + 46 * NbArm, IntToStr(PArmure.Encombrement));
                  Inc(NbArm);
                end;
              if Equip.Porte then
                for J := 1 to CountOccurrences(PArmure.Emplacement, ',') + 1 do
                  begin
                    Loc := ExtractChaine(',', PArmure.Emplacement, J);
                    if CompareRechercheValeur(Loc, BonusTete) then
                      Tete := Tete + PArmure.Protection
                    else if CompareRechercheValeur(Loc, BonusCorps) then
                      Corps := Corps + PArmure.Protection
                    else if CompareRechercheValeur(Loc, BonusBras) then
                      Bras := Bras + PArmure.Protection
                    else if CompareRechercheValeur(Loc, BonusJambes) then
                      Jambes := Jambes + PArmure.Protection;
                  end;
            end;
        Centre( 871, 1594, TexteZone(0, Tete));
        Centre(1119, 1682, TexteZone(2, Bras));
        Centre( 825, 1746, TexteZone(2, Bras));
        Centre(1122, 1828, TexteZone(1, Corps));
        Centre( 827, 1928, TexteZone(3, Jambes));
        Centre(1122, 1966, TexteZone(3, Jambes));
      end;

    // Competences : deux colonnes (10 puis 23 lignes), codes a choisir (A/B) ou a specialiser ignores.
    procedure LignesCompetences;
      var
        Vues:  TStringList;
        PerComp: StructurePersonnageCompetence;
        Rang:  Integer = 0;
        Reste: String;

      procedure Ajoute(const CodeComp: String);
        var
          Y: Single;
          X0, X1: Single;
        begin
          if (Pos('/', CodeComp) > 0) or (Pos('*', CodeComp) > 0) or (Vues.IndexOf(CodeComp) >= 0) or EstLangueV1(CodeComp) then
            Exit;
          Vues.Add(CodeComp);
          if Rang < 10 then
            begin
              X0 := 800; X1 := 1050; Y := 1010 + 44 * Rang;
            end
          else if Rang < 33 then
            begin
              X0 := 1170; X1 := 1410; Y := 1010 + 44 * (Rang - 10);
            end
          else
            Exit;
          Champ(X0, X1, Y, ChercheCompetence(CodeComp).Libelle);
          Inc(Rang);
        end;

      begin
        Vues := TStringList.Create;
        try
          for PerComp in Personnage.CreationCompetence35 do
            Ajoute(PerComp.CodeCompetence);
          for PerComp in Personnage.CreationCompetence40 do
            Ajoute(PerComp.CodeCompetence);
          for PerComp in Personnage.MetierCompetence do
            Ajoute(PerComp.CodeCompetence);
          for PerComp in Personnage.AugmentationCompetence do
            Ajoute(PerComp.CodeCompetence);
          // competences gratuites du familier du Druidic Priest
          Reste := CompetencesFamilierV1(Personnage);
          while Reste <> '' do
            Ajoute(ElementSuivantV1(Reste));
        finally
          Vues.Free;
        end;
      end;

    // Starter (valeur de depart), Advance Scheme (avances), Current (total) : trois lignes.
    procedure LigneProfil;
      var
        I: Integer;
      begin
        for I := 0 to High(CodeProfil) do
          begin
            Donnee := PdfPersonnageAttribut(Personnage, CodeProfil[I], Bonus);
            Centre(XProfil[I], 742, IntToStr(Donnee.Base));
            if Donnee.Augmentation <> 0 then
              Centre(XProfil[I], 819, IntToStr(Donnee.Augmentation));
            Centre(XProfil[I], 896, IntToStr(Donnee.Total));
          end;
      end;

    begin
      NouvellePage(ConstCheminPdfFront);

      PRace   := ChercheRace(Personnage.Race);
      PMetier := ChercheMetier(Personnage.MetierEnCours.CodeMetier);

      Champ(205, 645, 363, Personnage.NomPersonnage);
      Champ(665, 805, 363, PersonnageRaceLibelle(Personnage, PRace.Libelle));
      if Personnage.SexeV2 <> '' then
        Champ(818, 958, 363, GetTexteLibelle(IfThen(Personnage.SexeV2 = 'F', 'RULES-LAB_743', 'RULES-LAB_744')));
      Champ(973, 1295, 363, GetTexteLibelle(PMetier.LibelleGroupe));
      Champ(1320, 1510, 363, GetTexteLibelle(PersonnageAlignementV1(Personnage)));
      if Personnage.Age > 0 then
        Champ(205, 340, 478, IntToStr(Personnage.Age));
      if Personnage.Height > 0 then
        Champ(355, 497, 478, FormateTaille(Personnage.Height, Personnage.HeightUnit));
      if Personnage.PoidsV2 > 0 then
        Champ(510, 655, 478, IntToStr(Personnage.PoidsV2));
      Champ(670, 805, 478, Personnage.HairColors);
      Champ(818, 965, 478, Personnage.EyeColors);
      Champ(978, 1510, 478, Personnage.SigneDistinctifV2);
      Champ(205, 508, 583, PMetier.Libelle);
      Champ(527, 1008, 583, PdfFeldoMetiersAnciens(Personnage));
      Champ(1030, 1515, 583, SortiesCarriereV1);

      LigneProfil;
      LignesArmes;
      LignesArmures;
      LignesCompetences;
    end;

  procedure Page2;
    var
      Equip:  StructurePersonnageEquipement;
      PSort:  StructureSort;
      Donnee: StructureDonnee;
      Bonus:  String;
      Ligne:  Integer = 0;
      Mouv:   Integer;
      Enc:    Integer = 0;
      Y:      Single;
      Reste:  String;
      Item:   String;
      Phrase: String;
      Hand:   StructureHandicapV1;
      Familier: StructureFamilierV1;
      Mots:   TStringList;
      I:      Integer;
      Stade:  Integer;
    begin
      NouvellePage(ConstCheminPdfBack);

      // Sorts : 9 lignes (nom, niveau, ingredient)
      for Equip in Personnage.Equipement do
        if (Equip.TypeEquipement = TypeEquipSp) and (Ligne < 9) then
          begin
            PSort := ChercheSort(Equip.CodeEquipement);
            Y     := 232 + 46 * Ligne;
            Champ(198, 472, Y, PSort.Libelle);
            Centre(515, Y, LibelleValeurLivre(PSort.Niveau));
            Champ(548, 610, Y, PSort.CoutMagieV1);
            Champ(618, 680, Y, PSort.Portee);
            Champ(686, 752, Y, PSort.Duree);
            Champ(760, 1010, Y, PSort.Ingredient);
            Champ(1018, 1296, Y, PSort.Description);
            Inc(Ligne);
          end;

      // Handicaps des magiciens : cadre Psychology & Health, un titre puis le texte du stade, a la ligne
      Reste := Personnage.HandicapsV1;
      Y     := 950;
      while Reste <> '' do
        begin
          Item  := ElementSuivantV1(Reste);
          Stade := StrToIntDef(Copy(Item, Pos('=', Item) + 1, 3), 0);
          Hand  := ChercheHandicapV1(Copy(Item, 1, Pos('=', Item) - 1));
          if (Hand.Libelle = '') or (Stade < 1) or (Stade > 3) then
            Continue;
          if Y <= 1125 then
            Champ(712, 1135, Y, Hand.Libelle + ' (' + IntToStr(Stade) + ')');
          Y     := Y + 32;
          Mots  := TStringList.Create;
          try
            ExtractStrings([' '], [], PChar(Hand.Texte[Stade]), Mots);
            Phrase := '';
            for I := 0 to Mots.Count - 1 do
              begin
                if (Phrase <> '') and (TailleTexte(Phrase + ' ' + Mots[I], PdfFontTaille) > (MX(1135) - MX(712)) * 1.15) then
                  begin
                    if Y <= 1125 then
                      Champ(712, 1135, Y, Phrase);
                    Y      := Y + 32;
                    Phrase := Mots[I];
                  end
                else if Phrase = '' then
                  Phrase := Mots[I]
                else
                  Phrase := Phrase + ' ' + Mots[I];
              end;
            if (Phrase <> '') and (Y <= 1125) then
              Champ(712, 1135, Y, Phrase);
            if Phrase <> '' then
              Y := Y + 32;
          finally
            Mots.Free;
          end;
        end;

      // Familier du Druidic Priest : espece, armure / bouclier permis, lieux de ressourcement
      if Personnage.FamilierV1 <> '' then
        begin
          Familier := ChercheFamilierV1(Personnage.FamilierV1);
          if Y <= 1125 then
            Champ(712, 1135, Y, Familier.Animal + ' : ' + Familier.Armure + IfThen(Familier.Bouclier, ' + shield', '') + ' (' + Familier.Lieux + ')');
          Y := Y + 32;
          // strictures du familier : armes interdites et regime
          if Y <= 1125 then
            Champ(712, 1135, Y, GetTexteLibelle('RULES-FAMDIET_FORBIDDEN') + ' : ' + Familier.ArmesInterdites + ' ; ' +
                  GetTexteLibelle('RULES-FAMDIET_DIET') + ' : ' + GetTexteLibelle('RULES-FAMDIET_' + Familier.Regime));
          Y := Y + 32;
        end;

      // Langues : une par ligne, 6 maxi
      Mots := TStringList.Create;
      try
        ListeLangues(Mots);
        for I := 0 to Mots.Count - 1 do
          if I < 6 then
            Champ(1105, 1295, 705 + 30 * I, ChercheCompetence(Mots[I]).Libelle);
      finally
        Mots.Free;
      end;

      // Destin, XP
      Donnee := PdfPersonnageAttribut(Personnage, ConstCaracDestin, Bonus);
      Centre(1413, 236, IntToStr(Donnee.Total));
      if Personnage.PointsMagie > 0 then
        Centre(1413, 350, IntToStr(Personnage.PointsMagie));
      if Personnage.FolieV1 > 0 then
        Centre(1224, 1010, IntToStr(Personnage.FolieV1));
      // Background : texte libre apres chaque etiquette imprimee de la feuille
      Champ(890, 1290, 1218, Personnage.NaissanceV1);
      Champ(955, 1290, 1255, Personnage.ParentsV1);
      Champ(915, 1290, 1294, Personnage.FamilleV1);
      Champ(1311, 1516, 580, IntToStr(Personnage.XpActuel) + ' / ' + IntToStr(Personnage.XpTotal));

      // Mouvement : cadence de la feuille = 2 M, 4 M, 16 M verges par round, 12 M, 24 M, 96 M par tour
      Donnee := PdfPersonnageAttribut(Personnage, 'RULES-ATTR_M', Bonus);
      Mouv   := Donnee.Total;
      Centre(911, 728, IntToStr(Mouv * 2));
      Centre(979, 728, IntToStr(Mouv * 12));
      Centre(911, 789, IntToStr(Mouv * 4));
      Centre(979, 789, IntToStr(Mouv * 24));
      Centre(911, 857, IntToStr(Mouv * 16));
      Centre(979, 857, IntToStr(Mouv * 96));

      // Equipement : 16 lignes
      Ligne := 0;
      for Equip in Personnage.Equipement do
        if (Equip.TypeEquipement = TypeEquipDI) and (Ligne < 16) then
          begin
            Champ(198, 545, 700 + 46 * Ligne, PdfDiversLibelle(Equip));
            if PdfDiversEncombrement(Equip) <> 0 then
              Centre(649, 700 + 46 * Ligne, IntToStr(PdfDiversEncombrement(Equip)));
            Enc := Enc + PdfDiversEncombrement(Equip);
            Inc(Ligne);
          end;
      if Enc <> 0 then
        Centre(649, 1500, IntToStr(Enc));

      // Argent
      if Personnage.MonnaieCO <> 0 then
        Champ(198, 545, 1600, IntToStr(Personnage.MonnaieCO) + ' GC');
      if Personnage.MonnaiePA <> 0 then
        Champ(198, 545, 1646, IntToStr(Personnage.MonnaiePA) + ' s');
      if Personnage.MonnaieSB <> 0 then
        Champ(198, 545, 1692, IntToStr(Personnage.MonnaieSB) + ' p');
    end;

  begin
    PdfCheminsSelonVersion(ValVersion);
    Personnage := PersonnageSansMunitions(Personnage);
    PdfChemin  := GetCurrentDir+ConstCheminPersonnage+Personnage.NomPersonnage+'\'+Personnage.NomPersonnage+' '+FormatDateTime('yyyymmdd-hhnnss', Now)+'.PDF';
    if FileExists(PdfChemin) then
      if not DeleteFile(PdfChemin) then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_038'));
          Exit;
        end;

    PDFDoc          := TPDFDocument.Create(nil);
    PDFDoc.Options  := [poUseImageTransparency, poCompressImages, poCompressFonts, poCompressText];
    PDFDoc.StartDocument;
    PdfSection      := PDFDoc.Sections.AddSection;
    PdfPolicesDeRepli;
    PdfFontBack     := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Bold.ttf'), ConstPoliceCarlson+ConstPoliceGras);
    PdfFontValue    := PdfDoc.AddFont(PdfCheminPolice('ariali.ttf'), ConstPoliceArial);
    PdfFontBold     := PdfDoc.AddFont(PdfCheminPolice('arialbd.ttf'), ConstPoliceArial+ConstPoliceGras);

    Page1;
    Page2;

    PDFDoc.SaveToFile(PdfChemin);
    PDFDoc.Free;
    PdfPurgeAnciens(PdfChemin);

    if not PdfSansOuverture then
      OpenDocument(PdfChemin);
  end;

// Options d'impression des astérisques (onglet PDF de WinPersonnage). NoAsterisk cache tout
// (numéros et montants) ; NoAmount garde les numéros "(N)" et retire les montants ("+10", "-10%").
Function PdfAsterisquesCachees(Personnage: StructurePersonnage): Boolean;
begin
  Result := Pos(AjouteAccolade(ConstXmlOptionSansAsterisque), Personnage.Options) > 0;
end;

// Applique l'option aux annotations déjà construites : Annotation (Name=code, Value=" +10 (3)"),
// ParPiece (numéros à côté d'une pièce/mutation) et AsterisqueArmure (numéros des Armour Points).
Procedure PdfAsterisquesFiltrer(Personnage: StructurePersonnage; Annotation, ParPiece: TStringList; var AsterisqueArmure: String);
var
  Ind, IndMot: Integer;
  Mots:        TStringList;
  Texte:       String;
begin
  if PdfAsterisquesCachees(Personnage) then
    begin
      Annotation.Clear;
      ParPiece.Clear;
      AsterisqueArmure := '';
      exit;
    end;
  if Pos(AjouteAccolade(ConstXmlOptionSansMontant), Personnage.Options) = 0 then
    exit;
  // ne garde que les mots "(N)" / "(N,M)" : les montants ne commencent jamais par une parenthèse
  Mots := TStringList.Create;
  try
    for Ind := 0 to Annotation.Count - 1 do
      begin
        Mots.Clear;
        ExtractStrings([' '], [], PChar(Annotation.ValueFromIndex[Ind]), Mots);
        Texte := '';
        for IndMot := 0 to Mots.Count - 1 do
          if Copy(Mots[IndMot], 1, 1) = '(' then
            Texte += ' ' + Mots[IndMot];
        Annotation.ValueFromIndex[Ind] := Texte;
      end;
  finally
    Mots.Free;
  end;
end;

// Bonus d'attribut d'un talent tel que construit au chargement ("+5 (2)", parties séparées par
// '-') : option cacher le tout = vide ; cacher les montants = on ne garde que les "(N)".
Function PdfBonusAttributFiltrer(Personnage: StructurePersonnage; Texte: String): String;
var
  Pos1, Pos2: Integer;
begin
  Result := Texte;
  if PdfAsterisquesCachees(Personnage) then
    Result := ''
  else if (Texte <> '') and (Pos(AjouteAccolade(ConstXmlOptionSansMontant), Personnage.Options) > 0) then
    begin
      Result := '';
      Pos1 := Pos('(', Texte);
      while Pos1 > 0 do
        begin
          Pos2 := PosEx(')', Texte, Pos1);
          if Pos2 = 0 then
            break;
          if Result <> '' then
            Result += ' ';
          Result += Copy(Texte, Pos1, Pos2 - Pos1 + 1);
          Pos1 := PosEx('(', Texte, Pos2);
        end;
    end;
end;

Function PdfPersonnageTalentBonus(Personnage: StructurePersonnage; CodeTalent: String): String;
var
  Indice: Integer;
  Bonus:  String = '';
begin
  // Meme piege que PersonnageTalentAsterisque (chargepersonnage.pas) : sans cette remise a
  // zero explicite, un talent sans astérisque propre affichait celle laissee par le DERNIER
  // appel qui en avait une - signale par Nono le 11/09/2026.
  Bonus := '';
  For Indice := 0 to high(Personnage.CreationTalent) do
    if MemeTalent(Personnage.CreationTalent[Indice].CodeTalent, CodeTalent) then
      if Personnage.CreationTalent[Indice].Asterisque <> 0 then
        Bonus := '(' + IntToStr(Personnage.CreationTalent[Indice].Asterisque) + ')';

  For Indice := 0 to high(Personnage.AugmentationTalent) do
    if MemeTalent(Personnage.AugmentationTalent[Indice].CodeTalent, CodeTalent) then
      if Personnage.AugmentationTalent[Indice].Asterisque <> 0 then
        Bonus := '(' + IntToStr(Personnage.AugmentationTalent[Indice].Asterisque) + ')';

  if PdfAsterisquesCachees(Personnage) then
    Bonus := '';
  Result := Bonus;
end;


Function PdfPersonnageCompetenceBonus(Personnage: StructurePersonnage; CodeCompetence: String): String;
var
  Indice: Integer;
  Bonus:  String = '';
begin
  // Meme piege que PdfPersonnageTalentBonus ci-dessus.
  Bonus := '';
  if PdfAsterisquesCachees(Personnage) then
    exit('');
  For Indice := 0 to high(Personnage.CreationCompetence35) do
    if CompareRechercheValeur(Personnage.CreationCompetence35[Indice].CodeCompetence, CodeCompetence) then
      if Personnage.CreationCompetence35[Indice].Bonus <> '' then
        if CountOccurrences(Personnage.CreationCompetence35[Indice].Bonus, Bonus) = 0 then
          begin
            if Bonus <> '' then
              Bonus += '-';
            Bonus += Personnage.CreationCompetence35[Indice].Bonus;
          end;

  For Indice := 0 to high(Personnage.CreationCompetence40) do
    if CompareRechercheValeur(Personnage.CreationCompetence40[Indice].CodeCompetence, CodeCompetence) then
      if Personnage.CreationCompetence40[Indice].Bonus <> '' then
        if CountOccurrences(Personnage.CreationCompetence40[Indice].Bonus, Bonus) = 0 then
          begin
            if Bonus <> '' then
              Bonus += '-';
            Bonus += Personnage.CreationCompetence40[Indice].Bonus;
          end;

  For Indice := 0 to high(Personnage.AugmentationCompetence) do
    if CompareRechercheValeur(Personnage.AugmentationCompetence[Indice].CodeCompetence, CodeCompetence) then
      if Personnage.AugmentationCompetence[indice].Bonus <> '' then
        if CountOccurrences(Personnage.AugmentationCompetence[Indice].Bonus, Bonus) = 0 then
          begin
            if Bonus <> '' then
              Bonus += '-';
            Bonus += Personnage.AugmentationCompetence[Indice].Bonus;
          end;

  Result := Bonus;
end;

Function PdfPersonnageArmureAsterisques(Personnage: StructurePersonnage; AsterisqueDepart: Integer; out AsterisqueParEquipement: TStringList; out AsterisqueFinal: Integer): TStringList;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    PArmure:              StructureArmure;
    PArmureSimplifiee:    StructureArmureSimplifiee;
    PArmureBonusModif:    StructureModificateur;
    ListeBonus:           String;
    NbLoca, IndLoca:       Integer;
    LocData:               String;
    AsterisqueCourant:      Integer;
    AsterisquePiece:        Integer;
    // Une piece par competence touchee sur la ligne, plutot qu'une ligne "(N) -10%" par
    // piece : trois pieces a -10% chacune sur la meme competence debordaient de la colonne
    // et se chevauchaient (retour de Nono, capture d'ecran du 14/09/2026). Name=CodeCompetence.
    NumerosParCompetence:  TStringList;
    TotalParCompetence:    TStringList;
    IndComp:                Integer;
    AsterisqueArmureTmp:    String;
  begin
    Result                   := TStringList.Create;
    AsterisqueParEquipement  := TStringList.Create;
    AsterisqueCourant        := AsterisqueDepart;
    NumerosParCompetence     := TStringList.Create;
    TotalParCompetence       := TStringList.Create;

    for PersonnageEquipement in Personnage.Equipement do
      if (PersonnageEquipement.TypeEquipement = TypeEquipAR) or (PersonnageEquipement.TypeEquipement = TypeEquipARS) then
        begin
          if PersonnageEquipement.TypeEquipement = TypeEquipAR then
            begin
              PArmure    := ChercheArmure(PersonnageEquipement.CodeEquipement);
              ListeBonus := PArmure.ListeBonus;
            end
          else
            begin
              PArmureSimplifiee := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement);
              ListeBonus         := PArmureSimplifiee.ListeBonus;
            end;

          if (ListeBonus <> '') and (ListeBonus <> '-') then
            begin
              NbLoca          := CountOccurrences(ListeBonus, ',') + 1;
              AsterisquePiece := 0; // une seule astérisque par pièce, partagée par toutes les compétences qu'elle touche
              for IndLoca := 1 to NbLoca do
                begin
                  LocData := ExtractChaine(',', ListeBonus, IndLoca);
                  if pos(' ', LocData) <> 0 then
                    LocData := copy(LocData,1,Pos(' ',LocData)-1);
                  for PArmureBonusModif in ListModificateur do
                    if EntreeCompetenceEquip(PArmureBonusModif) and CompareRechercheValeur(PArmureBonusModif.CodeSource, LocData) then
                      begin
                        if AsterisquePiece = 0 then
                          begin
                            Inc(AsterisqueCourant);
                            AsterisquePiece := AsterisqueCourant;
                            // même format court que les talents ("(3)") - retour de Nono le
                            // 16/08/2026, à côté de la pièce elle-même
                            AsterisqueParEquipement.Values[PersonnageEquipement.CodeEquipement] := '(' + IntToStr(AsterisquePiece) + ')';
                          end;
                        // Accumule ici (numeros + total) au lieu d'ecrire directement dans
                        // Result - la chaine finale ("(5,6,7) -30%") est construite apres la
                        // boucle equipement, une fois toutes les pieces vues.
                        if NumerosParCompetence.Values[PArmureBonusModif.Cible] = '' then
                          NumerosParCompetence.Values[PArmureBonusModif.Cible] := IntToStr(AsterisquePiece)
                        else
                          NumerosParCompetence.Values[PArmureBonusModif.Cible] := NumerosParCompetence.Values[PArmureBonusModif.Cible] + ',' + IntToStr(AsterisquePiece);
                        TotalParCompetence.Values[PArmureBonusModif.Cible] := IntToStr(StrToIntDef(TotalParCompetence.Values[PArmureBonusModif.Cible], 0) + PArmureBonusModif.Facteur);
                      end;
                end;
            end;
        end;

    // "(5,6,7) -30%" à côté de la compétence (idée d'origine de Nono) - la colonne
    // d'annotation a été élargie le 16/08/2026 (DessinerTableau, orLigne) pour que ça tienne
    // sur une seule ligne sans wrap PdfEcrit ; un numéro par pièce et un total groupés en
    // une seule annotation plutôt qu'une ligne par pièce (14/09/2026).
    for IndComp := 0 to NumerosParCompetence.Count - 1 do
      Result.Values[NumerosParCompetence.Names[IndComp]] := ' (' + NumerosParCompetence.ValueFromIndex[IndComp] + ') '
        + IntToStr(StrToIntDef(TotalParCompetence.Values[NumerosParCompetence.Names[IndComp]], 0)) + '%';

    NumerosParCompetence.Free;
    TotalParCompetence.Free;
    // dernier numero pris : la chaine continue apres (ex. l'astérisque de la monture)
    AsterisqueFinal := AsterisqueCourant;
    // option d'impression (onglet PDF) : pas d'armure ici dans AsterisqueArmure, chaine locale
    AsterisqueArmureTmp := '';
    PdfAsterisquesFiltrer(Personnage, Result, AsterisqueParEquipement, AsterisqueArmureTmp);
  end;

// Astérisques des qualités de fabrication portées (runes) : une astérisque par pièce d'armure
// PORTÉE dont une fabrication modifie une caractéristique (ModifyCarac) ou les PA (ModifArmour).
// "+10 (N)" à côté de la caractéristique (Result), "(N)" à côté des Armour Points
// (AsterisqueArmure) et, sous la clé "FAB:CodeEquipement" de AsterisqueParMutation, le numéro à
// écrire à côté de la pièce elle-même. 20/09/2026.
Procedure PdfFabricationAsterisques(Personnage: StructurePersonnage; var AsterisqueCourant: Integer; Annotation, ParPiece: TStringList; var AsterisqueArmure: String);
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    Liste:                TStringList;
    Element, Code:        String;
    Niveau, Valeur:       Integer;
    Ind, IndModif:        Integer;
    NumPiece:             Integer;
  begin
    Liste := TStringList.Create;
    try
      for PersonnageEquipement in Personnage.Equipement do
        if PersonnageEquipement.Porte
           and ((TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipAR))
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipARS))
                or (TrimRight(PersonnageEquipement.TypeEquipement) = TrimRight(TypeEquipWe)))
           and (PersonnageEquipement.QualiteEquipement <> '') then
          begin
            NumPiece := 0;
            Liste.Clear;
            ExtractStrings([','], [], PChar(PersonnageEquipement.QualiteEquipement), Liste);
            for Ind := 0 to Liste.Count - 1 do
              begin
                Element := Trim(Liste[Ind]);
                Code    := Element;
                Niveau  := 1;
                if Pos(' ', Element) > 0 then
                  begin
                    Code   := Trim(ExtractStringBefore(Element, ' '));
                    Niveau := StrToIntDef(Trim(Copy(Element, Pos(' ', Element) + 1, Length(Element))), 1);
                  end;
                for IndModif := 0 to ListModificateur.Count - 1 do
                  if EntreeFabrication(ListModificateur[IndModif]) and ((ListModificateur[IndModif].TypeModif = ConstXmlModifieAttribut)
                      or (ListModificateur[IndModif].TypeModif = ConstXmlModifieArmure)
                      // Degats (Cleaving) et Competence (Striking) : meme astérisque de piece que
                      // l'Attribut/l'Armure, mais sans texte "+X" - la valeur est deja incluse dans
                      // le total affiche sur la ligne de l'arme (FabricationModificateurQualite,
                      // PdfBlocArmesDonnees). A FAIRE.txt "FABRICATIONS", 25/09/2026.
                      or (ListModificateur[IndModif].TypeModif = ConstXmlModifieDegat)
                      or (ListModificateur[IndModif].TypeModif = ConstXmlModifieCompetence))
                     and CompareRechercheValeur(ListModificateur[IndModif].CodeSource, Code) then
                    begin
                      if NumPiece = 0 then
                        begin
                          Inc(AsterisqueCourant);
                          NumPiece := AsterisqueCourant;
                          ParPiece.Values['FAB:' + PersonnageEquipement.CodeEquipement] := '(' + IntToStr(NumPiece) + ')';
                        end;
                      Valeur := ListModificateur[IndModif].Facteur * Niveau;
                      if ListModificateur[IndModif].TypeModif = ConstXmlModifieAttribut then
                        begin
                          if Valeur >= 0 then
                            Annotation.Values[ListModificateur[IndModif].Cible] := Annotation.Values[ListModificateur[IndModif].Cible]
                              + ' +' + IntToStr(Valeur) + ' (' + IntToStr(NumPiece) + ')'
                          else
                            Annotation.Values[ListModificateur[IndModif].Cible] := Annotation.Values[ListModificateur[IndModif].Cible]
                              + ' ' + IntToStr(Valeur) + ' (' + IntToStr(NumPiece) + ')';
                        end
                      else if ListModificateur[IndModif].TypeModif = ConstXmlModifieArmure then
                        begin
                          if Pos('(' + IntToStr(NumPiece) + ')', AsterisqueArmure) = 0 then
                            AsterisqueArmure := AsterisqueArmure + '(' + IntToStr(NumPiece) + ')';
                        end;
                      // ConstXmlModifieDegat/ConstXmlModifieCompetence : la piece est deja marquee
                      // (ParPiece ci-dessus) ; aucune annotation supplementaire a ecrire, la valeur
                      // est deja dans le total Degats/Competence de la ligne.
                    end;
              end;
          end;
    finally
      Liste.Free;
    end;
  end;

Function PdfPersonnageMutationAsterisques(Personnage: StructurePersonnage; AsterisqueDepart: Integer; out AsterisqueParMutation: TStringList; out AsterisqueArmure: String; out AsterisqueFinal: Integer): TStringList;
  var
    PersonnageMutation:                 StructurePersonnageMutation;
    PCorruptionModificateur:            StructureModificateur;
    PCorruptionCompetenceAttributModif: StructureCorruptionCompetenceAttributModif;
    PCompetence:                        StructureCompetence;
    CodeGenerique:                      String;
    AsterisqueCourant:                  Integer;
    AsterisqueMutation:                 Integer;
    IndCompetence:                      Integer;
  begin
    Result                 := TStringList.Create;
    AsterisqueParMutation  := TStringList.Create;
    AsterisqueArmure       := '';
    AsterisqueCourant      := AsterisqueDepart;

    for PersonnageMutation in Personnage.Mutations do
      begin
        AsterisqueMutation := 0; // une seule astérisque par mutation, partagée par tous les codes qu'elle touche
        // ListCorruptionAttributModif -> filtre sur ListCorruptionModificateur (TypeModif =
        // ConstXmlModifieAttribut) depuis le 11/09/2026, migration ModifyCarac sur le moteur
        // generique - meme donnee, CodeSource remplace CodeCorruption et Cible/Facteur
        // remplacent CodeAttribut/Valeur.
        for PCorruptionModificateur in ListModificateur do
          if (PCorruptionModificateur.TypeSource = SourceModifMutation)
             and (PCorruptionModificateur.TypeModif = ConstXmlModifieAttribut)
             and CompareRechercheValeur(PCorruptionModificateur.CodeSource, PersonnageMutation.Code) then
            begin
              if AsterisqueMutation = 0 then
                begin
                  Inc(AsterisqueCourant);
                  AsterisqueMutation := AsterisqueCourant;
                  AsterisqueParMutation.Values[PersonnageMutation.Code] := '(' + IntToStr(AsterisqueMutation) + ')';
                end;
              // même format que les talents : la valeur signée suivie du numéro d'astérisque,
              // ex. "+10 (3)".
              if PCorruptionModificateur.Facteur >= 0 then
                Result.Values[PCorruptionModificateur.Cible] := Result.Values[PCorruptionModificateur.Cible]
                  + ' +' + IntToStr(PCorruptionModificateur.Facteur) + ' (' + IntToStr(AsterisqueMutation) + ')'
              else
                Result.Values[PCorruptionModificateur.Cible] := Result.Values[PCorruptionModificateur.Cible]
                  + ' ' + IntToStr(PCorruptionModificateur.Facteur) + ' (' + IntToStr(AsterisqueMutation) + ')';
            end;
        // ListCorruptionCompetenceModif -> filtre sur ListCorruptionModificateur (TypeModif =
        // ConstXmlModifieCompetence) depuis le 11/09/2026, meme migration que ModifyCarac plus
        // haut. Signale par Nono le 11/09/2026 : une Cible generique (ex. "RULES-COMPLANG_*",
        // famille de sous-competences comme les langues) n'annotait jamais aucune ligne
        // affichee - Result n'est lu que par CodeCompetence exact d'une sous-competence
        // (PdfPreparerRecordSetCompetencesBase/Groupees), jamais par le code generique
        // lui-meme. Meme parcours du catalogue que <ModifySkillAttribut> juste en dessous :
        // pour chaque competence, la Cible matche soit son propre code (cas direct), soit sa
        // forme generique si c'est une sous-competence (meme calcul que
        // PersonnageMutationCompetenceModif ci-dessus, chargepersonnage.pas).
        for PCorruptionModificateur in ListModificateur do
          if (PCorruptionModificateur.TypeSource = SourceModifMutation)
             and (PCorruptionModificateur.TypeModif = ConstXmlModifieCompetence)
             and CompareRechercheValeur(PCorruptionModificateur.CodeSource, PersonnageMutation.Code) then
            for IndCompetence := 0 to ListCompetence.Count - 1 do
              begin
                PCompetence   := ListCompetence[IndCompetence];
                CodeGenerique := '';
                if PCompetence.SousCompetence then
                  begin
                    // Lien explicite (CONTEXT.md 2.67) prioritaire sur la deduction par
                    // radical - seul repli quand <Generique> n'est pas renseigne.
                    if PCompetence.CodeGenerique <> '' then
                      CodeGenerique := PCompetence.CodeGenerique
                    else
                      CodeGenerique := CodeGeneriqueDeduit(PCompetence.CodeCompetence);
                  end;
                if CompareRechercheValeur(PCompetence.CodeCompetence, PCorruptionModificateur.Cible)
                   or ((CodeGenerique <> '') and CompareRechercheValeur(CodeGenerique, PCorruptionModificateur.Cible)) then
                  begin
                    if AsterisqueMutation = 0 then
                      begin
                        Inc(AsterisqueCourant);
                        AsterisqueMutation := AsterisqueCourant;
                        AsterisqueParMutation.Values[PersonnageMutation.Code] := '(' + IntToStr(AsterisqueMutation) + ')';
                      end;
                    // même format que les armures (ListArmureBonusModif) : "(N) valeur%".
                    Result.Values[PCompetence.CodeCompetence] := Result.Values[PCompetence.CodeCompetence]
                      + ' (' + IntToStr(AsterisqueMutation) + ') ' + IntToStr(PCorruptionModificateur.Facteur) + '%';
                  end;
              end;
        // Effets visant toutes les compétences d'un attribut de rattachement (ex. "-20 to all
        // Fellowship Tests", CORPHY_011, <ModifySkillAttribut>) - pas de code de compétence
        // unique ici, donc on parcourt le catalogue complet pour annoter chaque compétence
        // dont l'attribut correspond (même format "(N) valeur%" que ci-dessus).
        for PCorruptionCompetenceAttributModif in ListCorruptionCompetenceAttributModif do
          if CompareRechercheValeur(PCorruptionCompetenceAttributModif.CodeCorruption, PersonnageMutation.Code) then
            for IndCompetence := 0 to ListCompetence.Count - 1 do
              begin
                PCompetence := ListCompetence[IndCompetence];
                if CompareRechercheValeur(PCompetence.CodeAttribut, PCorruptionCompetenceAttributModif.CodeAttribut) then
                  begin
                    if AsterisqueMutation = 0 then
                      begin
                        Inc(AsterisqueCourant);
                        AsterisqueMutation := AsterisqueCourant;
                        AsterisqueParMutation.Values[PersonnageMutation.Code] := '(' + IntToStr(AsterisqueMutation) + ')';
                      end;
                    Result.Values[PCompetence.CodeCompetence] := Result.Values[PCompetence.CodeCompetence]
                      + ' (' + IntToStr(AsterisqueMutation) + ') ' + IntToStr(PCorruptionCompetenceAttributModif.Valeur) + '%';
                  end;
              end;
        // Effets sur les Armour Points (CORPHY_012/016/017, <ModifArmour>) - un seul
        // marqueur pour tout le bloc PdfBlocArmourPoints, peu importe combien de cases
        // sont touchées (choix de Nono, pas d'astérisque par case). Même AsterisqueMutation
        // que ci-dessus si la mutation touche aussi un Attribut/une Compétence.
        // ListCorruptionArmureModif -> filtre sur ListCorruptionModificateur (TypeModif =
        // ConstXmlModifieArmure) depuis le 11/09/2026.
        for PCorruptionModificateur in ListModificateur do
          if (PCorruptionModificateur.TypeSource = SourceModifMutation)
             and (PCorruptionModificateur.TypeModif = ConstXmlModifieArmure)
             and CompareRechercheValeur(PCorruptionModificateur.CodeSource, PersonnageMutation.Code) then
            begin
              if AsterisqueMutation = 0 then
                begin
                  Inc(AsterisqueCourant);
                  AsterisqueMutation := AsterisqueCourant;
                  AsterisqueParMutation.Values[PersonnageMutation.Code] := '(' + IntToStr(AsterisqueMutation) + ')';
                end;
              if Pos('(' + IntToStr(AsterisqueMutation) + ')', AsterisqueArmure) = 0 then
                AsterisqueArmure := AsterisqueArmure + '(' + IntToStr(AsterisqueMutation) + ')';
              Break;
            end;
      end;

    // Runes et autres fabrications portees (Rune of Fortitude, Rune of Stone).
    PdfFabricationAsterisques(Personnage, AsterisqueCourant, Result, AsterisqueParMutation, AsterisqueArmure);

    // Signe astral (Archives of the Empire II p.39).
    PdfSigneAstralAsterisque(Personnage, AsterisqueCourant, Result, AsterisqueParMutation);

    AsterisqueFinal := AsterisqueCourant;
    // option d'impression (onglet PDF) : cacher le tout ou seulement les montants
    PdfAsterisquesFiltrer(Personnage, Result, AsterisqueParMutation, AsterisqueArmure);
  end;

// Asterisque du signe astral : une seule, si le signe modifie au moins une caracteristique.
// " +2 (N)" a cote de chaque caracteristique touchee (Annotation) et "(N)" sous la cle SIGNE de
// ParPiece, a ecrire a cote du signe dans l'en-tete. Un signe qui ne donne qu'un talent n'en a pas.
Procedure PdfSigneAstralAsterisque(Personnage: StructurePersonnage; var AsterisqueCourant: Integer; Annotation, ParPiece: TStringList);
  var
    PEffet: StructureSigneEffet;
    Numero: Integer;
  begin
    if Personnage.SigneAstral = '' then
      Exit;
    Numero := 0;
    for PEffet in ListSigneEffet do
      if (PEffet.CodeSigne = Personnage.SigneAstral) and (PEffet.CodeAttribut <> '')
         and ((PEffet.Variante = '') or (PEffet.Variante = Personnage.SigneAstralVariante)) then
        begin
          if Numero = 0 then
            begin
              Inc(AsterisqueCourant);
              Numero := AsterisqueCourant;
              ParPiece.Values['SIGNE'] := '(' + IntToStr(Numero) + ')';
            end;
          if PEffet.Valeur >= 0 then
            Annotation.Values[PEffet.CodeAttribut] := Annotation.Values[PEffet.CodeAttribut]
              + ' +' + IntToStr(PEffet.Valeur) + ' (' + IntToStr(Numero) + ')'
          else
            Annotation.Values[PEffet.CodeAttribut] := Annotation.Values[PEffet.CodeAttribut]
              + ' ' + IntToStr(PEffet.Valeur) + ' (' + IntToStr(Numero) + ')';
        end;
  end;

// Dessine le cadre partagé Résilience/Destin (4 lignes de haut, de X à X+78) et le contenu
// du côté Résilience (colonnes X à X+40). Dans le gabarit Feldo2P, Résilience et Destin
// occupent physiquement UNE SEULE boîte, avec des séparateurs internes de hauteurs
// différentes (celui à X+40 ne descend pas jusqu'à la dernière ligne, celui à X+69 saute
// la ligne de titre) — les reproduire depuis deux cadres indépendants aurait changé le
// rendu (traits en double ou manquants). C'est pourquoi le cadre est dessiné ici en entier ;
// PdfBlocDestin ne dessine que son texte/ses valeurs. À revoir si on veut un jour deux
// tableaux vraiment indépendants (cf. CONTEXT.md §2.4).
//
// NbLignesPourSuite reproduit la valeur que la boucle "for IndC := 0 to DessinNbLigRes"
// laissait dans IndC après son exécution (NbLignes + 1), utilisée par le bloc
// Expérience pour calculer sa position de départ. Valeur préservée telle quelle pour ne
// rien changer visuellement ; à vérifier si ce "+1" est voulu ou un héritage accidentel
// avant de la retoucher plus tard.
//
// NbLignes/HauteurLigne remplacent les anciennes constantes locales DessinNbLigRes/
// DessinHauteurRes de PdfPersonnageCreationFeldo2P (hors de portée dans une procédure
// séparée) — l'appelant continue de passer ses valeurs actuelles (4 et 4.4), donc rien
// ne change au rendu.
Procedure PdfBlocResilience(PdfPage: TPDFPage; Personnage: StructurePersonnage; X, Y: Single; NbLignes: Integer; HauteurLigne: Single; MinPolice: Integer; Determine: Integer; out NbLignesPourSuite: Integer);
  var
    IndC:           Integer;
    Bonus:          String;
    AttributDonnee: StructureDonnee;
  begin
    // Dessin (cadre partagé Résilience + Destin)
    // Géométrie resserrée le 16/08/2026 (78mm -> 53mm) pour laisser Mouvement sur la même
    // rangée (CONTEXT.md §2.6) - anciens repères 29.9/40/69/78 devenus 20/27/46/53.
    if PdfStyle then
      PdfStyleBloc(PdfPage, X, X + 53, Y, HauteurLigne, NbLignes);
    PdfPage.DrawLine( X,      Y,                    X,      Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine( X+20,   Y - HauteurLigne,      X+20,   Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine( X+27,   Y,                     X+27,   Y - ((NbLignes-1) * HauteurLigne), 1);
    PdfPage.DrawLine( X+46,   Y - HauteurLigne,      X+46,   Y - ((NbLignes-1) * HauteurLigne), 1);
    PdfPage.DrawLine( X+53,   Y,                     X+53,   Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      PdfPage.DrawLine(X, Y - (IndC * HauteurLigne), X+53, Y - (IndC * HauteurLigne), 1);

    // Texte Résilience
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, X+2, X+25, Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_RESIL1_RESILIENCE'));
    PdfEcrit (PdfPage, X+2, X+18, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_RESIL2A_RESILIENCE'), MinPolice);
    PdfEcrit (PdfPage, X+2, X+18, Y - (3 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_RESIL2B_RESOLVE'),    MinPolice);
    PdfEcrit (PdfPage, X+2, X+50, Y - (NbLignes * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_RESIL2C_MOTIVATION'), MinPolice);

    // Valeur Résilience
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    AttributDonnee := PdfPersonnageAttribut(Personnage, ConstCaracResil, Bonus);
    PdfCentre(PdfPage, X+20, X+27, Y - (2 * HauteurLigne) + 1, IntToStr(AttributDonnee.Total));   // Résilience
    PdfCentre(PdfPage, X+20, X+27, Y - (3 * HauteurLigne) + 1, IntToStr(Determine));              // Détermination

    NbLignesPourSuite := NbLignes + 1;
  end;

// Dessine le contenu (texte + valeurs) du côté Destin de la boîte Résilience/Destin.
// Ne dessine aucun cadre : il est entièrement à la charge de PdfBlocResilience (voir son
// commentaire). XGauche doit correspondre au X+40 utilisé pour appeler PdfBlocResilience
// juste avant (le bord commun entre les deux zones). HauteurLigne remplace l'ancienne
// constante locale DessinHauteurDes (même valeur, 4.4, passée par l'appelant).
Procedure PdfBlocDestin(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, Y: Single; HauteurLigne: Single; MinPolice: Integer; Chance: Integer);
  var
    Bonus:          String;
    AttributDonnee: StructureDonnee;
  begin
    // Texte Destin
    // Géométrie resserrée le 16/08/2026 (38mm -> 26mm relatifs à XGauche), même chantier que
    // PdfBlocResilience (CONTEXT.md §2.6) - anciens repères 29/38 devenus 17/24.
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche+2,  XGauche+24, Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_FATE1_FATE'));
    PdfEcrit (PdfPage, XGauche+2,  XGauche+17, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_FATE2_FATE'),    MinPolice);
    PdfEcrit (PdfPage, XGauche+2,  XGauche+17, Y - (3 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_FATE3_FORTUNE'), MinPolice);

    // Valeur Destin
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    AttributDonnee := PdfPersonnageAttribut(Personnage, ConstCaracDestin, Bonus);
    PdfCentre(PdfPage, XGauche+17, XGauche+24, Y - (2 * HauteurLigne) + 1, IntToStr(AttributDonnee.Total));  // Destin
    PdfCentre(PdfPage, XGauche+17, XGauche+24, Y - (3 * HauteurLigne) + 1, IntToStr(Chance));                // Chance
  end;

// Dessine le panneau Entête (extrait de PdfPersonnageCreationFeldo2P, CONTEXT.md §2.4).
// Cadre à colonnes irrégulières : les séparateurs verticaux internes (52/82/114) ne sont pas
// les mêmes d'une ligne à l'autre (voir les conditions IndC = 4 / IndC <> 3 / IndC <> 2
// ci-dessous, reprises telles quelles de l'ancien code). XGauche/XDroite sont les bords du
// cadre, Y son sommet, HauteurLigne la hauteur d'une ligne et NbLignes son nombre de lignes.
Function PdfBlocEntete(PdfPage: TPDFPage; Personnage: StructurePersonnage; PRace: StructureRace; PMetier: StructureMetier; PMetierNiveau: StructureMetierNiveau; LocData: String; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; AnnotSigne: String): Single;
  var
    IndC: Integer;
    // Positions des colonnes, declarees une fois : deplacer une separation (XSep2, XSep3)
    // decale ses libelles et ses valeurs. Les valeurs sont donnees en decalage depuis la
    // separation de leur colonne (libelles differents d'une ligne a l'autre).
    XLib1, XVal1, XValChemin, XSep1, XLibTaille, XValTaille: Single;
    XSep2, XSep3, XLib2, XLib3: Single;
    XValEspece, XValNiveau, XValCheveux, XValClasse, XValStatut, XValYeux: Single;
  begin
    XLib1      := XGauche + 2;    // libelles de la 1re colonne (Name, Career, Career Path, Age)
    XVal1      := XLib1 + 11;     // valeurs de la 1re colonne (Name, Career, Age)
    XValChemin := XLib1 + 25;     // valeur de Career Path
    XSep1      := 52;   // separation Age | Height (ligne 4)
    XLibTaille := 53;   // libelle Height
    XValTaille := 63;   // valeur Height
    XSep2      := 72;   // separation avant Species / Career Level / Hair (etait 77)
    XSep3      := 108;  // separation avant Class / Status / Eyes (etait 114)
    XLib2      := XSep2 + 1;
    XLib3      := XSep3 + 1;
    XValEspece  := XSep2 + 12;
    XValNiveau  := XSep2 + 18;
    XValCheveux := XSep2 + 12;   // etait +21 : la valeur flottait loin du libelle et se reduisait
    XValClasse  := XSep3 + 12;
    XValStatut  := XSep3 + 11;
    XValYeux    := XSep3 + 11;

    if PdfStyle then
      begin
        // libelles : bandeau rouge sur toutes les cellules de libelle de l'en-tete
        PdfStyleEtiquette(PdfPage, XGauche,      XVal1 - 1,       Y,                      HauteurLigne);
        PdfStyleEtiquette(PdfPage, XSep2,        XValEspece - 1,  Y,                      HauteurLigne);
        PdfStyleEtiquette(PdfPage, XSep3,        XValClasse - 1,  Y,                      HauteurLigne);
        PdfStyleEtiquette(PdfPage, XGauche,      XVal1 - 1,       Y - HauteurLigne,       HauteurLigne);
        PdfStyleEtiquette(PdfPage, XSep2,        XValNiveau - 1,  Y - HauteurLigne,       HauteurLigne);
        PdfStyleEtiquette(PdfPage, XGauche,      XValChemin - 1,  Y - (2 * HauteurLigne), HauteurLigne);
        PdfStyleEtiquette(PdfPage, XSep3,        XValStatut - 1,  Y - (2 * HauteurLigne), HauteurLigne);
        PdfStyleEtiquette(PdfPage, XGauche,      XVal1 - 1,       Y - (3 * HauteurLigne), HauteurLigne);
        PdfStyleEtiquette(PdfPage, XSep1,        XValTaille - 1,  Y - (3 * HauteurLigne), HauteurLigne);
        PdfStyleEtiquette(PdfPage, XSep2,        XValCheveux - 1, Y - (3 * HauteurLigne), HauteurLigne);
        PdfStyleEtiquette(PdfPage, XSep3,        XValYeux - 1,    Y - (3 * HauteurLigne), HauteurLigne);
        if NbLignes >= 5 then
          PdfStyleEtiquette(PdfPage, XGauche,    XValChemin + 4,  Y - (4 * HauteurLigne), HauteurLigne);
        // valeurs : fond or pour Nom, Carriere et Statut seulement (les trois repères de la fiche)
        PdfStyleValeur(PdfPage, XVal1 - 1,      XSep2,   Y,                      HauteurLigne);
        PdfStyleValeur(PdfPage, XVal1 - 1,      XSep2,   Y - HauteurLigne,       HauteurLigne);
        PdfStyleValeur(PdfPage, XValStatut - 1, XDroite, Y - (2 * HauteurLigne), HauteurLigne);
      end;
    // Dessin cadre
    PdfPage.DrawLine(XGauche, Y, XGauche, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite, Y, XDroite, Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      begin
        PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);
        if (IndC > 0) and (IndC <= 4) then
          begin
            if IndC = 4  then PdfPage.DrawLine(XSep1, Y - ((IndC-1) * HauteurLigne), XSep1, Y - (IndC * HauteurLigne), 1);
            if IndC <> 3 then PdfPage.DrawLine(XSep2, Y - ((IndC-1) * HauteurLigne), XSep2, Y - (IndC * HauteurLigne), 1);
            if IndC <> 2 then PdfPage.DrawLine(XSep3, Y - ((IndC-1) * HauteurLigne), XSep3, Y - (IndC * HauteurLigne), 1);
          end;
      end;

    // Texte Entête
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfEcritTitre(PdfPage, XLib1,      Y - (HauteurLigne * 1) + 1, GetTexteLibelle('RULES-PDF_MAIN1_NAME'));
    PdfEcritTitre(PdfPage, XLib2,      Y - (HauteurLigne * 1) + 1, GetTexteLibelle('RULES-PDF_MAIN1_SPECIES'));
    PdfEcritTitre(PdfPage, XLib3,      Y - (HauteurLigne * 1) + 1, GetTexteLibelle('RULES-PDF_MAIN1_CLASS'));
    PdfEcritTitre(PdfPage, XLib1,      Y - (HauteurLigne * 2) + 1, GetTexteLibelle('RULES-PDF_MAIN2_CAREER'));
    PdfEcritTitre(PdfPage, XLib2,      Y - (HauteurLigne * 2) + 1, GetTexteLibelle('RULES-PDF_MAIN2_CAREERLEVEL'));
    PdfEcritTitre(PdfPage, XLib1,      Y - (HauteurLigne * 3) + 1, GetTexteLibelle('RULES-PDF_MAIN3_CAREERPATH'));
    PdfEcritTitre(PdfPage, XLib3,      Y - (HauteurLigne * 3) + 1, GetTexteLibelle('RULES-PDF_MAIN3_STATUS'));
    PdfEcritTitre(PdfPage, XLib1,      Y - (HauteurLigne * 4) + 1, GetTexteLibelle('RULES-PDF_MAIN4_AGE'));
    PdfEcritTitre(PdfPage, XLibTaille, Y - (HauteurLigne * 4) + 1, GetTexteLibelle('RULES-PDF_MAIN4_HEIGHT'));
    PdfEcritTitre(PdfPage, XLib2,      Y - (HauteurLigne * 4) + 1, GetTexteLibelle('RULES-PDF_MAIN4_HAIR'));
    PdfEcritTitre(PdfPage, XLib3,      Y - (HauteurLigne * 4) + 1, GetTexteLibelle('RULES-PDF_MAIN4_EYES'));
    if NbLignes >= 5 then
      PdfEcritTitre(PdfPage, XLib1,    Y - (HauteurLigne * 5) + 1, GetTexteLibelle('RULES-LAB_272'));

    // Valeur Entête (chaque valeur s'arrete a la separation suivante, moins 1)
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    PdfValeurGras(PdfPage, True);
    PdfEcrit(PdfPage, XVal1,       XSep2 - 1, Y - (HauteurLigne * 1) + 1, Personnage.NomPersonnage, MinPolice);
    PdfValeurGras(PdfPage, False);
    PdfEcrit(PdfPage, XValEspece,  XSep3 - 1, Y - (HauteurLigne * 1) + 1, PersonnageRaceLibelle(Personnage, PRace.Libelle), MinPolice);
    PdfEcrit(PdfPage, XValClasse,  XDroite,   Y - (HauteurLigne * 1) + 1, GetTexteLibelle(PMetier.LibelleGroupe), MinPolice);
    PdfValeurGras(PdfPage, True);
    if Trim(Personnage.Appartenance) <> '' then
      PdfEcrit(PdfPage, XVal1, XSep2 - 1, Y - (HauteurLigne * 2) + 1, PMetier.Libelle + ' (' + LibelleAppartenances(Personnage.Appartenance) + ')', MinPolice)
    else
      PdfEcrit(PdfPage, XVal1, XSep2 - 1, Y - (HauteurLigne * 2) + 1, PMetier.Libelle, MinPolice);
    PdfValeurGras(PdfPage, False);
    PdfEcrit(PdfPage, XValNiveau,  XDroite,   Y - (HauteurLigne * 2) + 1, IntToStr(Personnage.MetierEnCours.NiveauMetier)+' - '+ LibelleNiveauSelonSexe(PMetierNiveau, Personnage.SexeV2), MinPolice);
    // Zone Career Path : jusqu'a la separation Status, pas jusqu'a XDroite.
    PdfEcrit(PdfPage, XValChemin,  XSep3 - 1, Y - (HauteurLigne * 3) + 1, LocData, MinPolice);
    // Prefixe RULES- ajoute le 12/09/2026 - meme correctif que le gabarit normal, voir son
    // commentaire (CONTEXT.md 2.49/2.61).
    PdfValeurGras(PdfPage, True);
    PdfEcrit(PdfPage, XValStatut,  XDroite,   Y - (HauteurLigne * 3) + 1, GetTexteLibelle('RULES-' + StatutAdapte(PMetierNiveau.SalaireMetier, PMetier.CodeMetier, Personnage.Race, Personnage.ChoixAdaptation), '', ' '), MinPolice);
    PdfValeurGras(PdfPage, False);
    PdfEcrit(PdfPage, XVal1,       XSep1,     Y - (HauteurLigne * 4) + 1, IntToStr(Personnage.Age), MinPolice);
    if Personnage.Height > 0 then
      PdfEcrit(PdfPage, XValTaille,  XSep2,     Y - (HauteurLigne * 4) + 1, FormateTaille(Personnage.Height, Personnage.HeightUnit), MinPolice);
    PdfEcrit(PdfPage, XValCheveux, XSep3 - 1, Y - (HauteurLigne * 4) + 1, Personnage.HairColors, MinPolice);
    PdfEcrit(PdfPage, XValYeux,    XDroite,   Y - (HauteurLigne * 4) + 1, Personnage.EyeColors, MinPolice);
    // Signe astral (Archives of the Empire II p.39) : ligne pleine largeur, nom, effets et astérisque
    if (NbLignes >= 5) and (Personnage.SigneAstral <> '') then
      begin
        // Le texte s'arrete 8 mm avant le bord : l'asterisque "(N)" s'ecrit a droite en petite police
        // (meme principe que les annotations de talents).
        PdfEcrit(PdfPage, XValChemin + 5, XDroite - 8, Y - (HauteurLigne * 5) + 1,
          Trim(ChercheSigneAstral(Personnage.SigneAstral).Libelle + ' - '
               + SigneAstralTextePdf(Personnage.SigneAstral, Personnage.SigneAstralVariante)), MinPolice);
        if AnnotSigne <> '' then
          begin
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 5);
            PdfEcrit(PdfPage, XDroite - 8, XDroite - 1, Y - (HauteurLigne * 5) + 1.5, AnnotSigne, 4);
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
          end;
      end;

    Result := Y - (NbLignes * HauteurLigne);
  end;

// Dessine le panneau Ambitions (extrait de PdfPersonnageCreationFeldo2P, CONTEXT.md §2.4).
// XGauche+19.9 remplace l'ancienne constante absolue 39.9 (= 20 + 19.9, avec 20 = l'ancien
// DessinDebColG) pour que le bloc ne connaisse que son coin de départ.
// Page 2 depuis le 27/09/2026 (a la demande de Nono) : place liberee a droite du schema
// d'Armour Points, au-dessus du bloc Montures/Navires (PdfBlocMontures, qui demarre desormais
// sous ce bloc-ci au lieu de partager le meme Y).
// Scinde en 2 sous-blocs le 27/09/2026 (a la demande de Nono) : titre "AMBITIONS" (perso,
// court/long) puis, en dessous, un second titre "AMBITIONS <nom du groupe>" (ou generique
// "AMBITIONS <PARTY>" si le personnage n'est dans aucun groupe) suivi des memes 2 lignes -
// le prefixe "Party" devant les libelles Court/Long n'est donc plus necessaire, le titre du
// sous-bloc porte deja l'info. NbLignes=6 (2 titres + 2*2 donnees).
Function PdfBlocAmbitions(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; MinPolice: Integer): Single;
  const
    NbLignes    = 6;
    LargeurLib  = 16;
  var
    IndC:                       Integer;
    AmbitionGroupeCourt, AmbitionGroupeLong, TitreGroupe: String;
    GroupeComplet:              StructureGroupe;
  begin
    // Dans un groupe, l'ambition de groupe vient du fichier de groupe (CONTEXT.md 2.100) et
    // plus de Personnage.AmbitionGroupeCourt/Long (non tenu a jour des qu'un groupe existe).
    if Personnage.GroupeId <> '' then
      begin
        GroupeComplet       := ChargeGroupeComplet(GetCurrentDir + ConstCheminPersonnage, Personnage.GroupeId);
        AmbitionGroupeCourt := GroupeComplet.AmbitionCourt;
        AmbitionGroupeLong  := GroupeComplet.AmbitionLong;
        TitreGroupe         := GetTexteLibelle('RULES-PDF_AMBITION1_AMBITIONS')+' '+Personnage.GroupeId;
      end
    else
      begin
        AmbitionGroupeCourt := Personnage.AmbitionGroupeCourt;
        AmbitionGroupeLong  := Personnage.AmbitionGroupeLong;
        TitreGroupe         := GetTexteLibelle('RULES-PDF_AMBITION1_AMBITIONS')+' '+GetTexteLibelle('RULES-PDF_PARTY1_PARTY');
      end;
    // Dessin cadre : cadre exterieur + separateurs horizontaux (les 2 titres, lignes 1 et 4,
    // couvrent toute la largeur) ; le separateur vertical libelle/valeur est interrompu sur
    // ces 2 lignes de titre.
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y - (3 * HauteurLigne), HauteurLigne);
      end;
    PdfPage.DrawLine(XGauche, Y, XGauche, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite, Y, XDroite, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XGauche + LargeurLib, Y - HauteurLigne,     XGauche + LargeurLib, Y - (3 * HauteurLigne), 1);
    PdfPage.DrawLine(XGauche + LargeurLib, Y - (4 * HauteurLigne), XGauche + LargeurLib, Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Titres (centres, pleine largeur) + libelles (colonne de gauche)
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche + 2, XDroite, Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_AMBITION1_AMBITIONS'));
    PdfEcrit (PdfPage, XGauche + 2, XGauche + LargeurLib, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_AMBITION2A_SHORT')+GetTexteLibelle('RULES-PDF_AMBITION2B_SHORT'), MinPolice);
    PdfEcrit (PdfPage, XGauche + 2, XGauche + LargeurLib, Y - (3 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_AMBITION3A_LONG')+GetTexteLibelle('RULES-PDF_AMBITION3B_LONG'), MinPolice);
    PdfTitreCentre(PdfPage, XGauche + 2, XDroite, Y - (4 * HauteurLigne) + 1, TitreGroupe);
    PdfEcrit (PdfPage, XGauche + 2, XGauche + LargeurLib, Y - (5 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_AMBITION2A_SHORT')+GetTexteLibelle('RULES-PDF_AMBITION2B_SHORT'), MinPolice);
    PdfEcrit (PdfPage, XGauche + 2, XGauche + LargeurLib, Y - (6 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_AMBITION3A_LONG')+GetTexteLibelle('RULES-PDF_AMBITION3B_LONG'), MinPolice);
    // Saisie libre du joueur (Personnage.AmbitionCourt/Long/GroupeCourt/GroupeLong,
    // winpersonnage.pas) - jusqu'ici le cadre restait vide, a completer a la main.
    if PdfStyle then
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9)
    else
      PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson, 10);
    PdfEcrit (PdfPage, XGauche + LargeurLib + 2, XDroite - 1, Y - (2 * HauteurLigne) + 1, Personnage.AmbitionCourt, MinPolice);
    PdfEcrit (PdfPage, XGauche + LargeurLib + 2, XDroite - 1, Y - (3 * HauteurLigne) + 1, Personnage.AmbitionLong, MinPolice);
    PdfEcrit (PdfPage, XGauche + LargeurLib + 2, XDroite - 1, Y - (5 * HauteurLigne) + 1, AmbitionGroupeCourt, MinPolice);
    PdfEcrit (PdfPage, XGauche + LargeurLib + 2, XDroite - 1, Y - (6 * HauteurLigne) + 1, AmbitionGroupeLong, MinPolice);

    Result := Y - (NbLignes * HauteurLigne);
  end;

// Dessine le panneau Expérience (titre + Total/Utilisé/Restant). Extrait de
// PdfPersonnageCreationFeldo2P, CONTEXT.md §2.4.
Function PdfBlocExperience(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer): Single;
  var
    IndC: Integer;
    XpTotalAffiche: Integer;
  begin
    // Option XpDiv25 (CONTEXT.md §2.48) : en mode coché, Xp25Total et XpActuel sont déjà
    // tous les deux exprimés en unités divisées par 25 au moment de la sauvegarde
    // (winpersonnage.pas, Restante := Personnage.Xp25Total - Depense) - il n'existe pas de
    // second champ "Xp25Actuel", XpActuel sert les deux modes. Pas de division ici : on
    // choisit juste la paire de champs déjà cohérente entre elle, sous peine de mélanger
    // absolu et divisé (bug observé avec Nono le 11/09/2026).
    if Pos(AjouteAccolade(ConstXmlOptionXpDiv25), Personnage.Options) > 0 then
      XpTotalAffiche := Personnage.Xp25Total
    else
      XpTotalAffiche := Personnage.XpTotal;
    // Separateur libelles/valeur elargi le 12/09/2026 (23 au lieu de 15, Nono) - meme
    // traitement que PdfBlocMouvement/PdfBlocCorruption, colonne valeur inchangee (10mm),
    // tout le gain de largeur va aux libelles (CONTEXT.md 2.59).
    if PdfStyle then
      PdfStyleBloc(PdfPage, XGauche, XDroite, Y, HauteurLigne, NbLignes);
    // Dessin cadre
    PdfPage.DrawLine(XGauche,      Y,                 XGauche,      Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XGauche + 23, Y - HauteurLigne,   XGauche + 23, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite,      Y,                 XDroite,      Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Texte Expérience
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche + 1, XDroite,      Y - ((NbLignes - 3) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_XP1_EXPERIENCE'));
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_XP2C_TOTAL')  , MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_XP2B_SPENT') , MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ( NbLignes      * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_XP2A_CURRENT'), MinPolice);

    // Valeur Expérience
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, IntToStr(XpTotalAffiche));                              // Total Xp
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, IntToStr(XpTotalAffiche - Personnage.XpActuel));        // Utilisé
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ( NbLignes      * HauteurLigne) + 0.6, IntToStr(Personnage.XpActuel));                         // Restant

    Result := Y - (NbLignes * HauteurLigne);
  end;

// Dessine le panneau Mouvement (titre + Mouvement/Marche/Course). Extrait de
// PdfPersonnageCreationFeldo2P, CONTEXT.md §2.4.
Function PdfBlocMouvement(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; Mouv, BonusSprint: Integer): Single;
  var
    IndC: Integer;
  begin
    // Separateur libelles/valeur elargi le 12/09/2026 (23 au lieu de 15, Nono) pour que le
    // bord droit du cadre (XDroite) retombe sur celui d'Ambitions une fois DessinLargeurMou
    // elargi d'autant (CONTEXT.md 2.59) - meme "+15" que Resilience/Corruption a l'origine,
    // desormais propre a Mouvement.
    if PdfStyle then
      PdfStyleBloc(PdfPage, XGauche, XDroite, Y, HauteurLigne, NbLignes);
    // Dessin cadre
    PdfPage.DrawLine(XGauche,      Y,                 XGauche,      Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XGauche + 23, Y - HauteurLigne,   XGauche + 23, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite,      Y,                 XDroite,      Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Texte Mouvement
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche + 1, XDroite,      Y - ((NbLignes - 3) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_MV1_MOVEMENT'));
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_MV2A_MOVEMENT'), MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_MV2B_WALK')    , MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ( NbLignes      * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_MV2C_RUN')     , MinPolice);

    // Valeur Mouvement
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, IntToStr(Mouv));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, IntToStr(Mouv * 2));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ( NbLignes      * HauteurLigne) + 0.6, IntToStr((Mouv + BonusSprint) * 4));

    Result := Y - (NbLignes * HauteurLigne);
  end;

// Dessine le panneau Corruption (titre + Tolérance/Volonté/Bonus/Total). Extrait de
// PdfPersonnageCreationFeldo2P, CONTEXT.md §2.4.
Function PdfBlocCorruption(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; BE, BFM, AmePure, Lost: Integer): Single;
  var
    IndC:  Integer;
    Total: Integer;
  begin
    // Separateur libelles/valeur elargi le 12/09/2026 (23 au lieu de 15, Nono) : meme
    // traitement que PdfBlocMouvement, colonne valeur gardee a largeur identique (10mm),
    // tout le gain de largeur va aux libelles (CONTEXT.md 2.59).
    if PdfStyle then
      PdfStyleBloc(PdfPage, XGauche, XDroite, Y, HauteurLigne, NbLignes);
    // Dessin cadre
    PdfPage.DrawLine(XGauche,      Y,                 XGauche,      Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XGauche + 23, Y - HauteurLigne,   XGauche + 23, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite,      Y,                 XDroite,      Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    Total := Floor(BE/10) + Floor(BFM/10) + AmePure;

    // Texte Corruption
    // Lignes Lost/Left ajoutées le 16/08/2026 (historique de corruption, CONTEXT.md §2.6) :
    // Lost = somme des montants de Personnage.Corruption, Left = Total - Lost.
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche + 1, XDroite,      Y - ((NbLignes - 6) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_CORRUPTION_TITLE'));
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 5) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_CORRUPTION_T')    , MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 4) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_CORRUPTION_WP')   , MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 3) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_CORRUPTION_BONUS'), MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_CORRUPTION_TOTAL'), MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_CORRUPTION_LOST') , MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ( NbLignes      * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_CORRUPTION_LEFT') , MinPolice);

    // Valeur Corruption
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 5) * HauteurLigne) + 0.6, IntToStr(Floor(BE/10)));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 4) * HauteurLigne) + 0.6, IntToStr(Floor(BFM/10)));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 3) * HauteurLigne) + 0.6, IntToStr(AmePure));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, IntToStr(Total));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, IntToStr(Lost));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ( NbLignes      * HauteurLigne) + 0.6, IntToStr(Total - Lost));

    Result := Y - (NbLignes * HauteurLigne);
  end;

// Dessine le panneau Richesse : titre puis Couronnes d'or / Pistoles d'argent / Sous de laiton,
// memes libelles que le cadre Wealth de la page 2 du PDF normal (RULES-PDF_WEALTH*).
Function PdfBlocRichesse(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; MinPolice: Integer): Single;
  const
    NbLignes = 4;
  var
    IndC: Integer;
  begin
    if PdfStyle then
      PdfStyleBloc(PdfPage, XGauche, XDroite, Y, HauteurLigne, NbLignes);
    PdfPage.DrawLine(XGauche,      Y,                 XGauche,      Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XGauche + 23, Y - HauteurLigne,   XGauche + 23, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite,      Y,                 XDroite,      Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche + 1, XDroite,      Y - ((NbLignes - 3) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_WEALTH1_WEALTH'));
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_WEALTH4_GC'), MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_WEALTH3_SS'), MinPolice);
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 23, Y - ( NbLignes      * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_WEALTH2_D') , MinPolice);

    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, IntToStr(Personnage.MonnaieCO));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, IntToStr(Personnage.MonnaiePA));
    PdfCentre(PdfPage, XGauche + 23, XDroite, Y - ( NbLignes      * HauteurLigne) + 0.6, IntToStr(Personnage.MonnaieSB));

    Result := Y - (NbLignes * HauteurLigne);
  end;

// Dessine le tableau détaillé de l'historique de corruption (titre + en-têtes Amount/
// Reason + une ligne par entrée, la plus récente en haut). Extrait dans
// PdfPersonnageCreationFeldo2P, CONTEXT.md §2.6.
Function PdfBlocCorruptionDetail(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer): Single;
  var
    IndC:      Integer;
    IndLigne:  Integer;
    IndTab:    Integer;
    Montant:   String;
  begin
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleEntete(PdfPage, XGauche, XDroite, Y - HauteurLigne, HauteurLigne);
        PdfStyleZebra(PdfPage, XGauche, XDroite, Y, HauteurLigne, 3, NbLignes - 1);
      end;
    // Dessin cadre
    PdfPage.DrawLine(XGauche,     Y,                      XGauche,     Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XGauche + 12, Y - (2 * HauteurLigne),  XGauche + 12, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite,     Y,                       XDroite,     Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Titre + en-têtes de colonnes
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche + 1, XDroite,      Y - HauteurLigne + 0.6,             GetTexteLibelle('RULES-PDF_CORRUPTION_HISTORY'));
    PdfEcrit (PdfPage, XGauche + 1, XGauche + 12,  Y - (2 * HauteurLigne) + 0.6, GetTexteLibelle('RULES-LAB_162'), MinPolice); // Amount
    PdfEcrit (PdfPage, XGauche + 13, XDroite,      Y - (2 * HauteurLigne) + 0.6, GetTexteLibelle('RULES-LAB_163'), MinPolice); // Reason

    // Lignes de données : la plus récente (fin du tableau) en haut ; au-delà de la
    // capacité du cadre (NbLignes - 2 lignes de données), les plus anciennes sont
    // silencieusement omises (même limite que PdfBlocDiversDonnees pour Divers).
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    IndLigne := 0;
    for IndTab := High(Personnage.Corruption) downto Low(Personnage.Corruption) do
      begin
        Inc(IndLigne);
        if IndLigne <= (NbLignes - 2) then
          begin
            if Personnage.Corruption[IndTab].Montant > 0 then
              Montant := '+' + IntToStr(Personnage.Corruption[IndTab].Montant)
            else
              Montant := IntToStr(Personnage.Corruption[IndTab].Montant);
            PdfCentre(PdfPage, XGauche + 1,  XGauche + 12, Y - ((IndLigne + 2) * HauteurLigne) + 0.6, Montant);
            // Libellé souvent trop long pour tenir sur une ligne dans cette colonne étroite :
            // PdfEcrit le répartit alors sur 2 lignes (±1mm autour du Y donné) - avec le même
            // décalage +0.6 que le cas court, la 2e ligne déborde sous la bordure du bas de la
            // rangée (chevauche la ligne suivante). Remonté à +2 quand le texte est probablement
            // sur 2 lignes (même heuristique de longueur que PdfBlocTalents pour PTalent.Resume).
            if Length(Personnage.Corruption[IndTab].Libelle) > 18 then
              PdfEcrit (PdfPage, XGauche + 13, XDroite, Y - ((IndLigne + 2) * HauteurLigne) + 2, Personnage.Corruption[IndTab].Libelle, MinPolice)
            else
              PdfEcrit (PdfPage, XGauche + 13, XDroite, Y - ((IndLigne + 2) * HauteurLigne) + 0.6, Personnage.Corruption[IndTab].Libelle, MinPolice);
          end;
      end;

    Result := Y - (NbLignes * HauteurLigne);
  end;

// Dessine le panneau Talents (extrait de PdfPersonnageCreationFeldo2P, CONTEXT.md §2.4).
// Voir le commentaire de la déclaration pour pourquoi ce n'est pas passé par DessinerTableau.
Function PdfBlocTalents(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer): Single;
  var
    IndC:          Integer;
    NbLigne:       Integer;
    PTalent:       StructureTalent;
    NivTalMetier:  Integer;
    TalentDonnee:  StructureDonnee;
    Bonus:         String;
    ListeTalent:   String;
    PMetierTalent: StructureMetierTalent;
    ListeRegle:    TListCareerBonusSpecialRule;
    PRegle:        StructureCareerBonusSpecialRule;
    PMutationTalent: StructurePersonnageTalent;
    PArmureBonusTalent: StructurePersonnageTalent;
    LimiteLigne:   Integer;
    BranchesChoix: TStringList;
    IndBranche:    Integer;
    LibelleChoix:  String;

  // Vrai si le talent de carriere (ou l'une des branches d'un choix "A/B") est deja possede.
  function TalentCarriereDejaPris(CodeCarriere: String): Boolean;
    var
      Branches: TStringList;
      IndBr:    Integer;
    begin
      Result := False;
      Branches := TStringList.Create;
      try
        Branches.StrictDelimiter := True;
        Branches.Delimiter       := SeparateurMulti;
        Branches.DelimitedText   := CodeCarriere;
        for IndBr := 0 to Branches.Count - 1 do
          if Pos(AjouteAccolade(Branches[IndBr]), ListeTalent) <> 0 then
            Result := True;
      finally
        Branches.Free;
      end;
    end;

  begin
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleEntete(PdfPage, XGauche, XDroite, Y - HauteurLigne, HauteurLigne);
        PdfStyleZebra(PdfPage, XGauche, XDroite, Y, HauteurLigne, 3, NbLignes - 1);
      end;
    // Dessin cadre
    PdfPage.DrawLine( XGauche,      Y,                     XGauche,      Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 41, Y - (1 * HauteurLigne), XGauche + 41, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 47, Y - (1 * HauteurLigne), XGauche + 47, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 53, Y - (1 * HauteurLigne), XGauche + 53, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine( XDroite,      Y,                     XDroite,      Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Texte Talents
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche,      XDroite,      Y - (1 * HauteurLigne) + 1, Trim(GetTexteLibelle('RULES-PDF_TALENT1_TALENTS')));
    PdfCentre(PdfPage, XGauche,      XGauche + 40, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TALENT2_TALENTNAME'));
    PdfCentre(PdfPage, XGauche + 41, XGauche + 47, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TALENT2_UPG'));
    PdfCentre(PdfPage, XGauche + 47, XGauche + 51, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TALENT2_LEVEL'));
    PdfCentre(PdfPage, XGauche + 53, XDroite,      Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TALENT2_DESC'));

    // Valeur Talents
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    ListeTalent := '';
    NbLigne := 0;
    // Plafond : NbLignes - 2 lignes de données (2 lignes d'en-tête). Si les talents acquis ne
    // tiennent pas, la dernière ligne est réservée à "..." (les suivants sont omis à l'affichage).
    LimiteLigne := NbLignes - 2;
    if PdfNbTalentsAcquis(Personnage) > LimiteLigne then
      LimiteLigne := LimiteLigne - 1;
    For IndC := 0 to ListTalent.count - 1 do
      begin
        PTalent := ListTalent[IndC];
        NivTalMetier := 0;
        TalentDonnee := PdfPersonnageTalent(Personnage, PTalent.CodeTalent, NivTalMetier);
        if TalentDonnee.Total <> 0 then
          begin
            inc(NbLigne);
            if NbLigne > LimiteLigne then Continue;
            PdfEcrit(PdfPage, XGauche + 2, XGauche + 41, Y - ((NbLigne + 2) * HauteurLigne) + 1, PTalent.Libelle, MinPolice);
            // Virtue of the Quest (CONTEXT.md 2.78) : talent possede mais dont les effets
            // sont en sommeil hors de la carriere+niveau qui l'a accorde - barre plutot
            // que retire (le vrai retrait n'est pas encore mecanise).
            if PersonnageTalentEstBarre(Personnage, PTalent.CodeTalent) then
              PdfPage.DrawLine(XGauche + 2, Y - ((NbLigne + 2) * HauteurLigne) + 1.8,
                                XGauche + 41, Y - ((NbLigne + 2) * HauteurLigne) + 1.8, 0.5);
            Bonus := PdfPersonnageTalentBonus(Personnage, PTalent.CodeTalent);
            // Afficher l'astérisque pour les talents
            if Bonus <> '' then
              begin
                PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 4);
                PdfEcrit(PdfPage, XGauche + 38, XGauche + 41, Y - ((NbLigne + 2) * HauteurLigne) + 3, Bonus, 4);
                PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
              end;
            if (NivTalMetier > 0) then
              begin
                if (NivTalMetier > Personnage.MetierEnCours.NiveauMetier) then
                  PdfPage.SetColor(RGB(150,150,150), False);
                PdfEcrit(PdfPage, XGauche + 43, XGauche + 47, Y - ((NbLigne + 2) * HauteurLigne) + 1, IntToStr(NivTalMetier), MinPolice);
                PdfPage.SetColor(clBlack, False);
              end;
            PdfCentre(PdfPage, XGauche + 47, XGauche + 53, Y - ((NbLigne + 2) * HauteurLigne) + 1, IntToStr(TalentDonnee.Total));
            if PTalent.SousTalent then
              PTalent := ChercheTalent(CodeTalentGenerique(PTalent));
            if PTalent.Resume <> '' then
              begin
                if Length(PTalent.Resume) > 20 then
                  PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 2) * HauteurLigne) + 1.5, PTalent.Resume, MinPolice)
                else
                  PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 2) * HauteurLigne) + 1, PTalent.Resume, MinPolice);
                PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
              end;
            ListeTalent += AjouteAccolade(PTalent.CodeTalent);
          end;
      end;

    // Regles speciales des appartenances (palier "Knight of the Inner Circle" et
    // equivalents, sans bonus chiffre) - affichees comme des talents virtuels
    // supplementaires, meme bloc, meme mise en forme. CONTEXT.md 2.51, 08/09/2026.
    ListeRegle := PersonnageCareerBonusSpecialRule(Personnage);
    try
      for IndC := 0 to ListeRegle.Count - 1 do
        begin
          PRegle := ListeRegle[IndC];
          inc(NbLigne);
          if NbLigne > LimiteLigne then Continue;
          PdfEcrit(PdfPage, XGauche + 2, XGauche + 41, Y - ((NbLigne + 2) * HauteurLigne) + 1, PRegle.Libelle, MinPolice);
          if PRegle.Texte <> '' then
            begin
              if Length(PRegle.Texte) > 20 then
                PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 2) * HauteurLigne) + 1.5, PRegle.Texte, MinPolice)
              else
                PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 2) * HauteurLigne) + 1, PRegle.Texte, MinPolice);
            end;
        end;
    finally
      ListeRegle.Free;
    end;

    // Talents accordes par une mutation (ex. Fleshy Tentacle -> Tentacles), meme bloc, meme
    // mise en forme que les regles speciales d'appartenance juste au-dessus. Calcule a la
    // volee (PersonnageMutationTalent, chargepersonnage.pas) - CONTEXT.md, chantier
    // "traits de creature".
    for PMutationTalent in PersonnageMutationTalent(Personnage) do
      begin
        PTalent := ChercheTalent(PMutationTalent.CodeTalent);
        inc(NbLigne);
        if NbLigne > LimiteLigne then Continue;
        PdfEcrit(PdfPage, XGauche + 2, XGauche + 41, Y - ((NbLigne + 2) * HauteurLigne) + 1, PTalent.Libelle, MinPolice);
        if PTalent.SousTalent then
          PTalent := ChercheTalent(CodeTalentGenerique(PTalent));
        if PTalent.Resume <> '' then
          begin
            if Length(PTalent.Resume) > 20 then
              PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 2) * HauteurLigne) + 1.5, PTalent.Resume, MinPolice)
            else
              PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 2) * HauteurLigne) + 1, PTalent.Resume, MinPolice);
          end;
      end;

    // Talents accordes par une qualite d'objet porte (ex. NATIO-ARMOB_16 "Fear" -> Frightening,
    // Skull Trophies), meme bloc, meme mise en forme que les talents de mutation juste au-dessus.
    // Calcule a la volee (PersonnageArmureBonusTalent, chargepersonnage.pas) - CONTEXT.md,
    // chantier "traits de creature".
    for PArmureBonusTalent in PersonnageArmureBonusTalent(Personnage) + PersonnageArmeBonusTalent(Personnage) do
      begin
        PTalent := ChercheTalent(PArmureBonusTalent.CodeTalent);
        inc(NbLigne);
        if NbLigne > LimiteLigne then Continue;
        PdfEcrit(PdfPage, XGauche + 2, XGauche + 41, Y - ((NbLigne + 2) * HauteurLigne) + 1, PTalent.Libelle, MinPolice);
        if PTalent.SousTalent then
          PTalent := ChercheTalent(CodeTalentGenerique(PTalent));
        if PTalent.Resume <> '' then
          begin
            if Length(PTalent.Resume) > 20 then
              PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 2) * HauteurLigne) + 1.5, PTalent.Resume, MinPolice)
            else
              PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 2) * HauteurLigne) + 1, PTalent.Resume, MinPolice);
          end;
      end;

    // coupure : la ligne réservée annonce les talents omis
    if NbLigne > LimiteLigne then
      begin
        PdfEcrit(PdfPage, XGauche + 2, XGauche + 41, Y - ((LimiteLigne + 3) * HauteurLigne) + 1, '...', MinPolice);
        NbLigne := NbLignes;
      end;

    // Valeur Talents non acquis
    PdfPage.SetColor(RGB(150,150,150), False);
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    For PMetierTalent In ListMetierTalent do
      if (PMetierTalent.CodeMetier = Personnage.MetierEnCours.CodeMetier) then
        // niveau en cours seulement : les talents des niveaux suivants ne sont plus proposés d'avance
        if (PMetierTalent.NiveauMetier = Personnage.MetierEnCours.NiveauMetier) then
          if (not TalentCarriereDejaPris(PMetierTalent.CodeTalent)) and (NbLigne < (NbLignes - 2)) then
            begin
              // Talent de carriere = CHOIX "A/B" (Bretonnian Knight...) : le code brut ne
              // designe aucun talent, on affiche le libelle de chaque branche separes par " / ".
              LibelleChoix := '';
              if Pos(SeparateurMulti, PMetierTalent.CodeTalent) > 0 then
                begin
                  BranchesChoix := TStringList.Create;
                  try
                    BranchesChoix.StrictDelimiter := True;
                    BranchesChoix.Delimiter       := SeparateurMulti;
                    BranchesChoix.DelimitedText   := PMetierTalent.CodeTalent;
                    for IndBranche := 0 to BranchesChoix.Count - 1 do
                      begin
                        if LibelleChoix <> '' then
                          LibelleChoix := LibelleChoix + ' / ';
                        LibelleChoix := LibelleChoix + ChercheTalent(BranchesChoix[IndBranche]).Libelle;
                      end;
                    PTalent := ChercheTalent(BranchesChoix[0]);
                  finally
                    BranchesChoix.Free;
                  end;
                end
              else
                PTalent := chercheTalent(PMetierTalent.CodeTalent);
              if LibelleChoix = '' then
                LibelleChoix := PTalent.Libelle;
              PdfEcrit(PdfPage, XGauche +  2, XGauche + 41, Y - ((NbLigne + 3) * HauteurLigne) + 1, LibelleChoix, MinPolice);
              PdfEcrit(PdfPage, XGauche + 43, XGauche + 47, Y - ((NbLigne + 3) * HauteurLigne) + 1, InttoStr(PMetierTalent.NiveauMetier), MinPolice);
              if PTalent.SousTalent then
                PTalent := ChercheTalent(CodeTalentGenerique(PTalent));
              if PTalent.Resume <> '' then
                begin
                  if Length(PTalent.Resume) > 20 then
                    PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 3) * HauteurLigne) + 1.5, PTalent.Resume, MinPolice)
                  else
                    PdfEcrit(PdfPage, XGauche + 54, XDroite, Y - ((NbLigne + 3) * HauteurLigne) + 1, PTalent.Resume, MinPolice);
                  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
                end;
              NbLigne := NbLigne + 1;
            end;
    PdfPage.SetColor(clBlack, False);

    Result := Y - (NbLignes * HauteurLigne);
  end;

Function PdfBlocArmures(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer): Single;
  var
    IndC: Integer;
  begin
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleEntete(PdfPage, XGauche, XDroite, Y - HauteurLigne, HauteurLigne);
        PdfStyleZebra(PdfPage, XGauche, XDroite, Y, HauteurLigne, 3, NbLignes);
      end;
    // Dessin cadre
    PdfPage.DrawLine( XGauche,      Y,                     XGauche,      Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +  0, Y - (1 * HauteurLigne), XGauche +  0, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 34, Y - (1 * HauteurLigne), XGauche + 34, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 53, Y - (1 * HauteurLigne), XGauche + 53, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 62, Y - (1 * HauteurLigne), XGauche + 62, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 70, Y - (1 * HauteurLigne), XGauche + 70, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XDroite,      Y,                     XDroite,      Y - ((NbLignes + 1) * HauteurLigne), 1);
    for IndC := 0 to (NbLignes + 1) do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Texte Armure
    PdfTitreCentre(PdfPage, XGauche +  0, XDroite,      Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_ARMOUR1_ARMOUR'));
    PdfCentre(PdfPage, XGauche +  0, XGauche + 34, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_ARMOUR2_NAME'));
    PdfCentre(PdfPage, XGauche + 34, XGauche + 53, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_ARMOUR2_LOCATIONS'));
    PdfCentre(PdfPage, XGauche + 53, XGauche + 62, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_ARMOUR2_ENCUMBRANCE'));
    PdfCentre(PdfPage, XGauche + 62, XGauche + 70, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_ARMOUR2_ARMOURPOINT'));
    PdfCentre(PdfPage, XGauche + 70, XDroite,      Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_ARMOUR2_QUALITIES'));

    Result := Y - ((NbLignes + 1) * HauteurLigne);
  end;

Function PdfBlocEquipement(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer): Single;
  var
    IndC: Integer;
  begin
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleEntete(PdfPage, XGauche, XDroite, Y - HauteurLigne, HauteurLigne);
        PdfStyleZebra(PdfPage, XGauche, XDroite, Y, HauteurLigne, 3, NbLignes);
      end;
    // Dessin cadre
    PdfPage.DrawLine( XGauche,       Y,                     XGauche,       Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +   0, Y - (1 * HauteurLigne), XGauche +   0, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +  48, Y - (1 * HauteurLigne), XGauche +  48, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +  55, Y - (1 * HauteurLigne), XGauche +  55, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 100, Y - (1 * HauteurLigne), XGauche + 100, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XDroite,       Y,                     XDroite,       Y - ((NbLignes + 1) * HauteurLigne), 1);
    for IndC := 0 to (NbLignes + 1) do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Texte Equipement
    PdfTitreCentre(PdfPage, XGauche +   0, XDroite,       Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TRAPPING1_TRAPPINGS'));
    PdfCentre(PdfPage, XGauche +   0, XGauche +  48, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TRAPPING2_NAME'));
    PdfCentre(PdfPage, XGauche +  48, XGauche +  55, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TRAPPING2_ENCUMBRANCE'));
    PdfCentre(PdfPage, XGauche +  55, XGauche + 100, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TRAPPING2_NAME'));
    PdfCentre(PdfPage, XGauche + 100, XDroite,       Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_TRAPPING2_ENCUMBRANCE'));

    Result := Y - ((NbLignes + 1) * HauteurLigne);
  end;

Function PdfBlocArmes(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer): Single;
  var
    IndC: Integer;
  begin
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleEntete(PdfPage, XGauche, XDroite, Y - HauteurLigne, HauteurLigne);
        PdfStyleZebra(PdfPage, XGauche, XDroite, Y, HauteurLigne, 3, NbLignes);
      end;
    // Dessin cadre
    PdfPage.DrawLine( XGauche,       Y,                     XGauche,       Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +   0, Y - (1 * HauteurLigne), XGauche +   0, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +  45, Y - (1 * HauteurLigne), XGauche +  45, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +  64, Y - (1 * HauteurLigne), XGauche +  64, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +  71, Y - (1 * HauteurLigne), XGauche +  71, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +  96, Y - (1 * HauteurLigne), XGauche +  96, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 113, Y - (1 * HauteurLigne), XGauche + 113, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XDroite,       Y,                     XDroite,       Y - ((NbLignes + 1) * HauteurLigne), 1);
    for IndC := 0 to (NbLignes + 1) do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Texte Armes
    PdfTitreCentre(PdfPage, XGauche +   0, XDroite,       Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WEAPONS1_WEAPONS'));
    PdfCentre(PdfPage, XGauche +   0, XGauche +  45, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WEAPONS2_NAME'));
    PdfCentre(PdfPage, XGauche +  45, XGauche +  64, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WEAPONS2_GROUP'));
    PdfCentre(PdfPage, XGauche +  64, XGauche +  71, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WEAPONS2_ENCUMBRANCE'));
    PdfCentre(PdfPage, XGauche +  71, XGauche +  96, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WEAPONS2_RANGE'));
    PdfCentre(PdfPage, XGauche +  96, XGauche + 113, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WEAPONS2_DAMAGE'));
    PdfCentre(PdfPage, XGauche + 113, XDroite,       Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WEAPONS2_QUALITIES'));

    Result := Y - ((NbLignes + 1) * HauteurLigne);
  end;

Function PdfBlocSorts(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer): Single;
  var
    IndC: Integer;
  begin
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleEntete(PdfPage, XGauche, XDroite, Y - HauteurLigne, HauteurLigne);
        PdfStyleZebra(PdfPage, XGauche, XDroite, Y, HauteurLigne, 3, NbLignes);
      end;
    // Dessin cadre
    PdfPage.DrawLine( XGauche,      Y,                     XGauche,      Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche +  0, Y - (1 * HauteurLigne), XGauche +  0, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 38, Y - (1 * HauteurLigne), XGauche + 38, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 51, Y - (1 * HauteurLigne), XGauche + 51, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 66, Y - (1 * HauteurLigne), XGauche + 66, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 82, Y - (1 * HauteurLigne), XGauche + 82, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 98, Y - (1 * HauteurLigne), XGauche + 98, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XDroite,      Y,                     XDroite,      Y - ((NbLignes + 1) * HauteurLigne), 1);
    for IndC := 0 to (NbLignes + 1) do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Texte Sorts
    PdfTitreCentre(PdfPage, XGauche +  0, XDroite,      Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SPELL1_SPELL'));
    PdfCentre(PdfPage, XGauche +  0, XGauche + 38, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SPELL2_NAME'));
    PdfCentre(PdfPage, XGauche + 38, XGauche + 51, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SPELL2_CN'));
    PdfCentre(PdfPage, XGauche + 51, XGauche + 66, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SPELL2_RANGE'));
    PdfCentre(PdfPage, XGauche + 66, XGauche + 82, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SPELL2_TARGET'));
    PdfCentre(PdfPage, XGauche + 82, XGauche + 98, Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SPELL2_DURATION'));
    PdfCentre(PdfPage, XGauche + 98, XDroite,      Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SPELL2_EFFECT'));

    Result := Y - ((NbLignes + 1) * HauteurLigne);
  end;

Function PdfBlocEncombrement(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer): Single;
  var
    IndC: Integer;
  begin
    if PdfStyle then
      PdfStyleBloc(PdfPage, XGauche, XDroite, Y, HauteurLigne, NbLignes + 1);
    // Dessin cadre
    PdfPage.DrawLine( XGauche,      Y,                     XGauche,      Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 15, Y - (1 * HauteurLigne), XGauche + 15, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine( XDroite,      Y,                     XDroite,      Y - ((NbLignes + 1) * HauteurLigne), 1);
    for IndC := 0 to (NbLignes + 1) do
      PdfPage.DrawLine(XGauche, Y - (IndC * HauteurLigne), XDroite, Y - (IndC * HauteurLigne), 1);

    // Texte Encombrement
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche + 1, XDroite,      Y - ((NbLignes - 4) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_ENCUMBRANCE1_ENCUMBRANCE'));
    PdfEcrit(PdfPage,  XGauche + 1, XGauche + 15, Y - ((NbLignes - 3) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_ENCUMBRANCE2_ARMOUR')    , MinPolice);
    PdfEcrit(PdfPage,  XGauche + 1, XGauche + 15, Y - ((NbLignes - 2) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_ENCUMBRANCE3_WEAPONS')   , MinPolice);
    PdfEcrit(PdfPage,  XGauche + 1, XGauche + 15, Y - ((NbLignes - 1) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_ENCUMBRANCE4_TRAPPINGS') , MinPolice);
    PdfEcrit(PdfPage,  XGauche + 1, XGauche + 15, Y - ((NbLignes - 0) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_ENCUMBRANCE5_MAXENC')    , MinPolice);
    PdfEcrit(PdfPage,  XGauche + 1, XGauche + 15, Y - ((NbLignes + 1) * HauteurLigne) + 0.6, GetTexteLibelle('RULES-PDF_ENCUMBRANCE6_TOTAL')     , MinPolice);

    Result := Y - ((NbLignes + 1) * HauteurLigne);
  end;

Procedure PdfBlocSortsDonnees(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, Y, HauteurLigne: Single; MinPolice: Integer);
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    PSort:                StructureSort;
    NbSort:               Integer;
  begin
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    NbSort := 0;
    for PersonnageEquipement in Personnage.Equipement do
      if PersonnageEquipement.TypeEquipement = TypeEquipSp then
        begin
          Inc(NbSort);
          PSort := ChercheSort(PersonnageEquipement.CodeEquipement);
          PdfEcrit (PdfPage, XGauche +  1, XGauche + 38, Y - ((NbSort + 2) * HauteurLigne) + 0.6, PSort.Libelle, MinPolice);
          PdfCentre(PdfPage, XGauche + 38, XGauche + 51, Y - ((NbSort + 2) * HauteurLigne) + 0.6, LibelleValeurLivre(PSort.Niveau));
          PdfCentre(PdfPage, XGauche + 51, XGauche + 66, Y - ((NbSort + 2) * HauteurLigne) + 0.6, PdfPersonnageRemplaceBonus(Personnage, PSort.Portee));
          PdfCentre(PdfPage, XGauche + 66, XGauche + 82, Y - ((NbSort + 2) * HauteurLigne) + 0.6, PdfPersonnageRemplaceBonus(Personnage, PSort.Cible));
          PdfCentre(PdfPage, XGauche + 82, XGauche + 98, Y - ((NbSort + 2) * HauteurLigne) + 0.6, PdfPersonnageRemplaceBonus(Personnage, PSort.Duree));
        end;
  end;

Function PdfDiversLibelle(PersonnageEquipement: StructurePersonnageEquipement): String;
  var
    PTrapping: StructureTrapping;
    Morceaux:  TStringList;
    Ind:       Integer;
    Code:      String;
    Qualites:  String;
  begin
    PTrapping := ChercheTrapping(PersonnageEquipement.CodeEquipement);
    if PersonnageEquipement.NomLibre <> '' then
      Result := PersonnageEquipement.NomLibre
    else if PTrapping.CodeTrapping <> '' then
      Result := PTrapping.Libelle
    else
      Result := PersonnageEquipement.CodeEquipement;
    // Qualite (fabrication) entre parentheses ; le marqueur "qualite a ajouter" reste (Q), la colonne est etroite
    if (PersonnageEquipement.QualiteEquipement <> '') and not InList(PersonnageEquipement.QualiteEquipement, ',0') then
      begin
        Qualites := '';
        Morceaux := TStringList.Create;
        try
          ExtractStrings([','], [], PChar(PersonnageEquipement.QualiteEquipement), Morceaux);
          for Ind := 0 to Morceaux.Count - 1 do
            begin
              Code := ExtractStringBefore(Trim(Morceaux[Ind]), ' ');
              if Qualites <> '' then
                Qualites := Qualites + ',';
              if Code = CodeQualiteAAjouter then
                Qualites := Qualites + EquipementQualite
              else
                Qualites := Qualites + ChercheFabrication(Code).Libelle;
            end;
        finally
          Morceaux.Free;
        end;
        if Qualites <> '' then
          Result := Result + ' (' + Qualites + ')';
      end;
    if PersonnageEquipement.Quantite > 1 then
      Result := Result + ' x' + IntToStr(PersonnageEquipement.Quantite);
  end;

Function PdfDiversEncombrement(PersonnageEquipement: StructurePersonnageEquipement): Integer;
  var
    PTrapping: StructureTrapping;
    Qte:       Integer;
  begin
    // Regle "Worn Items" (Rulebook p.292), comme armes/armures : un objet PORTE voit son
    // Encombrement reduit de 1 (plancher 0, ou 1 s'il est Bulky), par exemplaire. Tout
    // objet du catalogue peut etre marque porte (Nono, 19/09/2026).
    Qte := PersonnageEquipement.Quantite;
    if Qte < 1 then
      Qte := 1;
    PTrapping := ChercheTrapping(PersonnageEquipement.CodeEquipement);
    if PersonnageEquipement.NomLibre <> '' then
      begin
        // Objet de texte pur : meme regle "porte" que les autres Divers, encombrement propre a la ligne.
        Result := PersonnageEquipement.EncLibre;
        if PersonnageEquipement.Porte and (Result > 0) then
          Dec(Result);
        Result := Result * Max(Qte, 1);
      end
    else if PTrapping.CodeTrapping = '' then
      Result := 0
    else
      begin
        Result := PTrapping.Encombrement;
        if PersonnageEquipement.Porte and (Result > 0) then
          begin
            Result := Result - 1;
            if (Result < 1) and FabricationEstBulky(PersonnageEquipement.QualiteEquipement) then
              Result := 1;
          end;
        Result := Result * Qte;
      end;
  end;

Function PdfDiversEncombrementBrut(PersonnageEquipement: StructurePersonnageEquipement): Integer;
  var
    PTrapping: StructureTrapping;
  begin
    PTrapping := ChercheTrapping(PersonnageEquipement.CodeEquipement);
    if PersonnageEquipement.NomLibre <> '' then
      Result := PersonnageEquipement.EncLibre * Max(PersonnageEquipement.Quantite, 1)
    else if PTrapping.CodeTrapping = '' then
      Result := 0
    else
      Result := PTrapping.Encombrement * Max(PersonnageEquipement.Quantite, 1);
  end;

// Texte de la colonne Enc : "reduit(brut)" pour un objet porte dont l'encombrement change,
// comme les armures.
// Lien objet <-> animal (CONTEXT.md 2.84) : ' [A1]' a la suite du nom d'un objet confie a l'animal A1,
// et du nom de l'animal lui-meme, pour relier les deux a la lecture. Chaine vide sinon.
Function PdfLienAnimal(PersonnageEquipement: StructurePersonnageEquipement): String;
  begin
    Result := '';
    if PersonnageEquipement.PortePar <> '' then
      Result := ' [' + PersonnageEquipement.PortePar + ']'
    else if PersonnageEquipement.IdInstance <> '' then
      Result := ' [' + PersonnageEquipement.IdInstance + ']';
  end;

Function PdfDiversTexteEnc(PersonnageEquipement: StructurePersonnageEquipement): String;
  var
    Enc, Brut: Integer;
  begin
    Enc   := PdfDiversEncombrement(PersonnageEquipement);
    Brut  := PdfDiversEncombrementBrut(PersonnageEquipement);
    // Confie a un animal : entre parentheses, meme a 0 (CONTEXT.md 2.84).
    if PersonnageEquipement.PortePar <> '' then
      Result := '(' + IntToStr(Brut) + ')'
    else if Brut = 0 then
      Result := ''
    else if Enc <> Brut then
      Result := IntToStr(Enc) + '(' + IntToStr(Brut) + ')'
    else
      Result := IntToStr(Enc);
  end;

Function PdfEquipementEncombrementBrut(PersonnageEquipement: StructurePersonnageEquipement): Integer;
  var
    Quality: String;
  begin
    Result := 0;
    if PersonnageEquipement.TypeEquipement = TypeEquipWe then
      Result := ChercheArme(PersonnageEquipement.CodeEquipement).Encombrement
                + FabricationEncombrement(PersonnageEquipement.QualiteEquipement, Quality)
    else if PersonnageEquipement.TypeEquipement = TypeEquipAr then
      Result := ChercheArmure(PersonnageEquipement.CodeEquipement).Encombrement
                + FabricationEncombrement(PersonnageEquipement.QualiteEquipement, Quality)
    else if PersonnageEquipement.TypeEquipement = TypeEquipArS then
      Result := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement).Encombrement
                + FabricationEncombrement(PersonnageEquipement.QualiteEquipement, Quality)
    else if (PersonnageEquipement.TypeEquipement = TypeEquipDI) or (PersonnageEquipement.TypeEquipement = TypeEquipAN) then
      Result := PdfDiversEncombrementBrut(PersonnageEquipement);
  end;

Function PdfAnimalCharge(Personnage: StructurePersonnage; IdAnimal: String): Integer;
  var
    PersonnageEquipement: StructurePersonnageEquipement;
  begin
    Result := 0;
    if IdAnimal = '' then
      exit;
    for PersonnageEquipement in Personnage.Equipement do
      if PersonnageEquipement.PortePar = IdAnimal then
        Result := Result + PdfEquipementEncombrementBrut(PersonnageEquipement);
  end;

Procedure PdfBlocDiversDonnees(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; out EncDivers: Integer; MinPolice: Integer; var FabricationBonii: String);
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    IndDivers, NbTotal:   Integer;
    Enc:                  Integer;
    Libelle:              String;
    Bidon:                String;
  begin
    IndDivers := 0;
    EncDivers := 0;
    NbTotal   := 0;
    for PersonnageEquipement in Personnage.Equipement do
      if (PersonnageEquipement.TypeEquipement = TypeEquipDI) or (PersonnageEquipement.TypeEquipement = TypeEquipAN) then
        Inc(NbTotal);
    for PersonnageEquipement in Personnage.Equipement do
      if (PersonnageEquipement.TypeEquipement = TypeEquipDI) or (PersonnageEquipement.TypeEquipement = TypeEquipAN) then
        begin
          Inc(IndDivers);
          Enc       := PdfDiversEncombrement(PersonnageEquipement);
          if PersonnageEquipement.PortePar = '' then
            EncDivers := EncDivers + Enc;
          Libelle   := PdfDiversLibelle(PersonnageEquipement) + PdfLienAnimal(PersonnageEquipement);
          // Animal qui porte des objets : charge / capacite <Carries> a la suite du nom.
          if (PersonnageEquipement.IdInstance <> '') and (PdfAnimalCharge(Personnage, PersonnageEquipement.IdInstance) > 0) then
            Libelle := Libelle + ' (' + GetTexteLibelle('RULES-LAB_257') + ' '
                       + IntToStr(PdfAnimalCharge(Personnage, PersonnageEquipement.IdInstance)) + '/'
                       + IntToStr(ChercheTrapping(PersonnageEquipement.CodeEquipement).Capacite * Max(PersonnageEquipement.Quantite, 1)) + ')';
          // Runes de talisman (Warding...) : leur explication va dans le bloc Crafting Bonus.
          if PersonnageEquipement.QualiteEquipement <> '' then
            begin
              Bidon := '';
              FabricationDetail(PersonnageEquipement.QualiteEquipement, Bidon, FabricationBonii);
            end;
          if (IndDivers <= (NbLignes - 1) * 2) then
            begin
              // Trop d'objets pour le cadre : la dernière ligne annonce la coupure (les Trappings
              // sont la variable d'ajustement quand tout déborde, décision Nono 20/09/2026).
              // Enc et Enc total restent comptés sur tous les objets, seul l'affichage est coupé.
              if (IndDivers = (NbLignes - 1) * 2) and (NbTotal > IndDivers) then
                Libelle := '...';
              if IndDivers > (NbLignes - 1) then
                begin
                  PdfEcrit(PdfPage, XGauche +  56, XGauche + 100, Y - ((IndDivers - NbLignes + 3) * HauteurLigne) + 0.6, Libelle, MinPolice);
                  if (PdfDiversTexteEnc(PersonnageEquipement) <> '') and (Libelle <> '...') then
                    PdfCentre(PdfPage, XGauche + 100, XDroite, Y - ((IndDivers - NbLignes + 3) * HauteurLigne) + 0.6, PdfDiversTexteEnc(PersonnageEquipement));
                end
              else
                begin
                  PdfEcrit(PdfPage, XGauche +   1, XGauche +  48, Y - ((IndDivers + 2) * HauteurLigne) + 0.6, Libelle, MinPolice);
                  if (PdfDiversTexteEnc(PersonnageEquipement) <> '') and (Libelle <> '...') then
                    PdfCentre(PdfPage, XGauche + 48, XGauche + 55, Y - ((IndDivers + 2) * HauteurLigne) + 0.6, PdfDiversTexteEnc(PersonnageEquipement));
                end;
            end;
        end;
  end;

Procedure PdfBlocArmesDonnees(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; BF, TBonusCC, TBonusCT: Integer; var FabricationBonii: String; out EncArme: Integer; out ArmeBonii: String; out ArmureBouclier: Integer; MinPolice: Integer; AsterisqueParPiece: TStringList);
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    PArme:                StructureArme;
    CompetenceDonnee:      StructureDonnee;
    Bidon:                 Integer;
    NbArme:                Integer;
    Enc:                   Integer;
    Quality:               String;
    Pourcent:              String;
    RangeX:                Single;   // debut du texte des portees, cale a droite pour laisser la place aux qualites (20/09/2026)
    PasBonus:              Boolean;
    TexteRange1:           String;
    TexteRange2:           String;
    Portee:                String;
    PorteMoyenne:          Integer;
    Deg:                   Integer;

    // Portee, accessoires de fabrication, encombrement : alimente PArme, Portee, PorteMoyenne, Enc.
    procedure PrepareArme;
      begin
        TexteRange1:= '';
        TexteRange2:= '';
        PArme      := ChercheArme(PersonnageEquipement.CodeEquipement);

        Portee     := PArme.Portee;
        if Pos('('+ConstBonusCaracF+')',Portee) > 0 then
          begin
            Portee       := StringReplace(Portee, '('+ConstBonusCaracF+')', IntToStr(Trunc(BF/10)), [rfReplaceAll]);;
            PorteMoyenne := MultiChaine(Portee);
            Portee       := IntToStr(PorteMoyenne);
          end
        else
          PorteMoyenne   := StrToIntDef(Portee,0);

        // Accessoires d arme (fabrication) : bonus de portee et qualites ajoutees.
        if (PorteMoyenne > 0) and (FabricationPortee(PersonnageEquipement.QualiteEquipement) <> 0) then
          begin
            PorteMoyenne := PorteMoyenne + FabricationPortee(PersonnageEquipement.QualiteEquipement);
            Portee       := IntToStr(PorteMoyenne);
          end;
        ArmeAjouteQualites(PArme.ListeBonus, FabricationQualitesArme(PersonnageEquipement.QualiteEquipement));
        Enc        := PArme.Encombrement + FabricationEncombrement(PersonnageEquipement.QualiteEquipement, Quality);
        // Ligne alternative d'un accessoire (Bayonet = Spear) : pas d'encombrement propre, l'accessoire pese 0.
        if EquipementAlternatifFabrication(PersonnageEquipement) <> '' then
          begin
            Enc     := 0;
            Quality := ' (' + ChercheFabrication(EquipementAlternatifFabrication(PersonnageEquipement)).Libelle + ')';
          end;
        if PersonnageEquipement.PortePar = '' then // confie a un animal : compte pour lui
          EncArme    := EncArme + Enc;
      end;

    // Pourcentage de la competence et textes de portee des armes a distance.
    procedure CalculePourcent;
      begin
                  Pourcent := '';

                  CompetenceDonnee := PdfPersonnageCompetence(Personnage, PArme.CodeCompetence, Bidon);

                  // Bonus des Ordres de Chevalerie/appartenances filtre par TYPE d'arme (ex. "+10 CC
                  // avec les lances" - Reiksguard, palier Knight) : meme ajout que PdfPersonnageCreation
                  // l.1557, manquant ici jusqu'au 08/09/2026 - PdfBlocArmesDonnees est le bloc arme
                  // utilise par PdfPersonnageCreationFeldo2P (l.4236), reste a l'ecart du calcul
                  // "normal" depuis l'ajout de ModifyWeapon le 07/09/2026 (CONTEXT.md 2.50 point 4bis).
                  // PersonnageTalentArmeModif ajoute ici aussi depuis le 11/09/2026, meme cablage
                  // dans les DEUX blocs des le depart.
                  // Rune of Accuracy (chargefabrication.pas via ModifyAccurate/ACCURATE), meme reflexe
                  // "les DEUX blocs" que ModifyWeapon ci-dessus - 27/09/2026.
                  Pourcent := IntToStr(CompetenceDonnee.Total + PdfPersonnageArmeModif(Personnage, PArme) + FabricationModificateurQualite(PersonnageEquipement.QualiteEquipement, ConstXmlModifieCompetence, ConstCibleModifieDegatCC) + FabricationModificateurQualite(PArme.ListeBonus, ConstXmlModifieAccuracy, ConstCibleModifieAccuracy) + FabricationModificateurQualite(PersonnageEquipement.QualiteEquipement, ConstXmlModifieAccuracy, ConstCibleModifieAccuracy));
        // Meme exception que PdfPersonnageCreation : arme de mutation = partie du corps.
                  PasBonus := (CompetenceDonnee.Augmentation = 0) and (PersonnageEquipement.Source = '');

                  if pos(EquipementCT, PArme.CodeArme) > 0 then
                    begin
                      TexteRange1 := '< : '+ChaineSur(3,IntToStr(Trunc(PorteMoyenne/10)))+'m '+IntToStr(StrToInt(Pourcent)+40)+'% / '+ChaineSur(3,IntToStr(Trunc(PorteMoyenne/2 )))+'m '+IntToStr(StrToInt(Pourcent)+20)+'%';
                      TexteRange2 := '> : '+ChaineSur(3,IntToStr(Trunc(PorteMoyenne*2 )))+'m '+IntToStr(StrToInt(Pourcent)-10)+'% / '+ChaineSur(3,IntToStr(Trunc(PorteMoyenne*3 )))+'m '+IntToStr(StrToInt(Pourcent)-30)+'%';
                    end;
      end;

    // Nom, pourcentage, encombrement, portee, degats.
    procedure DessineNomEtStats;
      begin
        // Asterisque des fabrications (Speed...) en petite police relevee, comme celles des armures ;
        // le nom est raccourci d'autant pour ne pas la recouvrir.
        if AsterisqueParPiece.Values['FAB:' + PersonnageEquipement.CodeEquipement] <> '' then
          begin
            PdfEcrit(PdfPage, XGauche +  1, XGauche + 41, Y - ((NbArme + 2) * HauteurLigne) + 0.6, PArme.Libelle + Quality + PdfLienAnimal(PersonnageEquipement), MinPolice);
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 4);
            PdfEcrit(PdfPage, XGauche + 41, XGauche + 45, Y - ((NbArme + 2) * HauteurLigne) + 2.3, AsterisqueParPiece.Values['FAB:' + PersonnageEquipement.CodeEquipement], 4);
            PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
          end
        else
          PdfEcrit(PdfPage, XGauche +  1, XGauche + 45, Y - ((NbArme + 2) * HauteurLigne) + 0.6, PArme.Libelle + Quality + PdfLienAnimal(PersonnageEquipement), MinPolice);


        PdfCentre(PdfPage, XGauche +  45, XGauche + 64, Y - ((NbArme + 2) * HauteurLigne) + 0.6, Pourcent + ' %');
        // Confiee a un animal : encombrement entre parentheses, meme a 0, pour montrer ou elle est.
        if PersonnageEquipement.PortePar <> '' then
          PdfCentre(PdfPage, XGauche +  64, XGauche + 71, Y - ((NbArme + 2) * HauteurLigne) + 0.6, '(' + IntToStr(Enc) + ')')
        else if PArme.Encombrement <> 0 then
          PdfCentre(PdfPage, XGauche +  64, XGauche + 71, Y - ((NbArme + 2) * HauteurLigne) + 0.6, IntToStr(Enc));
        PdfCentre(PdfPage, XGauche +  71, XGauche + 96, Y - ((NbArme + 2) * HauteurLigne) + 0.6, GetAllTexteLibelle(Portee));

        Deg   := CalculDegat(PArme.CalculDegat, BF);
        if pos(EquipementCC, PArme.CodeArme) > 0 then
          Deg := Deg + TBonusCC + FabricationModificateurQualite(PersonnageEquipement.QualiteEquipement, ConstXmlModifieDegat, ConstCibleModifieDegatCC)
        else if pos(EquipementCT, PArme.CodeArme) > 0 then
          Deg := Deg + TBonusCT + FabricationModificateurQualite(PersonnageEquipement.QualiteEquipement, ConstXmlModifieDegat, ConstCibleModifieDegatCT);

        if Deg = 0 then
          PdfCentre(PdfPage, XGauche +  96, XGauche + 113, Y - ((NbArme + 2) * HauteurLigne) + 0.6, '-')
        else
          PdfCentre(PdfPage, XGauche +  96, XGauche + 113, Y - ((NbArme + 2) * HauteurLigne) + 0.6, 'DR + '+IntToStr(Deg));
      end;

    // Portees courte et longue, cale a droite ; fixe RangeX.
    procedure DessinePortees;
      begin
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);

        RangeX := XDroite;
        if TexteRange1 <> '' then
          begin
            // Portees cales a droite : le reste de la colonne revient aux qualites. TailleTexte
            // surestime la largeur reellement dessinee d'environ 30 % (mesure sur le PDF du
            // 20/09/2026 : 34 mm estimes pour 25,6 mm reels) : 0,77 la ramene a la realite.
            // WriteText et non PdfEcrit, qui reduirait la police avec cette meme estimation.
            RangeX := XDroite - 0.5 - 0.77 * TailleTexte(TexteRange1, 6);
            if XDroite - 0.5 - 0.77 * TailleTexte(TexteRange2, 6) < RangeX then
              RangeX := XDroite - 0.5 - 0.77 * TailleTexte(TexteRange2, 6);
            PdfPage.WriteText(RangeX, Y - ((NbArme + 2) * HauteurLigne) + 2.3, TexteRange1);
            PdfPage.WriteText(RangeX, Y - ((NbArme + 2) * HauteurLigne) + 0.3, TexteRange2);
          end;
      end;

    // Qualites de l arme (competence maitrisee).
    procedure DessineQualites;
      var
        PArmeBonus: StructureArmeBonus;
        NbLoca: Integer;
        IndLoca: Integer;
        LocData: String;
        LigneBonus: String;
        ReloadBase: Integer;
        ReloadEffectif: Integer;
        LibelleReload: String;
      begin
        LigneBonus := PArme.Listebonus;
        if (PArme.ListeBonus <> '') and (PArme.ListeBonus <> '-') then
          begin
            NbLoca  := CountOccurrences(PArme.ListeBonus,',') + 1;
            for IndLoca := 1 to NbLoca do
              begin
                LocData := ExtractChaine(',',PArme.ListeBonus,IndLoca);
                if Pos(SeparateurMulti, LocData) > 0 then
                  begin
                    // qualites alternatives "A 2/B 3" : "A 2 or B 3", chaque partie garde sa valeur et son explication
                    LigneBonus := StringReplace(LigneBonus, LocData, LibelleAlternatives(LocData), [rfReplaceAll]);
                    AjouteArmeBonii(ArmeBonii, CodesAlternatives(LocData));
                  end
                else
                  begin
                    if pos(' ',LocData) <> 0 then
                      LocData := copy(LocData,1,Pos(' ',LocData)-1);
                    PArmeBonus := ChercheArmeBonus(LocData);
                    LigneBonus := StringReplace(LigneBonus, LocData, PArmeBonus.Libelle, [rfReplaceAll]);
                    AjouteArmeBonii(ArmeBonii, PArmeBonus.CodeArmeBonus);
                  end;
              end;
          end;
        FabricationDetail(PersonnageEquipement.QualiteEquipement, LigneBonus, FabricationBonii);
        // Rune of Reloading : meme correctif que PdfPersonnageCreation ci-dessus, les DEUX
        // blocs armes doivent toujours recevoir le meme calcul. 26/09/2026.
        ReloadEffectif := ArmeReloadEffectif(PArme, PersonnageEquipement.QualiteEquipement, ReloadBase);
        if (ReloadEffectif >= 0) and (ReloadEffectif <> ReloadBase) then
          begin
            LibelleReload := ChercheArmeBonus(ArmeQualiteDuModificateur(PArme.ListeBonus, ConstXmlModifieRechargement, ConstCibleModifieRechargement)).Libelle;
            if ReloadEffectif = 0 then
              LigneBonus := StringReplace(LigneBonus, LibelleReload + ' ' + IntToStr(ReloadBase), '', [])
            else
              LigneBonus := StringReplace(LigneBonus, LibelleReload + ' ' + IntToStr(ReloadBase), LibelleReload + ' ' + IntToStr(ReloadEffectif), []);
            LigneBonus := StringReplace(LigneBonus, ',,', ',', [rfReplaceAll]);
            if (LigneBonus <> '') and (LigneBonus[1] = ',') then Delete(LigneBonus, 1, 1);
            if (LigneBonus <> '') and (LigneBonus[Length(LigneBonus)] = ',') then Delete(LigneBonus, Length(LigneBonus), 1);
          end;
        if (TexteRange1 = '') then
          PdfEcrit(PdfPage, XGauche + 113 + 1, XDroite, Y - ((NbArme + 2) * HauteurLigne) + 2.3, LigneBonus, MinPolice)
        else
          PdfEcrit(PdfPage, XGauche + 113 + 1, RangeX - 1, Y - ((NbArme + 2) * HauteurLigne) + 2.3, LigneBonus, MinPolice);
      end;

    // Malus de l arme (competence non maitrisee).
    procedure DessineMalus;
      var
        PArmeBonus: StructureArmeBonus;
        PCompetence: StructureCompetence;
        NbLoca: Integer;
        IndLoca: Integer;
        LocData: String;
        ListMalii: String;
      begin
        PCompetence := ChercheCompetence(PArme.CodeCompetence);
        ListMalii := 'pas ' + PCompetence.Libelle;

        if (PArme.ListeBonus <> '') and (PArme.ListeBonus <> '-') then
          begin
            NbLoca  := CountOccurrences(PArme.ListeBonus,',') + 1;
            for IndLoca := 1 to NbLoca do
              begin
                LocData := ExtractChaine(',',PArme.ListeBonus,IndLoca);
                if pos(' ',LocData) <> 0 then
                  LocData := copy(LocData,1,Pos(' ',LocData)-1);
                PArmeBonus := ChercheArmeBonus(LocData);
                if PArmeBonus.PlusMoins = '-' then
                  begin
                    if Pos(PArmeBonus.Libelle, ArmeBonii) = 0 then
                      begin
                        if ArmeBonii <> '' then ArmeBonii := ArmeBonii + ',';
                        ArmeBonii := ArmeBonii + LocData;
                      end;
                    ListMalii  := ListMalii + ',' + PArmeBonus.Libelle;
                  end;
              end;
          end;
        FabricationDetail(PersonnageEquipement.QualiteEquipement, ListMalii, FabricationBonii);

        if (TexteRange1 = '') then
          PdfEcrit(PdfPage, XGauche + 113 + 1, XDroite, Y - ((NbArme + 2) * HauteurLigne) + 2.3, ListMalii, MinPolice)
        else
          PdfEcrit(PdfPage, XGauche + 113 + 1, RangeX - 1, Y - ((NbArme + 2) * HauteurLigne) + 2, ListMalii, MinPolice);
      end;

  begin
    EncArme        := 0;
    ArmeBonii      := '';
    ArmureBouclier := PdfPersonnageArmureModif(Personnage, BonusBouclier);
    NbArme         := 0;
    Bidon          := 0;
    // Inclut les armes accordees par une mutation, meme principe que dans
    // PdfPersonnageCreation - CONTEXT.md, chantier "traits de creature".
    for PersonnageEquipement in (Personnage.Equipement + PersonnageMutationEquipement(Personnage) + PersonnageAccessoireEquipement(Personnage)) do
      if PersonnageEquipement.TypeEquipement = TypeEquipWe then
        begin
          PrepareArme;
          Inc(NbArme);

          // Ligne grisee si l'arme n'est pas "portee" (voir PdfBlocArmuresDonnees).
          if not PersonnageEquipement.Porte then
            PdfPage.SetColor(RGB(150,150,150), False);

          CalculePourcent;

          DessineNomEtStats;

          DessinePortees;

          if PasBonus = false then
            DessineQualites
          else
            DessineMalus;

          if not PersonnageEquipement.Porte then
            PdfPage.SetColor(clBlack, False);
          PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
        end;
  end;

Procedure PdfBlocArmuresDonnees(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; ArmureSet: Boolean; var FabricationBonii: String; out EncArmure, ArmureBras, ArmureCorps, ArmureJambe, ArmureTete: Integer; out ArmureBonii: String; MinPolice: Integer; AsterisqueParEquipement: TStringList);
  var
    PersonnageEquipement: StructurePersonnageEquipement;
    PArmure:              StructureArmure;
    PArmureSimplifiee:    StructureArmureSimplifiee;
    PArmureBonus:         StructureArmureBonus;
    NbArmure:             Integer;
    Enc:                  Integer;
    EncP:                 Integer;
    Quality:              String;
    NbLoca:                Integer;
    IndLoca:               Integer;
    LocData:               String;
    LigneBonus:            String;
  begin
    EncArmure   := 0;
    ArmureBras  := 0;
    ArmureCorps := 0;
    ArmureJambe := 0;
    ArmureTete  := 0;
    ArmureBonii := '';
    NbArmure    := 0;
    for PersonnageEquipement in Personnage.Equipement do
      begin
        Enc := 0;
        EncP:= 0;
        if ((ArmureSet = false) and (PersonnageEquipement.TypeEquipement = TypeEquipAR)) or
           ((ArmureSet = true)  and (PersonnageEquipement.TypeEquipement = TypeEquipARS)) then
            // gérer les armures
            begin
              if (PersonnageEquipement.TypeEquipement = TypeEquipAR) then
                begin
                  PArmure    := ChercheArmure(PersonnageEquipement.CodeEquipement);
                  Enc        := PArmure.Encombrement + FabricationEncombrement(PersonnageEquipement.QualiteEquipement,Quality);
                  NbLoca     := CountOccurrences(PArmure.Emplacement,',') + 1;
                  LigneBonus := PArmure.Listebonus;
                end
              else
                begin
                  PArmureSimplifiee   := ChercheArmureSimplifiee(PersonnageEquipement.CodeEquipement);
                  Enc                 := PArmureSimplifiee.Encombrement + FabricationEncombrement(PersonnageEquipement.QualiteEquipement,Quality);
                  LigneBonus          := PArmureSimplifiee.Listebonus;
                end;

              // Regle "Worn Items" (Rulebook p.292) : seule une piece PORTEE voit son
              // Encombrement reduit de 1 (plancher 0) - transportee, elle compte plein pot.
              // Exception Bulky (RULES-DEFECT_04) : la piece reste a Enc 1 meme portee,
              // le plancher est 1 et non 0.
              EncP      := Enc;
              if PersonnageEquipement.Porte and (EncP > 0) then
                begin
                  EncP := EncP - 1;
                  if (EncP < 1) and FabricationEstBulky(PersonnageEquipement.QualiteEquipement) then
                    EncP := 1;
                end;
              if PersonnageEquipement.PortePar = '' then
                EncArmure := EncArmure + EncP;
              if (PersonnageEquipement.TypeEquipement = TypeEquipAR) then
                begin
                  if PersonnageEquipement.Porte then
                    For IndLoca := 1 to NbLoca do
                      begin
                        LocData := ExtractChaine(',',PArmure.Emplacement,IndLoca);
                        // 05/09/2026 - ex-"case LocData of" : egalite stricte, incompatible
                        // avec un <Location> prefixe par son livre (RULES-ARMOL_ARM).
                        // CompareRechercheValeur tolere le libelle nu en SECOND argument,
                        // donc ceci marche avec les donnees prefixees comme avec les nues.
                        if CompareRechercheValeur(LocData, BonusBras) then
                          ArmureBras  := ArmureBras  + PArmure.Protection
                        else if CompareRechercheValeur(LocData, BonusCorps) then
                          ArmureCorps := ArmureCorps + PArmure.Protection
                        else if CompareRechercheValeur(LocData, BonusJambes) then
                          ArmureJambe := ArmureJambe + PArmure.Protection
                        else if CompareRechercheValeur(LocData, BonusTete) then
                          ArmureTete  := ArmureTete  + PArmure.Protection;
                      end
                end
              else if PersonnageEquipement.Porte then
                begin
                  ArmureBras  := ArmureBras  + PArmureSimplifiee.Protection;
                  ArmureCorps := ArmureCorps + PArmureSimplifiee.Protection;
                  ArmureJambe := ArmureJambe + PArmureSimplifiee.Protection;
                  ArmureTete  := ArmureTete  + PArmureSimplifiee.Protection;
                end;

              Inc(NBArmure);

              // Ligne grisee si l'armure n'est pas "portee" - meme mecanisme que
              // PdfBlocArmes/le premier PdfBlocArmuresDonnees (signalement Nono du
              // 26/09/2026, "armure a 0 PA").
              if not PersonnageEquipement.Porte then
                PdfPage.SetColor(RGB(150,150,150), False);
              if (PersonnageEquipement.TypeEquipement = TypeEquipAR) then
                begin
                  PdfEcrit(PdfPage, XGauche +  1, XGauche + 34, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, Parmure.Libelle + Quality + PdfLienAnimal(PersonnageEquipement), MinPolice);
                  PdfEcrit(PdfPage, XGauche + 35, XGauche + 53, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, GetAllTexteLibelle(PArmure.Emplacement), MinPolice);
                end
              else
                PdfEcrit(PdfPage, XGauche +  1, XGauche + 34, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, PArmureSimplifiee.Libelle + Quality + PdfLienAnimal(PersonnageEquipement), MinPolice);
              // Afficher l'astérisque de la pièce (même principe que les talents,
              // PdfPersonnageTalentBonus/PdfBlocTalents) - permet de retrouver quelle pièce
              // cause quel malus affiché sur les Compétences (retour de Nono le 16/08/2026)
              if AsterisqueParEquipement.Values[PersonnageEquipement.CodeEquipement] <> '' then
                begin
                  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 4);
                  PdfEcrit(PdfPage, XGauche + 31, XGauche + 34, Y - ((NbArmure + 2) * HauteurLigne) + 2.3, AsterisqueParEquipement.Values[PersonnageEquipement.CodeEquipement], 4);
                  PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
                end;
              // Confiee a un animal : encombrement entre parentheses, meme a 0.
              if PersonnageEquipement.PortePar <> '' then
                PdfCentre(PdfPage, XGauche + 53, XGauche + 62, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, '(' + IntToStr(Enc) + ')')
              else if Enc <> 0 then
                if EncP <> Enc then
                  PdfCentre(PdfPage, XGauche + 53, XGauche + 62, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, IntToStr(EncP)+ '('+IntToStr(Enc)+')')
                else
                  PdfCentre(PdfPage, XGauche + 53, XGauche + 62, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, IntToStr(Enc));
              if (PersonnageEquipement.TypeEquipement = TypeEquipAR) then
                PdfCentre(PdfPage, XGauche + 62, XGauche + 70, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, IntToStr(PArmure.Protection))
              else
                PdfCentre(PdfPage, XGauche + 62, XGauche + 70, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, IntToStr(PArmureSimplifiee.Protection));
              if (PersonnageEquipement.TypeEquipement = TypeEquipAR) and (PArmure.ListeBonus <> '') and (PArmure.ListeBonus <> '-') or
                 (PersonnageEquipement.TypeEquipement = TypeEquipARS) and (PArmureSimplifiee.ListeBonus <> '') and (PArmureSimplifiee.ListeBonus <> '-') then
                begin
                  if (PersonnageEquipement.TypeEquipement = TypeEquipAR) then
                    NbLoca  := CountOccurrences(PArmure.ListeBonus,',') + 1
                  else
                    NbLoca  := CountOccurrences(PArmureSimplifiee.ListeBonus,',') + 1;
                  for IndLoca := 1 to NbLoca do
                    begin
                      if (PersonnageEquipement.TypeEquipement = TypeEquipAR) then
                        LocData := ExtractChaine(',',PArmure.ListeBonus,IndLoca)
                      else
                        LocData := ExtractChaine(',',PArmureSimplifiee.ListeBonus,IndLoca);
                      if pos(' ',LocData) <> 0 then
                        LocData := copy(LocData,1,Pos(' ',LocData)-1);
                      PArmureBonus := ChercheArmureBonus(LocData);
                      LigneBonus := StringReplace(LigneBonus, LocData, PArmureBonus.Libelle, [rfReplaceAll]);
                      if pos(LocData, ArmureBonii) = 0 then
                        begin
                          if ArmureBonii <> '' then
                           ArmureBonii := ArmureBonii + ',';
                          ArmureBonii := ArmureBonii + LocData;
                        end;
                    end;
                end;
              FabricationDetail(PersonnageEquipement.QualiteEquipement, LigneBonus, FabricationBonii);
              PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);
              // Texte trop long pour une ligne : PdfEcrit le coupe en deux, la ligne du bas passait
              // sous le cadre (runes Force + Resistance). Meme hauteur que le bloc des armes (+2.3).
              if TailleTexte(LigneBonus, PdfFontTaille) > (XDroite - (XGauche + 71)) * 1.15 then
                PdfEcrit(PdfPage, XGauche + 70 +1, XDroite, Y - ((NbArmure + 2) * HauteurLigne) + 2.3, LigneBonus, MinPolice)
              else
                PdfEcrit(PdfPage, XGauche + 70 +1, XDroite, Y - ((NbArmure + 2) * HauteurLigne) + 0.6, LigneBonus, MinPolice);
              if not PersonnageEquipement.Porte then
                PdfPage.SetColor(clBlack, False);
              PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
            end;
      end;

    // Effets de mutation sur les Points d'Armure (CORPHY_012/016/017, CONTEXT.md §2.7,
    // étape 9) - ajoutés après le calcul de l'équipement, ne concernent que le PDF.
    // L'astérisque correspondante (un seul marqueur pour tout le bloc, pas par case) est
    // calculée séparément par PdfPersonnageMutationAsterisques, pas ici.
    ArmureTete := ArmureTete + PdfPersonnageArmureModif(Personnage, BonusTete);
    ArmureBras := ArmureBras + PdfPersonnageArmureModif(Personnage, BonusBras);
    ArmureCorps := ArmureCorps + PdfPersonnageArmureModif(Personnage, BonusCorps);
    ArmureJambe := ArmureJambe + PdfPersonnageArmureModif(Personnage, BonusJambes);
    // Talents (trait Armour, marque de Quetzl), fabrications (Rune of Stone) : meme collecteur.
  end;

// Ecrit sur UNE ligne en reduisant la police pour rester dans [X, XMax] (WriteText ne reduit
// jamais : les explications d'armes longues, ex. Pummel, debordaient du cadre). 20/09/2026.
Procedure PdfEcritTient(PdfPage: TPDFPage; X, XMax, Y: Single; Texte: String);
  var
    Taille: Integer;
  begin
    Taille := PdfFontTaille;
    while (Taille > 4) and (TailleTexte(Texte, Taille) > (XMax - X) * 1.15) do
      Dec(Taille);
    if Taille <> PdfFontTaille then
      PdfPage.SetFont(PdfFontEnCours, Taille);
    PdfPage.WriteText(X, Y, Texte);
    if Taille <> PdfFontTaille then
      PdfPage.SetFont(PdfFontEnCours, PdfFontTaille);
  end;

// ---- Habillage Warhammer (option {PdfStyle}, PDF Feldo) -------------------------------------
// Palette : rouge sang-de-boeuf (bandeaux), or vieilli (filets), parchemin (zebrage et texte des
// bandeaux), encre brun-noir (traits). Couleurs en $RRGGBB (TARGBColor de fpPDF).
// Tout est du fond ou du trait : a appeler AVANT les DrawLine et le texte du bloc.
const
  PdfCouleurRouge     = $7A1C1C;
  PdfCouleurOr        = $B08D3C;
  PdfCouleurParchemin = $F3E9D0;
  PdfCouleurEntete    = $E6D5A3;
  PdfCouleurZebra     = $F6EEDA;
  PdfCouleurEncre     = $3B2A1E;
  PdfCouleurMise      = $E8C872;   // ligne mise en evidence (Courantes)

// Couleur reellement employee : inchangee en couleurs, sa luminance en niveaux de gris.
Function PdfTeinte(Couleur: TARGBColor): TARGBColor;
  var
    R, V, B, Gris: Cardinal;
  begin
    if PdfCouleur then
      Exit(Couleur);
    R    := (Couleur shr 16) and $FF;
    V    := (Couleur shr 8) and $FF;
    B    := Couleur and $FF;
    Gris := (R * 299 + V * 587 + B * 114) div 1000;
    Result := (Gris shl 16) or (Gris shl 8) or Gris;
  end;

Procedure PdfStyleFond(PdfPage: TPDFPage; X1, X2, YHaut, YBas: Single; Couleur: TARGBColor);
  var
    Coord: TPDFCoord;
  begin
    if PdfEconomie then
      Exit;
    Coord.X := X1;
    Coord.Y := YBas;
    PdfPage.SetColor(PdfTeinte(Couleur), False);
    PdfPage.DrawRect(Coord, X2 - X1, YHaut - YBas, 0, True, False, 0);
    PdfPage.SetColor(clBlack, False);
  end;

// Losange plein or de demi-diagonale R centre en (XC, YC) : carre tourne de 45 degres autour de
// son coin bas-gauche, d'ou le decalage de Y.
Procedure PdfStyleLosange(PdfPage: TPDFPage; XC, YC, R: Single);
  begin
    PdfPage.SetColor(PdfTeinte(PdfCouleurOr), False);
    PdfPage.DrawRect(XC, YC - R, R * 1.4142, R * 1.4142, 0, True, False, 45);
    PdfPage.SetColor(clBlack, False);
  end;

// Trait de contour brun-noir pour toute la suite de la page (les DrawLine suivants).
Procedure PdfStyleEncre(PdfPage: TPDFPage);
  begin
    PdfPage.SetColor(PdfTeinte(PdfCouleurEncre), True);
  end;

// Bandeau de titre : fond rouge et filets or. Le texte du bandeau passe par PdfTitreCentre.
Procedure PdfStyleTitre(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single);
  begin
    PdfStyleFond(PdfPage, X1, X2, YHaut, YHaut - Haut, PdfCouleurRouge);
    PdfPage.SetColor(PdfTeinte(PdfCouleurOr), True);
    PdfPage.DrawLine(X1, YHaut - Haut, X2, YHaut - Haut, 0.6);
    PdfPage.DrawLine(X1, YHaut,        X2, YHaut,        0.6);
    PdfPage.SetColor(PdfTeinte(PdfCouleurEncre), True);
    // Losanges or aux deux extremites du bandeau (ornement d'angle)
    // seulement sur les bandeaux larges : sur un bandeau court le losange touche le titre
    if PdfOrnements and ((X2 - X1) > 70) then
      begin
        PdfStyleLosange(PdfPage, X1 + 2.4, YHaut - (Haut / 2), 1.1);
        PdfStyleLosange(PdfPage, X2 - 2.4, YHaut - (Haut / 2), 1.1);
      end;
  end;

// Equerres or aux quatre coins de la page, avec un losange dans l'angle.
Procedure PdfStyleCadrePage(PdfPage: TPDFPage);
  const
    Marge = 5;
    Bras  = 10;
    HautP = 297;
    LargP = 210;
  begin
    PdfPage.SetColor(PdfTeinte(PdfCouleurOr), True);
    PdfPage.DrawLine(Marge,         Marge,         Marge + Bras,         Marge,         0.8);
    PdfPage.DrawLine(Marge,         Marge,         Marge,                Marge + Bras,  0.8);
    PdfPage.DrawLine(LargP - Marge, Marge,         LargP - Marge - Bras, Marge,         0.8);
    PdfPage.DrawLine(LargP - Marge, Marge,         LargP - Marge,        Marge + Bras,  0.8);
    PdfPage.DrawLine(Marge,         HautP - Marge, Marge + Bras,         HautP - Marge, 0.8);
    PdfPage.DrawLine(Marge,         HautP - Marge, Marge,                HautP - Marge - Bras, 0.8);
    PdfPage.DrawLine(LargP - Marge, HautP - Marge, LargP - Marge - Bras, HautP - Marge, 0.8);
    PdfPage.DrawLine(LargP - Marge, HautP - Marge, LargP - Marge,        HautP - Marge - Bras, 0.8);
    PdfStyleLosange(PdfPage, Marge,         Marge,         1.3);
    PdfStyleLosange(PdfPage, LargP - Marge, Marge,         1.3);
    PdfStyleLosange(PdfPage, Marge,         HautP - Marge, 1.3);
    PdfStyleLosange(PdfPage, LargP - Marge, HautP - Marge, 1.3);
    PdfPage.SetColor(PdfTeinte(PdfCouleurEncre), True);
  end;

// Pied de page : texte centre en Garamond italique 7, entre les equerres du bas.
// Remet ensuite la police des libelles (la page 2 l'a fixee avant l'appel du cadre).
Procedure PdfStylePied(PdfPage: TPDFPage; Texte: String);
  begin
    PdfPage.SetColor(PdfTeinte(PdfCouleurEncre), False);
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
    PdfCentre(PdfPage, 20, 190, 6.5, Texte);
    PdfPage.SetColor(clBlack, False);
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
  end;

// Ligne d'en-tetes de colonnes : fond parchemin fonce.
Procedure PdfStyleEntete(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single);
  begin
    PdfStyleFond(PdfPage, X1, X2, YHaut, YHaut - Haut, PdfCouleurEntete);
  end;

// Zebrage : une ligne sur deux, de PremiereLigne a DerniereLigne (rangs comptes depuis YHaut).
Procedure PdfStyleZebra(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single; PremiereLigne, DerniereLigne: Integer);
  var
    Ind: Integer;
  begin
    Ind := PremiereLigne;
    while Ind <= DerniereLigne do
      begin
        PdfStyleFond(PdfPage, X1, X2, YHaut - (Ind * Haut), YHaut - ((Ind + 1) * Haut), PdfCouleurZebra);
        Ind := Ind + 2;
      end;
  end;

// Petit bloc libelle/valeur : bandeau sur la rangee 0, zebrage a partir de la rangee 2.
// NbRangs = nombre de rangees du cadre (titre compris).
Procedure PdfStyleBloc(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single; NbRangs: Integer);
  begin
    PdfStyleTitre(PdfPage, X1, X2, YHaut, Haut);
    PdfStyleZebra(PdfPage, X1, X2, YHaut, Haut, 2, NbRangs - 1);
  end;

// Cellule de libelle en rouge (Nom, Carriere, Statut de l'en-tete), sans filets or.
Procedure PdfStyleEtiquette(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single);
  begin
    PdfStyleFond(PdfPage, X1, X2, YHaut, YHaut - Haut, PdfCouleurRouge);
  end;

// Cellule de valeur mise en evidence (Nom, Carriere, Statut) : fond or soutenu.
Procedure PdfStyleValeur(PdfPage: TPDFPage; X1, X2, YHaut, Haut: Single);
  begin
    PdfStyleFond(PdfPage, X1, X2, YHaut, YHaut - Haut, PdfCouleurMise);
  end;

// Valeur centree : en police des donnees (Garamond) quand l'habillage est actif, puis retour a la
// police des libelles (Caslon gras 10) que les blocs a valeurs en Caslon utilisent ensuite.
Procedure PdfCentreValeur(PdfPage: TPDFPage; Min, Max, Y: Single; Texte: String);
  begin
    if PdfStyle then
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    PdfCentre(PdfPage, Min, Max, Y, Texte);
    if PdfStyle then
      PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
  end;

// Libelle ecrit a gauche (WriteText) en parchemin, pour un fond rouge pose par l'appelant.
Procedure PdfEcritTitre(PdfPage: TPDFPage; X, Y: Single; Texte: String);
  begin
    if PdfStyle and not PdfEconomie then
      PdfPage.SetColor(PdfTeinte(PdfCouleurParchemin), False);
    PdfPage.WriteText(X, Y, Texte);
    if PdfStyle and not PdfEconomie then
      PdfPage.SetColor(clBlack, False);
  end;

// Police des valeurs : Arial gras 10 quand l'habillage est actif et Actif, Arial italique 9 sinon.
Procedure PdfValeurGras(PdfPage: TPDFPage; Actif: Boolean);
  begin
    if PdfStyle and Actif then
      PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceArial+ConstPoliceGras, 10)
    else
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
  end;

// Comme PdfCentre, en parchemin sur le bandeau quand l'habillage est actif.
Procedure PdfTitreCentre(PdfPage: TPDFPage; Min, Max, Y: Single; Texte: String);
  begin
    if PdfStyle and not PdfEconomie then
      PdfPage.SetColor(PdfTeinte(PdfCouleurParchemin), False);
    PdfCentre(PdfPage, Min, Max, Y, Texte);
    if PdfStyle and not PdfEconomie then
      PdfPage.SetColor(clBlack, False);
  end;

Procedure PdfBlocDessinExplication(PdfPage: TPDFPage; XGauche, XDroite, YHaut, YBas, HauteurLigne: Single; ArmureBonii, ArmeBonii, FabricationBonii: String);
  var
    NbBonus:      Integer;
    NbLoca:       Integer;
    IndLoca:      Integer;
    LocData:      String;
    PArmureBonus: StructureArmureBonus;
    PArmeBonus:   StructureArmeBonus;
    PFabrication: StructureFabrication;
    PArmureBonusModif: StructureModificateur;
    TxtBonus:     String;
  begin
    // Dessin cadre
    PdfPage.DrawLine(XGauche + 3, YHaut,    XGauche + 3, YBas + 3, 1);
    PdfPage.DrawLine(XDroite    , YHaut,    XDroite    , YBas + 3, 1);
    PdfPage.DrawLine(XGauche + 3, YHaut,    XDroite    , YHaut, 1);
    PdfPage.DrawLine(XGauche + 3, YBas + 3, XDroite    , YBas + 3, 1);

    // Entete du cadre : meme hauteur que les autres bandeaux (4.4) ; le texte commence une ligne
    // plus bas (NbBonus part de 1). Police des donnees (Arial 6) retablie ensuite.
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche + 3, XDroite, YHaut, 4.4);
        // cadre de 69 mm : sous le seuil des 70 mm de PdfStyleTitre, titre court donc ornements poses ici
        PdfStyleLosange(PdfPage, XGauche + 3 + 2.4, YHaut - 2.2, 1.1);
        PdfStyleLosange(PdfPage, XDroite - 2.4,     YHaut - 2.2, 1.1);
        PdfPage.SetColor(PdfTeinte(PdfCouleurEncre), True);
      end;
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage, XGauche + 3, XDroite, YHaut - 4.4 + 1, GetTexteLibelle('RULES-LAB_697'));
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);

    NbBonus := 1;
    if ArmureBonii <> '' then
      begin
        Inc(NbBonus);
        Inc(NbBonus);
        PdfPage.WriteText(XGauche + 4,YHaut-(NbBonus*HauteurLigne), ' --------- ' + GetTexteLibelle('RULES-LAB_122') + ' --------- ');
        Inc(NbBonus);
        NbLoca := CountOccurrences(ArmureBonii,',')+1;
        For IndLoca := 1 to NbLoca do
          begin
            Inc(NbBonus);
            LocData      := ExtractChaine(',',ArmureBonii,IndLoca);
            PArmureBonus := ChercheArmureBonus(LocData);
            TxtBonus     := PArmureBonus.Libelle+':'+PArmureBonus.Malus;
            if PArmureBonus.Malus = '' then
              // Modifier structuré (attribut name="CodeCompetence", 15/08/2026) : plus de
              // texte libre dans .Malus pour ces entrées, on reconstruit un texte lisible
              // à partir de ListArmureBonusModif (même principe que WinArmor)
              for PArmureBonusModif in ListModificateur do
                if EntreeCompetenceEquip(PArmureBonusModif) and CompareRechercheValeur(PArmureBonusModif.CodeSource, PArmureBonus.CodeArmureBonus) then
                  begin
                    if TxtBonus <> PArmureBonus.Libelle+':' then
                      TxtBonus := TxtBonus + ', ';
                    TxtBonus := TxtBonus + ChercheCompetence(PArmureBonusModif.Cible).Libelle
                                          + ' ' + IntToStr(PArmureBonusModif.Facteur) + '%';
                  end;
            // Effets conditionnels (if=) : information a la suite du resume, jamais dans les totaux.
            if ModificateursConditionnelsTexte(SourceModifArmureBonus, PArmureBonus.CodeArmureBonus) <> '' then
              TxtBonus := TxtBonus + ' ; ' + ModificateursConditionnelsTexte(SourceModifArmureBonus, PArmureBonus.CodeArmureBonus);
            PdfEcritTient(PdfPage, XGauche + 4, XDroite - 1, YHaut-(NbBonus*HauteurLigne), TxtBonus);
          end;
      end;

    if ArmeBonii <> '' then
      begin
        Inc(NbBonus);
        Inc(NbBonus);
        PdfPage.WriteText(XGauche + 4,YHaut-(NbBonus*HauteurLigne), ' ---------- ' + GetTexteLibelle('RULES-LAB_123') + ' ---------- ');
        Inc(NbBonus);
        NbLoca := CountOccurrences(ArmeBonii,',')+1;
        For IndLoca := 1 to NbLoca do
          begin
            Inc(NbBonus);
            LocData     := ExtractChaine(',',ArmeBonii,IndLoca);
            PArmeBonus  := ChercheArmeBonus(LocData);
            TxtBonus    := PArmeBonus.Libelle+':'+PArmeBonus.Resume;
            // Effets conditionnels (if=) : information a la suite du resume, jamais dans les totaux.
            if ModificateursConditionnelsTexte(SourceModifQualiteArme, PArmeBonus.CodeArmeBonus) <> '' then
              TxtBonus := TxtBonus + ' ; ' + ModificateursConditionnelsTexte(SourceModifQualiteArme, PArmeBonus.CodeArmeBonus);
            PdfEcritTient(PdfPage, XGauche + 4, XDroite - 1, YHaut-(NbBonus*HauteurLigne), TxtBonus);
          end;
      end;

    if FabricationBonii <> '' then
      begin
        Inc(NbBonus);
        Inc(NbBonus);
        PdfPage.WriteText(XGauche + 4,YHaut-(NbBonus*HauteurLigne), ' ---------- ' + GetTexteLibelle('RULES-LAB_124') + ' ---------- ');
        Inc(NbBonus);
        NbLoca := CountOccurrences(FabricationBonii,',')+1;
        For IndLoca := 1 to NbLoca do
          begin
            Inc(NbBonus);
            LocData     := ExtractChaine(',',FabricationBonii,IndLoca);
            PFabrication:= ChercheFabrication(LocData);
            TxtBonus    := PFabrication.Libelle+':'+PFabrication.Resume;
            // Rune a effet conditionnel (Might, Grudge) : l'effet chiffre par rune remplace le resume.
            if FabricationEffetsConditionnels(PFabrication.CodeFabrication, '') <> '' then
              TxtBonus  := FabricationEffetsConditionnels(PFabrication.CodeFabrication, '') + ' (' + GetTexteLibelle('RULES-LAB_244') + ')';
            PdfEcritTient(PdfPage, XGauche + 4, XDroite - 1, YHaut-(NbBonus*HauteurLigne), TxtBonus);
          end;
      end;
  end;

Procedure PdfBlocArmourPoints(PdfPage: TPDFPage; PdfImgShadow: Integer; X, Y: Single; ArmureTete, ArmureBras, ArmureCorps, ArmureJambe, ArmureBouclier, DegatRecu: Integer; AsterisqueArmure: String);
  var
    ImgX: Single;
    ImgY: Single;
  begin
    // (X, Y) = coin HAUT-GAUCHE du cadre (corrigé le 15/08/2026 suite au retour de
    // Nono : doit tomber exactement sous le coin bas-gauche du cadre Encombrement,
    // comme les autres blocs de la page s'alignent entre eux). L'image (55x72mm) est
    // décalée de 4mm par rapport au cadre à gauche/haut/droite, et 8mm en bas pour
    // laisser la place à l'étiquette "Shield" qui déborde sous l'image (PdfEncadre,
    // Bouclier = true, Bas = 7.5).
    ImgX := X + 4;
    ImgY := Y - 4 - 72;

    // Habillage : fond parchemin clair derriere la silhouette (fonds seulement, le texte ne change pas)
    if PdfStyle then
      PdfStyleFond(PdfPage, X, X + 63, Y, Y - 84, PdfCouleurZebra);

    // Cadre
    PdfPage.DrawLine(X     , Y - 84, X     , Y     , 1);
    PdfPage.DrawLine(X + 63, Y - 84, X + 63, Y     , 1);
    PdfPage.DrawLine(X     , Y     , X + 63, Y     , 1);
    PdfPage.DrawLine(X     , Y - 84, X + 63, Y - 84, 1);

    // Astérisque de mutation (CONTEXT.md §2.7 étape 9) : un seul marqueur numéroté pour
    // tout le bloc, coin haut-droit du cadre, même format que les autres sources
    // d'astérisques du PDF (ex. "(7)").
    if AsterisqueArmure <> '' then
      begin
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 4);
        PdfPage.WriteText(X + 55, Y - 3, AsterisqueArmure);
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
      end;

    // Image de fond (silhouette), taille fixe 55x72mm comme dans l'ancien
    // PdfPersonnageCreation. (ImgX,ImgY) = coin bas-gauche de l'image, comme
    // (135,190) dans l'ancien PDF - tous les décalages ci-dessous reproduisent à
    // l'identique les coordonnées absolues de l'ancien bloc, juste traduites par
    // rapport à ce nouveau point d'ancrage.
    PdfPage.DrawImage(ImgX, ImgY, 55, 72, PdfImgShadow);

    // Habillage : l'interieur des sept cases (six carrees + ecu) reste blanc, par-dessus le fond
    if PdfStyle then
      begin
        PdfStyleFond(PdfPage, ImgX + 8   , ImgX + 14  , ImgY + 64  , ImgY + 58  , $FFFFFF);
        PdfStyleFond(PdfPage, ImgX + 8   , ImgX + 14  , ImgY + 43  , ImgY + 37  , $FFFFFF);
        PdfStyleFond(PdfPage, ImgX + 8   , ImgX + 14  , ImgY + 21.5, ImgY + 15.5, $FFFFFF);
        PdfStyleFond(PdfPage, ImgX + 9.2 , ImgX + 12.8, ImgY + 3   , ImgY - 1   , $FFFFFF);
        PdfStyleFond(PdfPage, ImgX + 47.5, ImgX + 53.5, ImgY + 55  , ImgY + 49  , $FFFFFF);
        PdfStyleFond(PdfPage, ImgX + 47.5, ImgX + 53.5, ImgY + 33.5, ImgY + 27.5, $FFFFFF);
        PdfStyleFond(PdfPage, ImgX + 47.5, ImgX + 53.5, ImgY + 9.5 , ImgY + 3.5 , $FFFFFF);
      end;

    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfEncadre(PdfPage, ImgX + 10  , ImgY + 60  , false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_HEAD'), '', '01-09');
    PdfEncadre(PdfPage, ImgX + 10  , ImgY + 39  , false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_RIGHTARM1'), GetTexteLibelle('RULES-PDF_ARMOURPOINT_RIGHTARM2'), '25-44');
    PdfEncadre(PdfPage, ImgX + 10  , ImgY + 17.5, false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_RIGHTLEG'), '', '90-00');
    PdfEncadre(PdfPage, ImgX + 10  , ImgY       , true , GetTexteLibelle('RULES-PDF_ARMOURPOINT_SHIELD'), '', '');
    PdfEncadre(PdfPage, ImgX + 49.5, ImgY + 51  , false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_LEFTARM1'), GetTexteLibelle('RULES-PDF_ARMOURPOINT_LEFTARM2'), '10-24');
    PdfEncadre(PdfPage, ImgX + 49.5, ImgY + 29.5, false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_BODY'), '', '45-79');
    PdfEncadre(PdfPage, ImgX + 49.5, ImgY + 5.5 , false, GetTexteLibelle('RULES-PDF_ARMOURPOINT_LEFTLEG'), '', '80-89');

    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
    if ArmureBouclier > 0 then
      PdfPage.WriteText(ImgX + 10, ImgY, IntToStr(ArmureBouclier));
    if ArmureJambe > 0 then
      begin
        PdfPage.WriteText(ImgX + 10  , ImgY + 17.5, IntToStr(ArmureJambe));
        PdfPage.WriteText(ImgX + 49.5, ImgY + 5.5 , IntToStr(ArmureJambe));
      end;
    if ArmureBras > 0 then
      begin
        PdfPage.WriteText(ImgX + 10  , ImgY + 39, IntToStr(ArmureBras));
        PdfPage.WriteText(ImgX + 49.5, ImgY + 51, IntToStr(ArmureBras));
      end;
    if ArmureTete > 0 then
      PdfPage.WriteText(ImgX + 10, ImgY + 60, IntToStr(ArmureTete));
    if ArmureCorps > 0 then
      PdfPage.WriteText(ImgX + 49.5, ImgY + 29.5, IntToStr(ArmureCorps));
    // Reduction fixe des degats recus (ModifyDamageReceived, ex. Amulet of Thrice-Blessed Copper),
    // coin haut-gauche du cadre (choix de Nono, 30/09/2026).
    if DegatRecu <> 0 then
      begin
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);
        PdfPage.WriteText(X + 2, Y - 7, GetTexteLibelle('RULES-PDF_ARMOURPOINT_DAMAGE') + ' ' + IntToStr(DegatRecu));
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 9);
      end;
  end;

// Petite table des mutations obtenues (CONTEXT.md §2.7, étape 9) - même style de cadre que
// PdfBlocEncombrement (titre + lignes), une seule colonne. Seules les NbLignes mutations les
// plus récentes sont affichées (Personnage.Mutations, ajoutées dans l'ordre d'obtention) - au-
// delà, les plus anciennes sont omises plutôt que de faire déborder le cadre.
Function PdfBlocMutations(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; AsterisqueParMutation: TStringList): Single;
  var
    IndM, Debut: Integer;
    PCorruptionTable: StructureCorruptionTable;
    PersonnagePathologie: StructurePersonnagePathologie;
    Texte: String;
    EffetTexte: String;
    Textes: TStringList;
  begin
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleZebra(PdfPage, XGauche, XDroite, Y, HauteurLigne, 2, NbLignes);
      end;
    // Cadre (titre + NbLignes lignes)
    PdfPage.DrawLine(XGauche, Y,                    XGauche, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite, Y,                    XDroite, Y - ((NbLignes + 1) * HauteurLigne), 1);
    PdfPage.DrawLine(XGauche, Y,                    XDroite, Y,                                   1);
    PdfPage.DrawLine(XGauche, Y - HauteurLigne,      XDroite, Y - HauteurLigne,                    1);
    PdfPage.DrawLine(XGauche, Y - ((NbLignes + 1) * HauteurLigne), XDroite, Y - ((NbLignes + 1) * HauteurLigne), 1);

    // Titre
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    // Regroupe Mutation/Affliction/Disease sous un seul intitule au PDF (decision de Nono,
    // 27/09/2026) - contrairement a l'ecran ou elles ont chacune leur ligne (LigAttMutation/
    // LigAttPathologie), le PDF garde une colonne unique (deja la somme des trois sources,
    // voir PdfPersonnageAttribut plus haut).
    PdfTitreCentre(PdfPage, XGauche + 1, XDroite, Y - HauteurLigne + 0.6, GetTexteLibelle('RULES-LAB_299'));

    // Liste combinee Mutations + Afflictions/Maladies (Personnage.Pathologies) - le titre les
    // regroupe desormais, la liste doit faire pareil, sinon une fiche sans Mutation mais avec
    // une Affliction affiche un cadre vide (signale par Nono le 27/09/2026). Mutations d'abord
    // (astérisque d'effet chiffre si applicable), puis Afflictions/Maladies (pas d'astérisque,
    // ce mecanisme est propre aux Mutations - PdfPersonnageMutationAsterisques). Seules les
    // NbLignes entrees les plus recentes de CETTE liste combinee sont gardees, meme principe
    // que l'ancien Debut ci-dessous mais applique apres fusion.
    Textes := TStringList.Create;
    try
      for IndM := 0 to High(Personnage.Mutations) do
        begin
          PCorruptionTable := ChercheCorruptionTable(Personnage.Mutations[IndM].Code);
          Texte := PCorruptionTable.Libelle;
          if AsterisqueParMutation.Values[Personnage.Mutations[IndM].Code] <> '' then
            Texte := Texte + ' ' + AsterisqueParMutation.Values[Personnage.Mutations[IndM].Code];
          // Effet a cote du libelle (demande de Nono le 27/09/2026, etendue aux Mutations -
          // meme troncature que le bloc Affliction/Disease ci-dessous).
          EffetTexte := PersonnageMutationEffetTexte(Personnage.Mutations[IndM]);
          if EffetTexte <> '' then
            begin
              if UTF8Length(EffetTexte) > 70 then
                EffetTexte := UTF8Copy(EffetTexte, 1, 69) + '…';
              Texte := Texte + ' : ' + EffetTexte;
            end;
          Textes.Add(Texte);
        end;
      for PersonnagePathologie in Personnage.Pathologies do
        begin
          if PersonnagePathologie.TypeChapitre = ConstXmlChapitreAffliction then
            Texte := ChercheAffliction(PersonnagePathologie.Code).Libelle
          else
            Texte := ChercheDisease(PersonnagePathologie.Code).Libelle;
          // Effet a cote du libelle (demande de Nono le 27/09/2026) : le montant+attribut
          // vise si l'entree porte un modificateur chiffrable, sinon le texte libre du
          // catalogue (Effet/Symptoms) - tronque, ces textes font parfois plusieurs phrases
          // et cette colonne est etroite (PdfEcrit gere au mieux 3 lignes, pas plus).
          EffetTexte := PersonnagePathologieEffetTexte(PersonnagePathologie);
          if EffetTexte <> '' then
            begin
              if UTF8Length(EffetTexte) > 70 then
                EffetTexte := UTF8Copy(EffetTexte, 1, 69) + '…';
              Texte := Texte + ' : ' + EffetTexte;
            end;
          Textes.Add(Texte);
        end;

      // Les NbLignes entrees les plus récentes (les plus anciennes, en tête, sont
      // silencieusement omises au-delà - même principe que PdfBlocCorruptionDetail).
      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, MinPolice);
      Debut := Textes.Count - NbLignes;
      if Debut < 0 then
        Debut := 0;
      for IndM := Debut to Textes.Count - 1 do
        begin
          Texte := Textes[IndM];
          // Libellé (+ astérisque) souvent trop long pour tenir sur une ligne dans cette
          // colonne étroite : PdfEcrit le répartit alors sur 2 lignes - même heuristique de
          // longueur que PdfBlocCorruptionDetail/PdfBlocTalents pour ne pas déborder sous la
          // bordure.
          if Length(Texte) > Round((XDroite - XGauche) * 0.3) then
            PdfEcrit(PdfPage, XGauche + 1, XDroite - 1, Y - ((IndM - Debut + 2) * HauteurLigne) + 2,   Texte, MinPolice)
          else
            PdfEcrit(PdfPage, XGauche + 1, XDroite - 1, Y - ((IndM - Debut + 2) * HauteurLigne) + 0.6, Texte, MinPolice);
        end;
    finally
      Textes.Free;
    end;

    Result := Y - ((NbLignes + 1) * HauteurLigne);
  end;

// Découpe Texte en au plus MaxLignes lignes de largeur Largeur (mm) à la police courante de taille
// Taille (glouton, coupe aux espaces). Si le texte ne tient pas, la dernière ligne finit par "...".
// Le TStringList rendu est à libérer par l'appelant.
Function PdfDecoupeLignes(Texte: String; Largeur: Single; Taille, MaxLignes: Integer): TStringList;
  var
    Mots:    TStringArray;
    Courant: String;
    Essai:   String;
    Ind:     Integer;
  begin
    Result  := TStringList.Create;
    Mots    := Texte.Split([' ']);
    Courant := '';
    for Ind := 0 to High(Mots) do
      begin
        if Courant = '' then Essai := Mots[Ind] else Essai := Courant + ' ' + Mots[Ind];
        if (TailleTexte(Essai, Taille) > Largeur) and (Courant <> '') then
          begin
            Result.Add(Courant);
            Courant := Mots[Ind];
            if Result.Count = MaxLignes then
              begin
                Courant := '';
                Result[MaxLignes - 1] := Result[MaxLignes - 1] + '...';
                break;
              end;
          end
        else
          Courant := Essai;
      end;
    if (Courant <> '') and (Result.Count < MaxLignes) then
      Result.Add(Courant);
  end;

// Fiches des montures/animaux du personnage (page 2 du Feldo, à droite d'Armour Points).
// Par animal : titre (nom + identifiant), profil sur 12 colonnes, traits, charge/capacité.
// PDF "intelligent" (A FAIRE 20/09/2026) : fiche complète si tout tient dans HauteurMax, sinon
// compacte (sans les traits), sinon les dernières fiches sont omises (marque "..."). Un animal
// sans profil (Chicken, Sheep, Pig) ne prend que le titre et la charge.
Procedure PdfBlocMontures(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurMax: Single; MinPolice: Integer);
  const
    HautTitre  = 4.4;
    HautLigne  = 3.3;
    Ecart      = 2;
    ColonnesProfilPdf: array[0..11] of String =
      ('M', 'WS', 'BS', 'S', 'T', 'I', 'Ag', 'Dex', 'Int', 'WP', 'Fel', 'W');
    ColonnesBateauPdf: array[0..6] of String =
      ('Crew', 'M (Sail)', 'M (Oar)', 'Man', 'Size', 'T', 'W');
    ColonnesVehiculePdf: array[0..3] of String =
      ('Motive', 'T', 'W', 'Strike');
  var
    Animaux:  array of StructurePersonnageEquipement;
    Libelles: array of String;
    NbCol:    Integer;
    PT:       StructureTrapping;
    PEq:      StructurePersonnageEquipement;
    Largeur:  Single;
    Complet:  Boolean;
    Total:    Single;
    Haut:     Single;
    Y0, YL:   Single;
    IndA, IndC: Integer;
    Valeurs:  TStringArray;
    LignesTr: TStringList;
    Texte:    String;
    ColL:     Single;
    Tronque:  Boolean;

  // hauteur de la fiche d'un animal (traits : 4 lignes au plus)
  function HauteurFiche(P: StructureTrapping; AvecTraits: Boolean): Single;
    var
      Lignes: TStringList;
    begin
      Result := HautTitre + 1;
      if TrappingEstPorteur(P) then
        Result := Result + 2 * HautLigne;
      if AvecTraits and (P.TraitsAnimal <> '') then
        begin
          Lignes := PdfDecoupeLignes(GetTexteLibelle('RULES-LAB_251') + ' : ' + TraitsAnimalAffiches(P), Largeur - 2, 6, 4);
          Result := Result + Lignes.Count * HautLigne;
          Lignes.Free;
        end;
      if P.Capacite <> 0 then
        Result := Result + HautLigne;
    end;

  begin
    SetLength(Animaux, 0);
    for PEq in Personnage.Equipement do
      if (PEq.TypeEquipement = TypeEquipAN) or TrappingEstPorteur(ChercheTrapping(PEq.CodeEquipement)) then
        begin
          SetLength(Animaux, Length(Animaux) + 1);
          Animaux[High(Animaux)] := PEq;
        end;
    if Length(Animaux) = 0 then exit;

    Largeur := XDroite - XGauche;
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);

    // Complet si tout tient ; sinon compact (sans traits) ; puis on omet les fiches en trop.
    Complet := True;
    Total   := 0;
    for IndA := 0 to High(Animaux) do
      Total := Total + HauteurFiche(ChercheTrapping(Animaux[IndA].CodeEquipement), True) + Ecart;
    if Total - Ecart > HauteurMax then
      Complet := False;

    Y0      := Y;
    Tronque := False;
    for IndA := 0 to High(Animaux) do
      begin
        PT   := ChercheTrapping(Animaux[IndA].CodeEquipement);
        Haut := HauteurFiche(PT, Complet);
        // la fiche dépasserait le bas de la zone : les suivantes sont omises
        if (Y0 - Haut) < (Y - HauteurMax) then
          begin
            Tronque := True;
            break;
          end;
        // habillage : bandeau rouge du titre, entete du profil en parchemin fonce
        if PdfStyle then
          begin
            PdfStyleTitre(PdfPage, XGauche, XDroite, Y0, HautTitre);
            if TrappingEstPorteur(PT) then
              PdfStyleEntete(PdfPage, XGauche, XDroite, Y0 - HautTitre, HautLigne);
          end;
        // cadre
        PdfPage.DrawLine(XGauche,  Y0, XGauche,  Y0 - Haut, 1);
        PdfPage.DrawLine(XDroite,  Y0, XDroite,  Y0 - Haut, 1);
        PdfPage.DrawLine(XGauche,  Y0, XDroite,  Y0,        1);
        PdfPage.DrawLine(XGauche,  Y0 - Haut, XDroite, Y0 - Haut, 1);
        PdfPage.DrawLine(XGauche,  Y0 - HautTitre, XDroite, Y0 - HautTitre, 1);
        // titre : nom (+ identifiant d'instance)
        PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 9);
        Texte := PT.Libelle;
        if Texte = '' then Texte := Animaux[IndA].CodeEquipement;
        if Animaux[IndA].IdInstance <> '' then
          Texte := Texte + ' (' + Animaux[IndA].IdInstance + ')';
        if PdfStyle and not PdfEconomie then
          PdfPage.SetColor(PdfTeinte(PdfCouleurParchemin), False);
        PdfEcrit(PdfPage, XGauche + 1, XDroite - 1, Y0 - HautTitre + 1, Texte, MinPolice);
        if PdfStyle and not PdfEconomie then
          PdfPage.SetColor(clBlack, False);
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);
        YL := Y0 - HautTitre - HautLigne + 0.8;
        // profil : libellés puis valeurs, 12 colonnes
        // (navire : 7 colonnes, vehicule : 4, separees par ';' ; animal : 12, separees par des espaces)
        if TrappingEstPorteur(PT) then
          begin
            SetLength(Libelles, 0);
            if PT.ProfilAnimal <> '' then
              begin
                Valeurs := PT.ProfilAnimal.Split([' ']);
                NbCol   := 12;
                SetLength(Libelles, NbCol);
                for IndC := 0 to NbCol - 1 do Libelles[IndC] := ColonnesProfilPdf[IndC];
              end
            else if PT.ProfilBateau <> '' then
              begin
                Valeurs := PT.ProfilBateau.Split([';']);
                NbCol   := 7;
                SetLength(Libelles, NbCol);
                for IndC := 0 to NbCol - 1 do Libelles[IndC] := ColonnesBateauPdf[IndC];
              end
            else
              begin
                Valeurs := PT.ProfilVehicule.Split([';']);
                NbCol   := 4;
                SetLength(Libelles, NbCol);
                for IndC := 0 to NbCol - 1 do Libelles[IndC] := ColonnesVehiculePdf[IndC];
              end;
            ColL    := (Largeur - 2) / NbCol;
            for IndC := 0 to NbCol - 1 do
              begin
                PdfCentre(PdfPage, XGauche + 1 + IndC * ColL, XGauche + 1 + (IndC + 1) * ColL, YL, Libelles[IndC]);
                if IndC <= High(Valeurs) then
                  PdfCentre(PdfPage, XGauche + 1 + IndC * ColL, XGauche + 1 + (IndC + 1) * ColL, YL - HautLigne, Valeurs[IndC]);
              end;
            YL := YL - 2 * HautLigne;
          end;
        // traits (fiche complète)
        if Complet and (PT.TraitsAnimal <> '') then
          begin
            LignesTr := PdfDecoupeLignes(GetTexteLibelle('RULES-LAB_251') + ' : ' + TraitsAnimalAffiches(PT), Largeur - 2, 6, 4);
            for IndC := 0 to LignesTr.Count - 1 do
              begin
                PdfPage.WriteText(XGauche + 1, YL, LignesTr[IndC]);
                YL := YL - HautLigne;
              end;
            LignesTr.Free;
          end;
        // charge / capacité
        if PT.Capacite <> 0 then
          begin
            Texte := GetTexteLibelle('RULES-LAB_257') + ' : ';
            if Animaux[IndA].IdInstance <> '' then
              Texte := Texte + IntToStr(PdfAnimalCharge(Personnage, Animaux[IndA].IdInstance))
            else
              Texte := Texte + '0';
            Texte := Texte + ' / ' + IntToStr(PT.Capacite * Max(Animaux[IndA].Quantite, 1));
            PdfPage.WriteText(XGauche + 1, YL, Texte);
          end;
        Y0 := Y0 - Haut - Ecart;
      end;
    if Tronque then
      PdfPage.WriteText(XGauche + 1, Y0 - 2, '...');
  end;

// Cherche la valeur du champ nommé Champ dans Enr. Renvoie une case vide (Valeur = '') si le
// champ n'existe pas dans cet enregistrement, plutôt qu'une erreur : cela permet à une
// préparation de ne pas renseigner un champ non pertinent pour une entrée donnée.
Function PdfChercheValeurChamp(const Enr: TPdfEnregistrement; const Champ: String): TPdfValeurCase;
  var
    Ind: Integer;
  begin
    Result.Champ      := Champ;
    Result.Valeur     := '';
    Result.Grise      := False;
    Result.Annotation := '';
    for Ind := 0 to High(Enr.Valeurs) do
      if Enr.Valeurs[Ind].Champ = Champ then
        begin
          Result := Enr.Valeurs[Ind];
          break;
        end;
  end;

Function DessinerTableau(PdfPage: TPDFPage; const Tableau: TPdfTableau; const Donnees: TPdfRecordSet): Single;
  var
    NbEntrees, NbChamps, IndE, IndC: Integer;
    XFinTableau, XCol, YHautLigne:   Single;
    ValeurCase:                      TPdfValeurCase;
    // orColonne : découpage de l'annotation en plusieurs lignes empilées (une par source, ex.
    // Talent '|' Mutation) - CONTEXT.md §2.7.
    LignesAnnotation:                TStringList;
    IndLigne:                        Integer;
    Fendue:                          Boolean;
    PosAst:                          Integer;
    // orLigne uniquement
    XPos:           array of Single;
    NbLignesEntete: Integer;
    NbLignesTotal:  Integer;
    LigneCourante:  Integer;
    YEntete, YDonnee, XDroite: Single;
    Fusionne:       Boolean;

  // Choisit la police d'une case selon son style explicite (ValeurCase.Style) ou, à défaut,
  // celui de sa colonne (Colonne.EnTete). Partagée par les deux orientations.
  Procedure AppliquerStylePolice(const Colonne: TPdfColonne; const Valeur: TPdfValeurCase);
    var
      Style: TPdfStylePolice;
    begin
      Style := Valeur.Style;
      if (Style = spValeur) and Colonne.EnTete then
        Style := spEnTete;
      case Style of
        spEnTete: PdfTaillePolice(PdfPage, PdfFontBack,  ConstPoliceCarlson+ConstPoliceGras, 10);
        spAccent: PdfTaillePolice(PdfPage, PdfFontBold,  ConstPoliceArial+ConstPoliceGras,     8);
        else      PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, Tableau.Police);
      end;
    end;

  begin
    NbEntrees := Length(Donnees);
    NbChamps  := Length(Tableau.Champs);

    if Tableau.Orientation = orColonne then
      begin
        XFinTableau := Tableau.X + Tableau.LargeurLibelles + (NbEntrees * Tableau.LargeurEntree);

        if PdfStyle then
          begin
            // colonne de libelles teintee, premiere ligne en bandeau rouge, ligne "Current" en evidence
            PdfStyleEntete(PdfPage, Tableau.X, Tableau.X + Tableau.LargeurLibelles, Tableau.Y, NbChamps * Tableau.HauteurLigne);
            for IndC := 0 to NbChamps - 1 do
              if Tableau.Champs[IndC].Champ = 'Current' then
                PdfStyleFond(PdfPage, Tableau.X, XFinTableau, Tableau.Y - (IndC * Tableau.HauteurLigne), Tableau.Y - ((IndC + 1) * Tableau.HauteurLigne), PdfCouleurMise);
            PdfOrnements := False;
            PdfStyleTitre(PdfPage, Tableau.X, XFinTableau, Tableau.Y, Tableau.HauteurLigne);
            PdfOrnements := True;
          end;
        // Cadre
        PdfPage.DrawLine(Tableau.X, Tableau.Y, XFinTableau, Tableau.Y, 1);
        PdfPage.DrawLine(Tableau.X, Tableau.Y, Tableau.X, Tableau.Y - (NbChamps * Tableau.HauteurLigne), 1);
        for IndE := 0 to NbEntrees do
          begin
            XCol := Tableau.X + Tableau.LargeurLibelles + (IndE * Tableau.LargeurEntree);
            PdfPage.DrawLine(XCol, Tableau.Y, XCol, Tableau.Y - (NbChamps * Tableau.HauteurLigne), 1);
          end;
        for IndC := 0 to NbChamps do
          PdfPage.DrawLine(Tableau.X, Tableau.Y - (IndC * Tableau.HauteurLigne), XFinTableau, Tableau.Y - (IndC * Tableau.HauteurLigne), 1);

        // Bande de libellés (à gauche)
        PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
        for IndC := 0 to NbChamps - 1 do
          if IndC = 0 then
            PdfTitreCentre(PdfPage, Tableau.X, Tableau.X + Tableau.LargeurLibelles, Tableau.Y - ((IndC+1) * Tableau.HauteurLigne) + 1, Tableau.Champs[IndC].Libelle)
          else
            PdfCentre(PdfPage, Tableau.X, Tableau.X + Tableau.LargeurLibelles, Tableau.Y - ((IndC+1) * Tableau.HauteurLigne) + 1, Tableau.Champs[IndC].Libelle);

        // Valeurs (une colonne par entrée)
        for IndE := 0 to NbEntrees - 1 do
          for IndC := 0 to NbChamps - 1 do
            begin
              ValeurCase := PdfChercheValeurChamp(Donnees[IndE], Tableau.Champs[IndC].Champ);
              if ValeurCase.Valeur = '' then
                continue;

              AppliquerStylePolice(Tableau.Champs[IndC], ValeurCase);
              if PdfStyle and (Tableau.Champs[IndC].Champ = 'Current') then
                PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceArial+ConstPoliceGras, Tableau.Police);

              if ValeurCase.Grise then
                PdfPage.SetColor(RGB(150,150,150), False);

              XCol := Tableau.X + Tableau.LargeurLibelles + (IndE * Tableau.LargeurEntree);
              if PdfStyle and (IndC = 0) then
                PdfTitreCentre(PdfPage, XCol, XCol + Tableau.LargeurEntree, Tableau.Y - ((IndC+1) * Tableau.HauteurLigne) + 1, ValeurCase.Valeur)
              else
                PdfCentre(PdfPage, XCol, XCol + Tableau.LargeurEntree, Tableau.Y - ((IndC+1) * Tableau.HauteurLigne) + 1, ValeurCase.Valeur);

              if ValeurCase.Grise then
                PdfPage.SetColor(clBlack, False);

              if ValeurCase.Annotation <> '' then
                begin
                  YHautLigne := Tableau.Y - ((IndC+1) * Tableau.HauteurLigne) + 1;
                  LignesAnnotation := TStringList.Create;
                  ExtractStrings(['|'], [], PChar(ValeurCase.Annotation), LignesAnnotation);
                  // Même rendu que l'annotation des compétences (orLigne) : Arial 6, indépendant de la
                  // police de la valeur. Plusieurs sources empilées : 4, pour ne pas se chevaucher.
                  // Une seule source "+10 (1)" : delta et astérisque sur deux lignes à 5 pt. La case
                  // (10,3 mm) n'a que ~6 mm à droite de la valeur : sur une ligne, "+10 (1)" tombait
                  // à 4 pt et l'astérisque était rognée par la case voisine.
                  Fendue := False;
                  if (LignesAnnotation.Count = 1) and (Pos(' (', LignesAnnotation[0]) > 1) then
                    begin
                      PosAst := Pos(' (', LignesAnnotation[0]);
                      LignesAnnotation.Add(Copy(LignesAnnotation[0], PosAst + 1, Length(LignesAnnotation[0])));
                      LignesAnnotation[0] := Copy(LignesAnnotation[0], 1, PosAst - 1);
                      Fendue := True;
                    end;
                  if Fendue then
                    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceArial, 4)
                  else if LignesAnnotation.Count = 1 then
                    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceArial, 6)
                  else
                    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceArial, 4);
                  // Empilement : une ligne par source, avec le même espacement que celui déjà
                  // utilisé par PdfEcrit en interne pour ses propres cas à 2/3 lignes.
                  if Fendue then
                    begin
                      // Deux lignes tenant dans la hauteur de la case (4,6 mm) : delta en haut, astérisque en bas.
                      PdfEcrit(PdfPage, XCol + (Tableau.LargeurEntree * 0.5) + 2.0, XCol + Tableau.LargeurEntree + 2.0, YHautLigne + 1.9, LignesAnnotation[0], 4);
                      PdfEcrit(PdfPage, XCol + (Tableau.LargeurEntree * 0.5) + 2.0, XCol + Tableau.LargeurEntree + 2.0, YHautLigne - 0.1, LignesAnnotation[1], 4);
                    end
                  else
                  case LignesAnnotation.Count of
                    1: PdfEcrit(PdfPage, XCol + (Tableau.LargeurEntree * 0.5) + 2.25, XCol + Tableau.LargeurEntree + 2.25, YHautLigne + 1.5, LignesAnnotation[0], 4);
                    2: begin
                         PdfEcrit(PdfPage, XCol + (Tableau.LargeurEntree * 0.5) + 2.25, XCol + Tableau.LargeurEntree + 2.25, YHautLigne + 1.5 + 1,   LignesAnnotation[0], 4);
                         PdfEcrit(PdfPage, XCol + (Tableau.LargeurEntree * 0.5) + 2.25, XCol + Tableau.LargeurEntree + 2.25, YHautLigne + 1.5 - 1,   LignesAnnotation[1], 4);
                       end;
                    else
                       for IndLigne := 0 to LignesAnnotation.Count - 1 do
                         PdfEcrit(PdfPage, XCol + (Tableau.LargeurEntree * 0.5) + 2.25, XCol + Tableau.LargeurEntree + 2.25, YHautLigne + 1.5 + 1.4 - (IndLigne * 1.4), LignesAnnotation[IndLigne], 4);
                  end;
                  LignesAnnotation.Free;
                end;
            end;

        Result := Tableau.Y - (NbChamps * Tableau.HauteurLigne);
      end
    else // orLigne
      begin
        // Positions X cumulées : largeur propre par colonne (Champs[i].Largeur) si
        // renseignée, sinon largeur par défaut du tableau.
        SetLength(XPos, NbChamps + 1);
        XPos[0] := Tableau.X;
        for IndC := 0 to NbChamps - 1 do
          if Tableau.Champs[IndC].Largeur > 0 then
            XPos[IndC+1] := XPos[IndC] + Tableau.Champs[IndC].Largeur
          else
            XPos[IndC+1] := XPos[IndC] + Tableau.LargeurEntree;
        XFinTableau := XPos[NbChamps];

        NbLignesEntete := 1;
        if Tableau.Titre <> '' then
          NbLignesEntete := NbLignesEntete + 1;
        // Le cadre peut avoir une capacité fixe supérieure au nombre d'entrées fournies
        // (NbLignesMax) ; les lignes au-delà de NbEntrees restent alors vides (grille sans
        // texte), seul le cadre est dessiné sur toute la capacité.
        if Tableau.NbLignesMax > 0 then
          NbLignesTotal := NbLignesEntete + Tableau.NbLignesMax
        else
          NbLignesTotal := NbLignesEntete + NbEntrees;

        if PdfStyle then
          begin
            if Tableau.Titre <> '' then
              PdfStyleTitre(PdfPage, Tableau.X, XFinTableau, Tableau.Y, Tableau.HauteurLigne);
            PdfStyleEntete(PdfPage, Tableau.X, XFinTableau, Tableau.Y - ((NbLignesEntete - 1) * Tableau.HauteurLigne), Tableau.HauteurLigne);
            PdfStyleZebra(PdfPage, Tableau.X, XFinTableau, Tableau.Y, Tableau.HauteurLigne, NbLignesEntete + 1, NbLignesTotal - 1);
          end;

        // Cadre horizontal (toutes les lignes, pleine largeur)
        for IndC := 0 to NbLignesTotal do
          PdfPage.DrawLine(Tableau.X, Tableau.Y - (IndC * Tableau.HauteurLigne), XFinTableau, Tableau.Y - (IndC * Tableau.HauteurLigne), 1);

        // Cadre vertical : les bords extérieurs (0 et NbChamps) sont toujours pleine
        // hauteur ; un séparateur intérieur dont la colonne de gauche est "fusionnée avec
        // la suivante" ne descend qu'à partir de la première ligne de données (pour laisser
        // le libellé fusionné chapeauter les deux colonnes sans trait au milieu).
        for IndC := 0 to NbChamps do
          begin
            if (IndC = 0) or (IndC = NbChamps) then
              YHautLigne := Tableau.Y
            else if Tableau.Champs[IndC-1].FusionAvecSuivante then
              YHautLigne := Tableau.Y - (NbLignesEntete * Tableau.HauteurLigne)
            else if Tableau.Titre <> '' then
              YHautLigne := Tableau.Y - Tableau.HauteurLigne
            else
              YHautLigne := Tableau.Y;
            PdfPage.DrawLine(XPos[IndC], YHautLigne, XPos[IndC], Tableau.Y - (NbLignesTotal * Tableau.HauteurLigne), 1);
          end;

        LigneCourante := 0;

        // Titre (bandeau plein largeur, optionnel)
        if Tableau.Titre <> '' then
          begin
            PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
            PdfTitreCentre(PdfPage, Tableau.X + Tableau.TitreDecalageGauche, XFinTableau, Tableau.Y - Tableau.HauteurLigne + 1, Tableau.Titre);
            LigneCourante := 1;
          end;

        // En-têtes de colonnes : une colonne "fusionnée dans" la précédente (i.e. dont la
        // précédente a FusionAvecSuivante) ne dessine rien elle-même, son libellé est porté
        // par la colonne précédente et centré sur la largeur des deux réunies.
        PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
        YEntete := Tableau.Y - ((LigneCourante+1) * Tableau.HauteurLigne) + 1;
        IndC := 0;
        while IndC < NbChamps do
          begin
            Fusionne := (IndC > 0) and Tableau.Champs[IndC-1].FusionAvecSuivante;
            if not Fusionne then
              begin
                if Tableau.Champs[IndC].FusionAvecSuivante then
                  XDroite := XPos[IndC+2]
                else
                  XDroite := XPos[IndC+1];
                if Tableau.Champs[IndC].Libelle <> '' then
                  if Tableau.Champs[IndC].AlignementEntete = alGauche then
                    PdfEcrit(PdfPage, XPos[IndC]+Tableau.Champs[IndC].DecalageEnteteMin, XDroite+Tableau.Champs[IndC].DecalageEnteteMax, YEntete, Tableau.Champs[IndC].Libelle, Tableau.PoliceMin)
                  else
                    PdfCentre(PdfPage, XPos[IndC]+1, XDroite, YEntete, Tableau.Champs[IndC].Libelle);
              end;
            Inc(IndC);
          end;

        // Valeurs (une ligne par entrée)
        for IndE := 0 to NbEntrees - 1 do
          begin
            YDonnee := Tableau.Y - ((NbLignesEntete + IndE + 1) * Tableau.HauteurLigne) + 1;
            for IndC := 0 to NbChamps - 1 do
              begin
                ValeurCase := PdfChercheValeurChamp(Donnees[IndE], Tableau.Champs[IndC].Champ);
                if ValeurCase.Valeur = '' then
                  continue;

                AppliquerStylePolice(Tableau.Champs[IndC], ValeurCase);
                if PdfStyle and (Tableau.Champs[IndC].Champ = 'Total') then
                  PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceArial+ConstPoliceGras, Tableau.Police);

                if ValeurCase.Grise then
                  PdfPage.SetColor(RGB(150,150,150), False);

                PdfEcrit(PdfPage, XPos[IndC] + Tableau.Champs[IndC].DecalageValeurMin, XPos[IndC+1] + Tableau.Champs[IndC].DecalageValeurMax, YDonnee, ValeurCase.Valeur, Tableau.PoliceMin);

                if ValeurCase.Grise then
                  PdfPage.SetColor(clBlack, False);

                if ValeurCase.Annotation <> '' then
                  begin
                    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceArial, 6);
                    // Boîte élargie le 16/08/2026 (retour de Nono) : les annotations de talent
                    // seules ("><(3)") tenaient dans 8.5mm, mais les nouvelles annotations
                    // d'armure ("(5) -10%") sont plus longues et provoquaient un retour à la
                    // ligne (PdfEcrit) qui désalignait le pourcentage du numéro. Champ Nom
                    // uniquement (Valeurs[0]) sur les tableaux Compétences, ne touche pas
                    // l'annotation des Caractéristiques (orColonne, autre PdfEcrit plus haut).
                    PdfEcrit(PdfPage, XPos[IndC+1] - 8, XPos[IndC+1] + 5, YDonnee + 1, ValeurCase.Annotation, 6);
                  end;
              end;
          end;

        Result := Tableau.Y - (NbLignesTotal * Tableau.HauteurLigne);
      end;
  end;

// Prépare les données du tableau des Caractéristiques (10 entrées = les 10 caractéristiques,
// dans l'ordre StructureAttribut.OrdreAttribut ; 6 champs par entrée : Code, Initial, Improv,
// Advances, Current, Bonus). Aucun dessin ici, uniquement du calcul/lecture de données.
Function PdfPreparerRecordSetCaracteristiques(Personnage: StructurePersonnage; PMetier: StructureMetier; AnnotationMutation: TStringList): TPdfRecordSet;
  var
    PAttribut:       StructureAttribut;
    PMetierAttribut: StructureMetierAttribut;
    AttributDonnee:  StructureDonnee;
    Bonus:           String;
    Ind:             Integer;
    NiveauMetier:    Integer;
  begin
    Result := nil;
    SetLength(Result, 10);
    for Ind := 1 to 10 do
      begin
        PAttribut      := ListeAttribut[Ind-1];
        AttributDonnee := PdfPersonnageAttribut(Personnage, PAttribut.CodeAttribut, Bonus);
        // Effets à delta pur des mutations obtenues (CONTEXT.md §2.7, étape 9) - même principe
        // que l'annotation armure sur les compétences, concaténée à l'annotation existante.
        // Séparateur '|' : permet à DessinerTableau d'afficher chaque source sur sa propre
        // ligne plutôt que de laisser PdfEcrit couper le texte concaténé n'importe où.
        if AnnotationMutation.Values[PAttribut.CodeAttribut] <> '' then
          begin
            if Bonus <> '' then
              Bonus := Bonus + '|';
            Bonus := Bonus + AnnotationMutation.Values[PAttribut.CodeAttribut];
          end;

        SetLength(Result[Ind-1].Valeurs, 6);

        Result[Ind-1].Valeurs[0].Champ  := 'Code';
        Result[Ind-1].Valeurs[0].Valeur := GetTexteLibelle('RULES-SHORTATTR_'+ExtractStringAfter(PAttribut.CodeAttribut,'_'));

        Result[Ind-1].Valeurs[1].Champ      := 'Initial';
        Result[Ind-1].Valeurs[1].Valeur     := IntToStr(AttributDonnee.Base);
        Result[Ind-1].Valeurs[1].Annotation := Bonus;

        NiveauMetier := 0;
        For PMetierAttribut in ListMetierAttribut do
          if (PMetierAttribut.CodeMetier = PMetier.CodeMetier)
             and (PMetierAttribut.CodeAttribut = PAttribut.CodeAttribut)
             and (PMetierAttribut.NiveauMetier > 0) then
            begin
              NiveauMetier := PMetierAttribut.NiveauMetier;
              break;
            end;
        Result[Ind-1].Valeurs[2].Champ := 'Improv';
        if NiveauMetier > 0 then
          begin
            Result[Ind-1].Valeurs[2].Valeur := IntToStr(NiveauMetier);
            Result[Ind-1].Valeurs[2].Grise  := (NiveauMetier > Personnage.MetierEnCours.NiveauMetier);
          end;

        Result[Ind-1].Valeurs[3].Champ := 'Advances';
        if AttributDonnee.Augmentation <> 0 then
          Result[Ind-1].Valeurs[3].Valeur := IntToStr(AttributDonnee.Augmentation);

        Result[Ind-1].Valeurs[4].Champ  := 'Current';
        Result[Ind-1].Valeurs[4].Valeur := IntToStr(AttributDonnee.Total);

        Result[Ind-1].Valeurs[5].Champ  := 'Bonus';
        Result[Ind-1].Valeurs[5].Valeur := IntToStr(Trunc(AttributDonnee.Total/10));
      end;
  end;

// Prépare le tableau des compétences de base : une entrée par compétence de ListPage, 6
// champs (Nom, Attribut, Stat, Upg, Adv, Total). Nom et Attribut partagent le même style de
// police par ligne (en-tête, ou "accent" si la compétence appartient au métier en cours) —
// c'est le même calcul que faisait l'ancien code juste avant de dessiner.
Function PdfPreparerRecordSetCompetencesBase(Personnage: StructurePersonnage; PMetier: StructureMetier; ListPage: TStringList; AnnotationArmure: TStringList; out TotalEsquive, TotalCalme, TotalResitance, TotalCommandement, TotalIntuition: Integer; out ListPris: String): TPdfRecordSet;
  var
    Ind:              Integer;
    Comp:             String;
    PCompetence:      StructureCompetence;
    PAttribut:        StructureAttribut;
    CompetenceDonnee: StructureDonnee;
    NivCompMetier:    Integer;
    ValBonus:         String;
    Bonus:            String;
    StyleLigne:       TPdfStylePolice;
    AvecEquipement:   Integer;
  begin
    TotalEsquive      := 0;
    TotalCalme        := 0;
    TotalResitance    := 0;
    TotalCommandement := 0;
    TotalIntuition    := 0;
    ListPris          := '';

    Result := nil;
    SetLength(Result, ListPage.Count);
    for Ind := 0 to ListPage.Count - 1 do
      begin
        Comp             := ListPage[Ind];
        PCompetence      := ChercheCompetence(Comp);
        CompetenceDonnee := PdfPersonnageCompetence(Personnage, Comp, NivCompMetier);
        PAttribut        := ChercheAttribut(PCompetence.CodeAttribut);
        ListPris         := ListPris + Separateurtabulation + Comp;

        case Comp of
          ConstCEsquive:      TotalEsquive      := CompetenceDonnee.Total;
          ConstCCalme:        TotalCalme        := CompetenceDonnee.Total;
          ConstCResitance:    TotalResitance    := CompetenceDonnee.Total;
          ConstCCommandement: TotalCommandement := CompetenceDonnee.Total;
          ConstCIntuition:    TotalIntuition    := CompetenceDonnee.Total;
        end;

        ValBonus := IntToStr(CompetenceDonnee.Augmentation);
        if ValBonus = '0' then
          ValBonus := '';
        if (StrToIntDef(ValBonus,0) >= 0) and (StrToIntDef(ValBonus,0) < 10) then
          ValBonus := '  ' + ValBonus;

        if CompareCompetence(PCompetence.CodeCompetence, PMetier.CodeCompetence) then
          StyleLigne := spAccent
        else
          StyleLigne := spValeur; // colonnes EnTete=True => police d'en-tête par défaut

        Bonus := PdfPersonnageCompetenceBonus(Personnage, Comp);
        if AnnotationArmure.Values[Comp] <> '' then
          Bonus := Bonus + AnnotationArmure.Values[Comp];

        SetLength(Result[Ind].Valeurs, 7);

        Result[Ind].Valeurs[0].Champ      := 'Nom';
        Result[Ind].Valeurs[0].Valeur     := PdfSupprimeGenerique(PCompetence.CodeCompetence, PCompetence.Libelle);
        Result[Ind].Valeurs[0].Style      := StyleLigne;
        Result[Ind].Valeurs[0].Annotation := Bonus;

        Result[Ind].Valeurs[1].Champ  := 'Attribut';
        Result[Ind].Valeurs[1].Valeur := GetTexteLibelle(PAttribut.Resume);
        Result[Ind].Valeurs[1].Style  := StyleLigne;

        Result[Ind].Valeurs[2].Champ  := 'Stat';
        Result[Ind].Valeurs[2].Valeur := IntToStr(CompetenceDonnee.Base);

        Result[Ind].Valeurs[3].Champ := 'Upg';
        if NivCompMetier > 0 then
          begin
            Result[Ind].Valeurs[3].Valeur := IntToStr(NivCompMetier);
            Result[Ind].Valeurs[3].Grise  := (NivCompMetier > Personnage.MetierEnCours.NiveauMetier);
          end;

        Result[Ind].Valeurs[4].Champ  := 'Adv';
        Result[Ind].Valeurs[4].Valeur := ValBonus;

        Result[Ind].Valeurs[5].Champ  := 'Total';
        Result[Ind].Valeurs[5].Valeur := IntToStr(CompetenceDonnee.Total);

        // Colonne "avec equipement" (CONTEXT.md 2.59) : vide si l'equipement porte ne modifie
        // pas cette competence, Total ajuste sinon (Valeur reste '' par defaut si AvecEquipement = 0).
        Result[Ind].Valeurs[6].Champ := 'AvecEquipement';
        AvecEquipement := PersonnageArmureBonusCompetenceModifPortee(Personnage, Comp);
        if AvecEquipement <> 0 then
          Result[Ind].Valeurs[6].Valeur := IntToStr(CompetenceDonnee.Total + AvecEquipement);
      end;
  end;

Function PdfPreparerRecordSetCompetencesGroupees(Personnage: StructurePersonnage; ListPris: String; CapaciteMax: Integer; AnnotationArmure: TStringList): TPdfRecordSet;
  var
    Ind:                  Integer;
    NbLigne:              Integer;
    PCompetence:          StructureCompetence;
    PAttribut:            StructureAttribut;
    CompetenceDonnee:     StructureDonnee;
    NivCompMetier:        Integer;
    ValBonus:             String;
    Bonus:                String;
    PersonnageCompetence: StructurePersonnageCompetence;
    AvecEquipement:       Integer;
  begin
    Result := nil;
    NbLigne := 0;

    // Passe 1 : compétences groupées déjà augmentées, pas déjà affichées dans le tableau de base
    for Ind := 0 to ListCompetence.Count - 1 do
      begin
        PCompetence := ListCompetence[Ind];
        if pos(PCompetence.CodeCompetence, ListPris) = 0 then
          begin
            CompetenceDonnee := PdfPersonnageCompetence(Personnage, PCompetence.CodeCompetence, NivCompMetier);
            if CompetenceDonnee.Augmentation <> 0 then
              begin
                PAttribut := ChercheAttribut(PCompetence.CodeAttribut);

                ValBonus := IntToStr(CompetenceDonnee.Augmentation);
                if (StrToIntDef(ValBonus,0) >= 0) and (StrToIntDef(ValBonus,0) < 10) then
                  ValBonus := '  ' + ValBonus;

                Bonus := PdfPersonnageCompetenceBonus(Personnage, PCompetence.CodeCompetence);
                if AnnotationArmure.Values[PCompetence.CodeCompetence] <> '' then
                  Bonus := Bonus + AnnotationArmure.Values[PCompetence.CodeCompetence];

                SetLength(Result, Length(Result)+1);
                SetLength(Result[High(Result)].Valeurs, 7);

                Result[High(Result)].Valeurs[0].Champ      := 'Nom';
                Result[High(Result)].Valeurs[0].Valeur     := PdfSupprimeGenerique(PCompetence.CodeCompetence, PCompetence.Libelle);
                Result[High(Result)].Valeurs[0].Annotation := Bonus;

                Result[High(Result)].Valeurs[1].Champ  := 'Attribut';
                Result[High(Result)].Valeurs[1].Valeur := GetTexteLibelle(PAttribut.Resume);

                Result[High(Result)].Valeurs[2].Champ  := 'Stat';
                Result[High(Result)].Valeurs[2].Valeur := IntToStr(CompetenceDonnee.Base);

                Result[High(Result)].Valeurs[3].Champ := 'Upg';
                if NivCompMetier > 0 then
                  begin
                    Result[High(Result)].Valeurs[3].Valeur := IntToStr(NivCompMetier);
                    Result[High(Result)].Valeurs[3].Grise  := (NivCompMetier > Personnage.MetierEnCours.NiveauMetier);
                  end;

                Result[High(Result)].Valeurs[4].Champ  := 'Adv';
                Result[High(Result)].Valeurs[4].Valeur := ValBonus;

                Result[High(Result)].Valeurs[5].Champ  := 'Total';
                Result[High(Result)].Valeurs[5].Valeur := IntToStr(CompetenceDonnee.Total);

                Result[High(Result)].Valeurs[6].Champ := 'AvecEquipement';
                AvecEquipement := PersonnageArmureBonusCompetenceModifPortee(Personnage, PCompetence.CodeCompetence);
                if AvecEquipement <> 0 then
                  Result[High(Result)].Valeurs[6].Valeur := IntToStr(CompetenceDonnee.Total + AvecEquipement);

                NbLigne := NbLigne + 1;
              end;
          end;
      end;

    // Passe 2 : compétences accessibles via le métier mais pas augmentées ("non prises"),
    // grisées entièrement, pour combler l'espace restant — plafonnée à CapaciteMax lignes au
    // total, comme le faisait l'ancien code (silencieusement tronqué au-delà).
    for PersonnageCompetence in Personnage.MetierCompetence do
      begin
        CompetenceDonnee := PdfPersonnageCompetence(Personnage, PersonnageCompetence.CodeCompetence, NivCompMetier);
        // niveau en cours au plus : les compétences des niveaux suivants ne sont plus proposées d'avance
        if (CompetenceDonnee.Augmentation = 0) and (NivCompMetier > 0) and (NivCompMetier <= Personnage.MetierEnCours.NiveauMetier) then
          if (pos(PersonnageCompetence.CodeCompetence, ListPris) = 0) and (NbLigne < CapaciteMax) then
            begin
              PCompetence := ChercheCompetence(PersonnageCompetence.CodeCompetence);
              PAttribut   := ChercheAttribut(PCompetence.CodeAttribut);

              SetLength(Result, Length(Result)+1);
              SetLength(Result[High(Result)].Valeurs, 4);

              Result[High(Result)].Valeurs[0].Champ  := 'Nom';
              Result[High(Result)].Valeurs[0].Valeur := PdfSupprimeGenerique(PCompetence.CodeCompetence, PCompetence.Libelle);
              Result[High(Result)].Valeurs[0].Grise  := True;

              Result[High(Result)].Valeurs[1].Champ  := 'Attribut';
              Result[High(Result)].Valeurs[1].Valeur := GetTexteLibelle(PAttribut.Resume);
              Result[High(Result)].Valeurs[1].Grise  := True;

              Result[High(Result)].Valeurs[2].Champ  := 'Stat';
              Result[High(Result)].Valeurs[2].Valeur := IntToStr(CompetenceDonnee.Base);
              Result[High(Result)].Valeurs[2].Grise  := True;

              Result[High(Result)].Valeurs[3].Champ  := 'Upg';
              Result[High(Result)].Valeurs[3].Valeur := IntToStr(NivCompMetier);
              Result[High(Result)].Valeurs[3].Grise  := True;
              // Adv/Total : jamais renseignés ici (Augmentation = 0 par construction),
              // comme dans l'ancien code.

              NbLigne := NbLigne + 1;
            end;
      end;
  end;

// PDF "intelligent" page 1 (A FAIRE 20/09/2026) : nombre de lignes de DONNEES dont ont besoin les
// compétences groupées (passe 1 de PdfPreparerRecordSetCompetencesGroupees : celles déjà
// augmentées, hors tableau de base) - les compétences grisées "non prises" ne comptent pas,
// elles comblent seulement l'espace restant.
Function PdfNbCompetencesGroupeesPrises(Personnage: StructurePersonnage; ListPris: String): Integer;
  var
    Ind:           Integer;
    NivCompMetier: Integer;
    PCompetence:   StructureCompetence;
  begin
    Result := 0;
    for Ind := 0 to ListCompetence.Count - 1 do
      begin
        PCompetence := ListCompetence[Ind];
        if pos(PCompetence.CodeCompetence, ListPris) = 0 then
          if PdfPersonnageCompetence(Personnage, PCompetence.CodeCompetence, NivCompMetier).Augmentation <> 0 then
            inc(Result);
      end;
  end;

// Idem pour les talents : lignes ACQUISES de PdfBlocTalents (talents possédés, règles spéciales
// d'appartenance, talents de mutation, talents de qualité d'objet) - hors talents de carrière
// grisés, qui comblent l'espace restant.
Function PdfNbTalentsAcquis(Personnage: StructurePersonnage): Integer;
  var
    IndC:         Integer;
    NivTalMetier: Integer;
    ListeRegle:   TListCareerBonusSpecialRule;
  begin
    Result := 0;
    for IndC := 0 to ListTalent.count - 1 do
      if PdfPersonnageTalent(Personnage, ListTalent[IndC].CodeTalent, NivTalMetier).Total <> 0 then
        inc(Result);
    ListeRegle := PersonnageCareerBonusSpecialRule(Personnage);
    try
      Result := Result + ListeRegle.Count;
    finally
      ListeRegle.Free;
    end;
    Result := Result + Length(PersonnageMutationTalent(Personnage)) + Length(PersonnageArmureBonusTalent(Personnage)) + Length(PersonnageArmeBonusTalent(Personnage));
    if Personnage.SigneAstral <> '' then
      Result := Result + 1;
  end;

// PDF "intelligent" page 2 (A FAIRE 20/09/2026) : nombre de lignes qu'occupe le bloc
// d'explications (PdfBlocDessinExplication), sans le dessiner. Reproduit son compteur NbBonus :
// une section non vide consomme 3 lignes (blanc, titre, blanc) + 1 ligne par bonus ; le résultat
// est l'indice de la dernière ligne écrite (le texte de la ligne n est à YHaut - n * HauteurLigne).
// Chaque chaîne est une liste de codes séparés par des virgules, comme pour le dessin.
Function PdfNbLignesExplication(ArmureBonii, ArmeBonii, FabricationBonii: String): Integer;
  begin
    Result := 0;
    if ArmureBonii <> '' then
      Result := Result + 3 + CountOccurrences(ArmureBonii, ',') + 1;
    if ArmeBonii <> '' then
      Result := Result + 3 + CountOccurrences(ArmeBonii, ',') + 1;
    if FabricationBonii <> '' then
      Result := Result + 3 + CountOccurrences(FabricationBonii, ',') + 1;
    if Result > 0 then
      Inc(Result); // ligne de l'entete du cadre
  end;

// Dessine le panneau Blessure de la page 2 (tableau Blessures : BF/BE/BFM, ligne Hardy, total).
// Extrait de PdfPersonnageCreationFeldo2P, CONTEXT.md §2.4.
Procedure PdfBlocBlessure(PdfPage: TPDFPage; Personnage: StructurePersonnage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; BF, BE, BFM, DurACuire, ValDurACuire, BonusBlessureFab: Integer; AnnotBlessure: String);
  var
    PRaceAttr: StructureRaceAttribut;
    Ch:        String;
    IndC:      Integer;
  begin
    if PdfStyle then
      begin
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfStyleZebra(PdfPage, XGauche, XDroite - 20, Y, HauteurLigne, 2, NbLignes - 2);
      end;
    PdfPage.DrawLine( XGauche , Y, XGauche, Y - (NbLignes * HauteurLigne), 1);
    // Ligne Hardy (20/09/2026) : |Hardy| rang | Objets | valeur objets | total de la ligne |
    PdfPage.DrawLine( XGauche + 24 , Y - (4 * HauteurLigne), XGauche + 24, Y - (5 * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 30 , Y - (4 * HauteurLigne), XGauche + 30, Y - (5 * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 42 , Y - (4 * HauteurLigne), XGauche + 42, Y - (5 * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 48 , Y - (1 * HauteurLigne), XGauche + 48, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine( XGauche + 61 , Y - (1 * HauteurLigne), XGauche + 61, Y - (NbLignes * HauteurLigne), 1);
    PdfPage.DrawLine( XDroite, Y, XDroite, Y - (NbLignes * HauteurLigne), 1);
    for IndC := 0 to NbLignes do
      if (IndC < 2) or (IndC = NbLignes) then
        PdfPage.DrawLine(XGauche,Y - (indC * HauteurLigne), XDroite, Y - (indC * HauteurLigne), 1)
      else
        PdfPage.DrawLine(XGauche,Y - (indC * HauteurLigne), XDroite - 20, Y - (indC * HauteurLigne), 1);
    // Texte Blessure
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage,XGauche + 2,XDroite,Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WOUNDS1_WOUNDS'));
    PdfEcrit(PdfPage,XGauche + 2,XDroite,Y - (2 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WOUNDS7_BS'),MinPolice);
    PdfEcrit(PdfPage,XGauche + 2,XDroite,Y - (3 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WOUNDS7_BT'),MinPolice);
    PdfEcrit(PdfPage,XGauche + 2,XDroite,Y - (4 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WOUNDS7_BWP'),MinPolice);
    PdfEcrit(PdfPage,XGauche + 2,XGauche + 24,Y - (5 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WOUNDS5_HARDY'),MinPolice);
    PdfEcrit(PdfPage,XGauche + 31,XGauche + 42,Y - (5 * HauteurLigne) + 1, GetTexteLibelle('RULES-LAB_182'),MinPolice);
    PdfEcrit(PdfPage,XGauche + 2,XDroite,Y - (6 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_WOUNDS7_Tot'),MinPolice);
    // Valeur Blessure
    Ch := IntToStr(Floor(BF/10));
    if Length(Ch) = 1 then Ch := ' '+Ch;
    PdfCentreValeur(PdfPage,XGauche + 48,XGauche + 61,Y - (2 * HauteurLigne) + 1, Ch);
    Ch := IntToStr(Floor(BE/10)*2);
    if Length(Ch) = 1 then Ch := ' '+Ch;
    PdfCentreValeur(PdfPage,XGauche + 48,XGauche + 61,Y - (3 * HauteurLigne) + 1, Ch);
    Ch := IntToStr(Floor(BFM/10));
    if Length(Ch) = 1 then Ch := ' '+Ch;
    PdfCentreValeur(PdfPage,XGauche + 48,XGauche + 61,Y - (4 * HauteurLigne) + 1, Ch);
    if DurACuire > 0 then
      PdfCentreValeur(PdfPage,XGauche + 24,XGauche + 30,Y - (5 * HauteurLigne) + 1, IntToStr(ValDurACuire));
    if BonusBlessureFab <> 0 then
      PdfCentreValeur(PdfPage,XGauche + 42,XGauche + 48,Y - (5 * HauteurLigne) + 1, IntToStr(BonusBlessureFab));
    if (DurACuire + BonusBlessureFab) <> 0 then
      begin
        Ch := IntToStr(DurACuire + BonusBlessureFab);
        if Length(Ch) = 1 then Ch := ' '+Ch;
        PdfCentreValeur(PdfPage,XGauche + 48,XGauche + 61,Y - (5 * HauteurLigne) + 1, Ch);
      end;
    PRaceAttr := ChercheRaceAttribut(Personnage.Race, ConstCaracBlessure);
    Ch := IntToStr(CalculBlessure(PRaceAttr.CalculRace, BF, BE, BFM) + DurACuire + BonusBlessureFab);
    if Length(Ch) = 1 then Ch := ' '+Ch;
    PdfCentreValeur(PdfPage,XGauche + 48,XGauche + 61,Y - (6 * HauteurLigne) + 1, Ch);
    if AnnotBlessure <> '' then
      begin
        PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 4);
        PdfPage.WriteText(XGauche + 59, Y - (6 * HauteurLigne) + 2.7, AnnotBlessure);
        PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
      end;
  end;

// Dessine le panneau Compétences de combat de la page 2 (Esquive, Calme, Intuition, Commandement,
// Résistance : libellé + total). Extrait de PdfPersonnageCreationFeldo2P, CONTEXT.md §2.4.
Procedure PdfBlocCompetencesCombat(PdfPage: TPDFPage; XGauche, XDroite, Y, HauteurLigne: Single; NbLignes: Integer; MinPolice: Integer; TotalEsquive, TotalCalme, TotalIntuition, TotalCommandement, TotalResitance: Integer);
  var
    PCompetence: StructureCompetence;
    IndC:        Integer;
  begin
    if PdfStyle then
      begin
        PdfOrnements := False;
        PdfStyleTitre(PdfPage, XGauche, XDroite, Y, HauteurLigne);
        PdfOrnements := True;
        PdfStyleZebra(PdfPage, XGauche, XDroite, Y, HauteurLigne, 2, 5);
      end;
    PdfPage.DrawLine(XGauche    , Y,    XGauche,     Y  - (6 * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite - 10   , Y,    XDroite - 10,    Y  - (6 * HauteurLigne), 1);
    PdfPage.DrawLine(XDroite        , Y,    XDroite,         Y  - (6 * HauteurLigne), 1);
    for IndC := 0 to (NbLignes + 1) do
      PdfPage.DrawLine(XGauche,Y - (indC * HauteurLigne), XDroite, Y - (indC * HauteurLigne), 1);
    // Texte Compétence de combat
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    PdfTitreCentre(PdfPage,XGauche,XDroite - 10,Y - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SKILLS1_BASIC'));
    PdfTitreCentre(PdfPage,XDroite - 10,XDroite,Y     - (1 * HauteurLigne) + 1, GetTexteLibelle('RULES-PDF_SKILLS2_TOTAL'));
    PCompetence := ChercheCompetence(ConstCEsquive);
    PdfEcrit(PdfPage ,XGauche + 1,XDroite - 10,Y - (2 * HauteurLigne) + 1, PCompetence.Libelle, MinPolice);
    PdfCentreValeur(PdfPage,XDroite - 10   ,XDroite, Y     - (2 * HauteurLigne) + 1, IntToStr(TotalEsquive));
    PCompetence := ChercheCompetence(ConstCCalme);
    PdfEcrit(PdfPage ,XGauche + 1,XDroite - 10,Y - (3 * HauteurLigne) + 1, PCompetence.Libelle, MinPolice);
    PdfCentreValeur(PdfPage,XDroite - 10   ,XDroite, Y     - (3 * HauteurLigne) + 1, IntToStr(TotalCalme));
    PCompetence := ChercheCompetence(ConstCIntuition);
    PdfEcrit(PdfPage ,XGauche + 1,XDroite - 10,Y - (4 * HauteurLigne) + 1, PCompetence.Libelle, MinPolice);
    PdfCentreValeur(PdfPage,XDroite - 10   ,XDroite, Y     - (4 * HauteurLigne) + 1, IntToStr(TotalIntuition));
    PCompetence := ChercheCompetence(ConstCCommandement);
    PdfEcrit(PdfPage ,XGauche + 1,XDroite - 10,Y - (5 * HauteurLigne) + 1, PCompetence.Libelle, MinPolice);
    PdfCentreValeur(PdfPage,XDroite - 10   ,XDroite, Y     - (5 * HauteurLigne) + 1, IntToStr(TotalCommandement));
    PCompetence := ChercheCompetence(ConstCResitance);
    PdfEcrit(PdfPage ,XGauche + 1,XDroite - 10,Y - (6 * HauteurLigne) + 1, PCompetence.Libelle, MinPolice);
    PdfCentreValeur(PdfPage,XDroite - 10   ,XDroite, Y     - (6 * HauteurLigne) + 1, IntToStr(TotalResitance));
  end;

Function PdfFeldoTableauCaracteristiques(DessinDebColCompG: Integer; DessinDebutHautCarac, DessinHauteurCarac, DessinLargeurCarac: Single): TPdfTableau;
begin
    Result.X               := DessinDebColCompG;
    Result.Y               := DessinDebutHautCarac;
    Result.Orientation     := orColonne;
    Result.LargeurLibelles := 40 - DessinDebColCompG;
    Result.LargeurEntree   := DessinLargeurCarac;
    Result.HauteurLigne    := DessinHauteurCarac;
    Result.Police          := 9;
    SetLength(Result.Champs, 6);
    Result.Champs[0].Libelle := GetTexteLibelle('RULES-PDF_CHARAC1_CHARAC');   Result.Champs[0].Champ := 'Code';     Result.Champs[0].EnTete := True;
    Result.Champs[1].Libelle := GetTexteLibelle('RULES-PDF_CHARAC3_INITIAL');  Result.Champs[1].Champ := 'Initial';
    Result.Champs[2].Libelle := GetTexteLibelle('RULES-PDF_CHARAC3_IMPROV');   Result.Champs[2].Champ := 'Improv';
    Result.Champs[3].Libelle := GetTexteLibelle('RULES-PDF_CHARAC3_ADVANCES'); Result.Champs[3].Champ := 'Advances';
    Result.Champs[4].Libelle := GetTexteLibelle('RULES-PDF_CHARAC3_CURRENT');  Result.Champs[4].Champ := 'Current';
    Result.Champs[5].Libelle := GetTexteLibelle('RULES-PDF_CHARAC3_BONUS');    Result.Champs[5].Champ := 'Bonus';
end;

Function PdfFeldoTableauCompetencesBase(DessinDebColCompG, DessinDebColG, DessinNbLigComp, MinPolice: Integer; DessinDebutHautComp, DessinLargeurComp, DessinHauteurComp: Single): TPdfTableau;
begin
    Result.X                := DessinDebColCompG;
    Result.Y                := DessinDebutHautComp;
    Result.Orientation      := orLigne;
    Result.LargeurEntree    := DessinLargeurComp;
    Result.HauteurLigne     := DessinHauteurComp;
    Result.Police           := 9;
    Result.PoliceMin        := MinPolice;
    Result.Titre            := Trim(GetTexteLibelle('RULES-PDF_SKILLS1_BASIC'));
    Result.TitreDecalageGauche := 15;
    Result.NbLignesMax       := DessinNbLigComp - 2; // 2 lignes d'en-tête (titre + libellés)

    SetLength(Result.Champs, 7);
    Result.Champs[0].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_NAME');
    Result.Champs[0].Champ             := 'Nom';
    Result.Champs[0].EnTete            := True;
    Result.Champs[0].Largeur           := 55 - DessinDebColG;
    Result.Champs[0].AlignementEntete  := alGauche;
    Result.Champs[0].DecalageEnteteMin := 2;
    Result.Champs[0].DecalageEnteteMax := 0;
    Result.Champs[0].DecalageValeurMin := 2;
    Result.Champs[0].DecalageValeurMax := 3.5;

    Result.Champs[1].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_CHARAC');
    Result.Champs[1].Champ             := 'Attribut';
    Result.Champs[1].EnTete            := True;
    Result.Champs[1].FusionAvecSuivante:= True;
    Result.Champs[1].DecalageValeurMin := 3.5;
    Result.Champs[1].DecalageValeurMax := 3.5;

    Result.Champs[2].Champ             := 'Stat';
    Result.Champs[2].DecalageValeurMin := 3.5;
    Result.Champs[2].DecalageValeurMax := 3.5;

    Result.Champs[3].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_UPG');
    Result.Champs[3].Champ             := 'Upg';
    Result.Champs[3].DecalageValeurMin := 3.5;
    Result.Champs[3].DecalageValeurMax := 3.5;

    Result.Champs[4].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_ADV');
    Result.Champs[4].Champ             := 'Adv';
    Result.Champs[4].DecalageValeurMin := 3.5;
    Result.Champs[4].DecalageValeurMax := 3.5;

    Result.Champs[5].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_TOTAL');
    Result.Champs[5].Champ             := 'Total';
    Result.Champs[5].DecalageValeurMin := 3.5;
    Result.Champs[5].DecalageValeurMax := 3.5;

    // Colonne "avec equipement" (CONTEXT.md 2.59) : vide si l'equipement porte ne modifie pas
    // la competence, total ajuste sinon - remplie par PdfPreparerRecordSetCompetencesBase.
    Result.Champs[6].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_GEAR');
    Result.Champs[6].Champ             := 'AvecEquipement';
    // Largeur explicite (8, au lieu du DessinLargeurComp=8.6 par defaut) pour que le bord
    // droit du tableau (12 + 35 + 5*8.6 + 8 = 98) tombe pile sur celui d'Ambitions
    // (DessinFinColG=98) - sans elle l'ecart etait de 0.6mm (Nono, 12/09/2026).
    Result.Champs[6].Largeur           := 8;
    Result.Champs[6].DecalageValeurMin := 3.5;
    Result.Champs[6].DecalageValeurMax := 3.5;
end;

Procedure PdfFeldoRepartitionPage1(Personnage: StructurePersonnage; ListPris: String; DessinMinLignesVides: Integer; var DessinNbLigComg, DessinNbLigTal, DessinNbLigMut: Integer);
var
  BudgetDonnees, BesoinComg, BesoinTal, LibreDonnees, BesoinMut: Integer;
begin
  // Répartition "intelligente" du budget de lignes de la colonne droite (Compétences groupées
  // + Talents, valeurs par défaut 24 + 21) selon le besoin réel du personnage, avec un
  // minimum de lignes vides par tableau pour noter à la main (A FAIRE 20/09/2026). Chaque
  // tableau garde 2 lignes d'en-tête. Le total ne change pas, donc le bas de page non plus.
  // Les Mutations font partie du budget (3 lignes de données par défaut) : besoin + 1 ligne
  // vide, cédant leurs lignes vides aux deux autres tableaux si besoin.
  BudgetDonnees := (DessinNbLigComg - 2) + (DessinNbLigTal - 2) + DessinNbLigMut;
  BesoinMut     := Length(Personnage.Mutations);
  DessinNbLigMut := BesoinMut + 1;
  if BudgetDonnees - DessinNbLigMut < PdfNbCompetencesGroupeesPrises(Personnage, ListPris) + PdfNbTalentsAcquis(Personnage) then
    DessinNbLigMut := Max(BesoinMut, BudgetDonnees - PdfNbCompetencesGroupeesPrises(Personnage, ListPris) - PdfNbTalentsAcquis(Personnage));
  if DessinNbLigMut < 1 then DessinNbLigMut := 1;
  BudgetDonnees := BudgetDonnees - DessinNbLigMut;
  BesoinComg    := PdfNbCompetencesGroupeesPrises(Personnage, ListPris);
  BesoinTal     := PdfNbTalentsAcquis(Personnage);
  LibreDonnees  := BudgetDonnees - BesoinComg - BesoinTal;
  if LibreDonnees >= 2 * DessinMinLignesVides then
    begin
      // tout tient avec le minimum de lignes vides : le reste se partage à parts égales
      DessinNbLigComg := 2 + BesoinComg + DessinMinLignesVides + ((LibreDonnees - 2 * DessinMinLignesVides) div 2);
      DessinNbLigTal  := 2 + BudgetDonnees - (DessinNbLigComg - 2);
    end
  else
    begin
      // serré : chacun garde son besoin, le peu de place qui reste est réparti
      // (au-delà du budget, la coupure existante s'applique)
      if LibreDonnees < 0 then LibreDonnees := 0;
      DessinNbLigComg := 2 + BesoinComg + (LibreDonnees div 2);
      DessinNbLigTal  := 2 + BudgetDonnees - (DessinNbLigComg - 2);
      if DessinNbLigTal < 2 + BesoinTal then
        begin
          DessinNbLigTal  := 2 + BesoinTal;
          DessinNbLigComg := 2 + BudgetDonnees - BesoinTal;
        end;
    end;
end;

Function PdfFeldoTableauCompetencesGroupees(DessinDebColD, DessinNbLigComg, MinPolice: Integer; DessinDebutHautComg, DessinLargeurComg, DessinHauteurComg: Single): TPdfTableau;
begin
    Result.X                 := DessinDebColD;
    Result.Y                 := DessinDebutHautComg;
    Result.Orientation       := orLigne;
    Result.LargeurEntree     := DessinLargeurComg;
    Result.HauteurLigne      := DessinHauteurComg;
    Result.Police            := 9;
    Result.PoliceMin         := MinPolice;
    Result.Titre             := Trim(GetTexteLibelle('RULES-PDF_SKILLS1_ADVANCED'));
    Result.TitreDecalageGauche := 15;
    Result.NbLignesMax        := DessinNbLigComg - 2; // 2 lignes d'en-tête (titre + libellés)

    SetLength(Result.Champs, 7);
    Result.Champs[0].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_NAME');
    Result.Champs[0].Champ             := 'Nom';
    Result.Champs[0].Largeur           := 143 - DessinDebColD;
    Result.Champs[0].AlignementEntete  := alGauche;
    Result.Champs[0].DecalageEnteteMin := 5;
    Result.Champs[0].DecalageEnteteMax := 5;
    Result.Champs[0].DecalageValeurMin := 3;
    Result.Champs[0].DecalageValeurMax := 0;

    Result.Champs[1].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_CHARAC');
    Result.Champs[1].Champ             := 'Attribut';
    Result.Champs[1].FusionAvecSuivante:= True;
    Result.Champs[1].DecalageValeurMin := 2.5;
    Result.Champs[1].DecalageValeurMax := 2.5;

    Result.Champs[2].Champ             := 'Stat';
    Result.Champs[2].DecalageValeurMin := 2.5;
    Result.Champs[2].DecalageValeurMax := 2.5;

    Result.Champs[3].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_UPG');
    Result.Champs[3].Champ             := 'Upg';
    Result.Champs[3].DecalageValeurMin := 2.5;
    Result.Champs[3].DecalageValeurMax := 2.5;

    Result.Champs[4].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_ADV');
    Result.Champs[4].Champ             := 'Adv';
    Result.Champs[4].DecalageValeurMin := 2.5;
    Result.Champs[4].DecalageValeurMax := 2.5;

    Result.Champs[5].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_TOTAL');
    Result.Champs[5].Champ             := 'Total';
    Result.Champs[5].DecalageValeurMin := 2.5;
    Result.Champs[5].DecalageValeurMax := 2.5;

    // Colonne "avec equipement" (CONTEXT.md 2.59) : meme principe que TableauComp - remplie
    // par PdfPreparerRecordSetCompetencesGroupees. La table s'elargit d'autant vers la droite
    // (DessinDebColD, son bord gauche, reste inchange) ; marge page restante ~13mm (>1cm).
    Result.Champs[6].Libelle           := GetTexteLibelle('RULES-PDF_SKILLS2_GEAR');
    Result.Champs[6].Champ             := 'AvecEquipement';
    Result.Champs[6].DecalageValeurMin := 2.5;
    Result.Champs[6].DecalageValeurMax := 2.5;
end;

Procedure PdfFeldoRepartitionPage2(Personnage: StructurePersonnage; ArmureSet: Boolean; NbLigExpl, DessinMinLignesVides: Integer; var DessinNbLigArm, DessinNbLigEqu, DessinNbLigWea, DessinNbLigSor: Integer);
var
  BudgetSorts, BesoinSor, NbDivers, NbEquNeeded, PrisSor, NbArmPieces, NbWeaPieces, ArmN, EquN, WeaN, SorN, LibreSor: Integer;
  PEquipDry: StructurePersonnageEquipement;
begin
  BudgetSorts := DessinNbLigSor;
  BesoinSor   := 0;
  for PEquipDry in Personnage.Equipement do
    if PEquipDry.TypeEquipement = TypeEquipSp then
      inc(BesoinSor);
  // Équipement : les objets Divers/Animaux se répartissent sur deux demi-colonnes de
  // NbLignes-1 lignes de données chacune ; besoin + lignes vides, jamais sous la taille par défaut.
  NbDivers := 0;
  for PEquipDry in Personnage.Equipement do
    if (PEquipDry.TypeEquipement = TypeEquipDI) or (PEquipDry.TypeEquipement = TypeEquipAN) then
      inc(NbDivers);
  // Armure : une ligne par pièce (NbLignes-1 lignes de données), plus une ligne vide
  NbArmPieces := 0;
  for PEquipDry in Personnage.Equipement do
    if ((not ArmureSet) and (PEquipDry.TypeEquipement = TypeEquipAR)) or
       (ArmureSet and (PEquipDry.TypeEquipement = TypeEquipARS)) then
      inc(NbArmPieces);
  NbEquNeeded := (NbDivers + DessinMinLignesVides + 1) div 2 + 1;
  // Répartition par besoin (Nono 20/09/2026) : chaque cadre reçoit son besoin + lignes vides,
  // l'Armure ne grossit plus pour le texte des explications (elles se placent à droite
  // d'Armure + Équipement : c'est l'Équipement qui prend la hauteur manquante).
  NbWeaPieces := 0;
  for PEquipDry in Personnage.Equipement do
    if PEquipDry.TypeEquipement = TypeEquipWe then
      inc(NbWeaPieces);
  ArmN := NbArmPieces + 1;
  if ArmN < 3 then ArmN := 3;
  EquN := Max(NbEquNeeded, DessinNbLigEqu);
  if EquN < NbLigExpl - ArmN - 2 then EquN := NbLigExpl - ArmN - 2;
  WeaN := Max(NbWeaPieces + DessinMinLignesVides + 1, 5);
  SorN := Max(BesoinSor + DessinMinLignesVides, 4);
  if SorN > BudgetSorts then SorN := BudgetSorts;
  LibreSor := (DessinNbLigArm + DessinNbLigEqu + DessinNbLigWea + BudgetSorts) - (ArmN + EquN + WeaN + SorN);
  if LibreSor < 0 then
    begin
      // trop de tout : les Sorts cèdent leurs lignes vides, puis les Armes, puis l'Équipement
      // (dont la liste est alors tronquée par "...")
      PrisSor := Min(-LibreSor, SorN - Max(BesoinSor + 1, 2));
      if PrisSor < 0 then PrisSor := 0;
      SorN := SorN - PrisSor; LibreSor := LibreSor + PrisSor;
      PrisSor := Min(-LibreSor, WeaN - Max(NbWeaPieces + 1, 3));
      if PrisSor < 0 then PrisSor := 0;
      WeaN := WeaN - PrisSor; LibreSor := LibreSor + PrisSor;
      PrisSor := Min(-LibreSor, EquN - 3);
      if PrisSor < 0 then PrisSor := 0;
      EquN := EquN - PrisSor; LibreSor := LibreSor + PrisSor;
    end;
  if LibreSor < 0 then LibreSor := 0;
  DessinNbLigArm := ArmN;
  DessinNbLigEqu := EquN + (LibreSor + 1) div 2;
  DessinNbLigWea := WeaN + LibreSor div 2;
  DessinNbLigSor := SorN;
end;

Function PdfFeldoMetiersAnciens(Personnage: StructurePersonnage): String;
var
  PMetier: StructureMetier;
  PersonnageMetier: StructurePersonnageMetier;
  DernierMetier, LocData: String;
begin
  DernierMetier := '';
  LocData        := '';
  for PersonnageMetier in Personnage.MetierAncien do
    begin
      if (DernierMetier <> PersonnageMetier.CodeMetier) then
        begin
          PMetier       := ChercheMetier(PersonnageMetier.CodeMetier);
          if Locdata <> '' then
            LocData     := LocData + ' - ';
          LocData       := LocData + PMetier.Libelle + ':';
          DernierMetier := PersonnageMetier.CodeMetier;
        end
      else if LocData <> '' then
        LocData         := LocData + ',';
       LocData          := LocData + IntToStr(PersonnageMetier.NiveauMetier);
    end;
  Result := LocData;
end;

// Ajoute une image PNG au document ; sans couleur, une copie en niveaux de gris (canal alpha
// conserve) est ecrite dans le dossier temporaire. Repli sur l'image d'origine en cas d'echec.
Function PdfAjouteImage(PdfDoc: TPDFDocument; const Chemin: String): Integer;
var
  Img: TFPMemoryImage;
  Lec: TFPReaderPNG;
  Ecr: TFPWriterPNG;
  X, Y: Integer;
  C: TFPColor;
  G: Word;
  Tmp: String;
begin
  if PdfCouleur then
    Exit(PdfDoc.Images.AddFromFile(Chemin, false));
  Tmp := IncludeTrailingPathDelimiter(GetTempDir) + 'wh_gris_' + ExtractFileName(Chemin);
  try
    Img := TFPMemoryImage.Create(0, 0);
    Lec := TFPReaderPNG.Create;
    Ecr := TFPWriterPNG.Create;
    try
      Img.LoadFromFile(Chemin, Lec);
      for Y := 0 to Img.Height - 1 do
        for X := 0 to Img.Width - 1 do
          begin
            C := Img.Colors[X, Y];
            G := (Cardinal(C.red) * 299 + Cardinal(C.green) * 587 + Cardinal(C.blue) * 114) div 1000;
            C.red := G; C.green := G; C.blue := G;
            Img.Colors[X, Y] := C;
          end;
      Ecr.UseAlpha := True;
      Img.SaveToFile(Tmp, Ecr);
    finally
      Ecr.Free; Lec.Free; Img.Free;
    end;
    Result := PdfDoc.Images.AddFromFile(Tmp, false);
  except
    Result := PdfDoc.Images.AddFromFile(Chemin, false);
  end;
end;

// Texte en courbe : chaque lettre est posee puis tournee (WriteText avec ADegrees) sur un cercle de
// rayon Rayon centre en (XC, YC). Haut = arc du dessus, lu de gauche a droite, pieds des lettres
// vers le centre ; sinon arc du dessous, lu de gauche a droite, tetes des lettres vers le centre
// (Rayon est alors le rayon de la ligne de base). Police et couleur : celles deja reglees.
Procedure PdfTexteSurArc(PdfPage: TPDFPage; XC, YC, Rayon: Single; Texte: String; Taille: Integer; Haut: Boolean);
  const
    Chasse = 0.35;   // espacement ajoute entre lettres, en mm
  var
    Ind: Integer;
    Larg: array of Single;
    Total, Cumul, Theta, Phi, PX, PY: Single;
  begin
    SetLength(Larg, Length(Texte));
    Total := 0;
    for Ind := 1 to Length(Texte) do
      begin
        Larg[Ind - 1] := TailleTexte(Texte[Ind], Taille) + Chasse;
        Total := Total + Larg[Ind - 1];
      end;
    Cumul := 0;
    for Ind := 1 to Length(Texte) do
      begin
        if Haut then
          Theta := Pi / 2 + (Total / 2 - Cumul - Larg[Ind - 1] / 2) / Rayon
        else
          Theta := 3 * Pi / 2 - (Total / 2 - Cumul - Larg[Ind - 1] / 2) / Rayon;
        if Haut then
          Phi := Theta - Pi / 2
        else
          Phi := Theta - 3 * Pi / 2;
        PX := XC + Rayon * Cos(Theta) - (Larg[Ind - 1] / 2) * Cos(Phi);
        PY := YC + Rayon * Sin(Theta) - (Larg[Ind - 1] / 2) * Sin(Phi);
        if Texte[Ind] <> ' ' then
          PdfPage.WriteText(PX, PY, Texte[Ind], RadToDeg(Phi));
        Cumul := Cumul + Larg[Ind - 1];
      end;
  end;

Procedure PdfFeldoImagesEntete(PDFDoc: TPDFDocument; PdfPage: TPDFPage; DessinDebutHautEntete: Single);
// Embleme maison, sans les logos officiels (sans licence ou sans PICTURES) : disque rouge cercle d'or, "WARHAMMER" sur la
// moitie haute, "FANTASY" sur la moitie basse, version du jeu (V4/V5) dans un medaillon central.
// Memes couleurs que le reste de l'habillage (PdfTeinte : niveaux de gris, PdfEconomie : sans fond).
var
  XC, YC, R, RMed: Single;
  Version: String;
  PdfImgWarhammer, PdfImgFantasy, PdfImgUbersreik: Integer;
begin
  // Logos du livre quand ils sont la (PICTURES present), comme avant ; sinon l'embleme maison
  // (version sans licence, ou installation publique sans PICTURES).
  if (not ImagesDefautSeul) and
     FileExists(CheminImage(GetCurrentDir + StringReplace(ConstCheminPdfUbersreik, ConstLangue, ValLangue, [rfReplaceAll]))) then
    begin
      PdfImgWarhammer  := PdfAjouteImage(PdfDoc, CheminImagePdf(GetCurrentDir+StringReplace(ConstCheminPdfWarhammer, ConstLangue, ValLangue, [rfReplaceAll])));
      PdfPage.DrawImage(152, DessinDebutHautEntete - 5, 36, 5, PdfImgWarhammer);
      PdfImgFantasy    := PdfAjouteImage(PdfDoc, CheminImagePdf(GetCurrentDir+StringReplace(ConstCheminPdfRolePlay, ConstLangue, ValLangue, [rfReplaceAll])));
      PdfPage.DrawImage(152, DessinDebutHautEntete - 17, 36, 12, PdfImgFantasy);
      PdfImgUbersreik  := PdfAjouteImage(PdfDoc, CheminImagePdf(GetCurrentDir+StringReplace(ConstCheminPdfUbersreik, ConstLangue, ValLangue, [rfReplaceAll])));
      PdfPage.DrawImage(152, DessinDebutHautEntete - 55, 36, 38, PdfImgUbersreik);
      Exit;
    end;
  XC   := 170;
  YC   := DessinDebutHautEntete - 18;
  R    := 17;
  RMed := 4.8;
  Version := 'V4';
  if Length(ValVersion) >= 5 then
    Version := 'V' + Copy(ValVersion, 5, 1);
  // disque
  if not PdfEconomie then
    begin
      PdfPage.SetColor(PdfTeinte(PdfCouleurRouge), False);
      PdfPage.DrawEllipse(XC - R, YC - R, 2 * R, 2 * R, 0, True, False);
    end;
  PdfPage.SetColor(PdfTeinte(PdfCouleurOr), True);
  PdfPage.DrawEllipse(XC - R, YC - R, 2 * R, 2 * R, 1.2, False, True);
  PdfPage.DrawEllipse(XC - R + 1.6, YC - R + 1.6, 2 * R - 3.2, 2 * R - 3.2, 0.4, False, True);
  // diametre
  PdfPage.DrawLine(XC - R + 1.6, YC, XC + R - 1.6, YC, 0.6);
  // medaillon central
  if not PdfEconomie then
    begin
      PdfPage.SetColor(PdfTeinte(PdfCouleurMise), False);
      PdfPage.DrawEllipse(XC - RMed, YC - RMed, 2 * RMed, 2 * RMed, 0, True, False);
    end;
  PdfPage.SetColor(PdfTeinte(PdfCouleurOr), True);
  PdfPage.DrawEllipse(XC - RMed, YC - RMed, 2 * RMed, 2 * RMed, 0.8, False, True);
  // textes
  PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceArial + ConstPoliceGras, 7);
  if PdfEconomie then
    PdfPage.SetColor(PdfTeinte(PdfCouleurEncre), False)
  else
    PdfPage.SetColor(PdfTeinte(PdfCouleurParchemin), False);
  PdfTexteSurArc(PdfPage, XC, YC, 11.8, 'WARHAMMER', 7, True);
  PdfTexteSurArc(PdfPage, XC, YC, 14.2, 'FANTASY', 7, False);
  PdfPage.SetColor(PdfTeinte(PdfCouleurEncre), False);
  PdfTaillePolice(PdfPage, PdfFontBold, ConstPoliceArial + ConstPoliceGras, 10);
  PdfCentre(PdfPage, XC - RMed, XC + RMed, YC - 1.5, Version);
  // retour a l'etat attendu par la suite de la page
  PdfPage.SetColor(clBlack, False);
  PdfStyleEncre(PdfPage);
  PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson + ConstPoliceGras, 10);
end;

Procedure PdfFeldoEncombrement(PdfPage: TPDFPage; DessinDebColCompG: Integer; DessinLargeurEnc, DessinDebutHautEnc, DessinHauteurEnc: Single; DessinNbLigEnc, EncArmure, EncArme, EncDivers, BF, BE, BonusEncomb: Integer);
begin
  //  gérer les encombrement
  PdfCentre(PdfPage, DessinDebColCompG + 15, DessinLargeurEnc, DessinDebutHautEnc - ((DessinNbLigEnc - 3) * DessinHauteurEnc) + 0.9, IntToStr(EncArmure));
  PdfCentre(PdfPage, DessinDebColCompG + 15, DessinLargeurEnc, DessinDebutHautEnc - ((DessinNbLigEnc - 2) * DessinHauteurEnc) + 0.9, IntToStr(EncArme));
  PdfCentre(PdfPage, DessinDebColCompG + 15, DessinLargeurEnc, DessinDebutHautEnc - ((DessinNbLigEnc - 1) * DessinHauteurEnc) + 0.9, IntToStr(EncDivers));
  PdfCentre(PdfPage, DessinDebColCompG + 15, DessinLargeurEnc, DessinDebutHautEnc - ((DessinNbLigEnc - 0) * DessinHauteurEnc) + 0.9, IntToStr(Floor(BF/10) + Floor(BE/10) + BonusEncomb));
  PdfCentre(PdfPage, DessinDebColCompG + 15, DessinLargeurEnc, DessinDebutHautEnc - ((DessinNbLigEnc + 1) * DessinHauteurEnc) + 0.9, IntToStr(EncArmure + EncArme + EncDivers));
end;

Procedure PdfPersonnageCreationFeldo2P(Personnage: StructurePersonnage);
  var
    PDFDoc:          TPDFDocument;
    PdfSection:      TPDFSection;
    PdfPage:         TPDFPage;
    PDFOption:       TPDFOptions;
    PdfChemin:       String;
    PRace:           StructureRace;
    PMetier:         StructureMetier;
    PMetierNiveau:   StructureMetierNiveau;
    Mouv:            Integer = 0;
    ListPage:        TStringList;
    ListAsterisqueArmure: TStringList;
    AsterisqueParEquipement: TStringList;
    ListAsterisqueMutation: TStringList;
    AsterisqueParMutation:  TStringList;
    AsterisqueFinalMutation: Integer;
    AsterisqueFinalArmure:   Integer;
    IndC:            Integer;
    ListPris:        String;
    BF, BE, BFM:     Integer;
    DurACuire:       Integer = 0;
    ValDurACuire:    Integer = 0;
    BonusBlessureFab: Integer = 0;   // Rune of Iron et autres fabrications portees
    AnnotBlessure:   String = '';
    BonusEncomb:     Integer = 0;
    EncArme:         Integer;
    EncArmure:       Integer;
    EncDivers:       Integer = 0;
    ArmureTete:      Integer;
    ArmureBras:      Integer;
    ArmureCorps:     Integer;
    ArmureJambe:     Integer;
    ArmureBouclier:  Integer;
    DessinHautArmourPoints: Single;
    AsterisqueArmure: String;
    LocData:         String;
    ArmeBonii:       String = '';
    ArmureBonii:     String = '';
    FabricationBonii:String = '';
    PAttribut:       StructureAttribut;
    Chance:          Integer;
    Determine:       Integer;
    TBonusCC:        Integer=0;
    TBonusCT:        Integer=0;
    Val:             Integer;
    BonusSprint:     Integer=0;
    MinPolice:       Integer=5;
    AttributDonnee:          StructureDonnee;
    ArmureSet:               Boolean = false;
    AmePure:                 Integer=0;
    LostCorruption:          Integer = 0;
    TotalEsquive:            Integer = 0;
    TotalCalme:              Integer = 0;
    TotalResitance:          Integer = 0;
    TotalCommandement:       Integer = 0;
    TotalIntuition:          Integer = 0;
    Bonus:                   String;
    TableauCarac:            TPdfTableau;
    DonneesCarac:            TPdfRecordSet;
    TableauComp:             TPdfTableau;
    DonneesComp:             TPdfRecordSet;
    TableauCompG:            TPdfTableau;
    DonneesCompG:            TPdfRecordSet;
    PoliceGaramond:          Boolean = False;
    CheminGaramondIt:        String = '';
    CheminGaramondGras:      String = '';
    FamilleGaramond:         String = 'Garamond';

    // Page 1
      // Entête
      DessinFinEntete:      Integer = 143;
      DessinDebColG:        Integer = 20;
      DessinFinColG:        Integer = 98;
      DessinDebColD:        Integer = 102;
      // Bord gauche PARTAGE par tous les blocs de la colonne gauche de la page 1 (Entete,
      // Caracteristiques, tableau Competences de base, Ambitions, Resilience/Destin, Mouvement,
      // Experience, Corruption) depuis la colonne "W/ Gear" (CONTEXT.md 2.59) - decale par
      // rapport a l'ancien DessinDebColG (20). Les bords DROITS existants (DessinFinColG,
      // DessinLargeurExp utilisee comme bord droit absolu) restent inchanges : chaque bloc
      // gagne la largeur en plus sur sa gauche, comme le tableau de competences lui-meme. Marge
      // page restante : 12mm, superieure au minimum d'1cm (Nono, 12/09/2026).
      // Etendue a tous les blocs de la PAGE 2 (Armure/Equipement/Armes/Sorts/Encombrement/
      // Armour Points/Mutations) le 12/09/2026 (CONTEXT.md 2.63) - leurs bords DROITS
      // (DessinLargeurArm/Equ/Wea/Sor/Enc, utilisees comme bord droit absolu) restent eux
      // aussi inchanges, seul le bord gauche partage bouge, meme principe qu'au-dessus.
      // DessinDebColG (20) ne sert plus qu'a la largeur de la colonne "Nom" du tableau
      // Competences de base (ligne ~4348, 55-DessinDebColG=35, formule volontairement
      // inchangee - ce n'est pas une position mais une largeur figee).
      DessinDebColCompG:    Integer = 12;
      // Bord droit du tableau Competences groupees une fois elargi (7e colonne) - Talents
      // (juste en dessous) s'elargit a l'identique pour rester aligne. Marge page restante :
      // 13mm, superieure au minimum d'1cm.
      DessinFinColCompD:    Integer = 197;
      // Colonne gauche
        // Images
        PdfImgShadow:    Integer;
        // Entete
        DessinDebutHautEntete:Single  = 285;
        DessinHauteurEntete:  Single  = 4.5;
        DessinNbLigEntete:    Integer = 4;
        // Caractéristiques
        DessinDebutHautCarac: Single;
        DessinHauteurCarac:   Single  = 4.6;
        DessinLargeurCarac:   Single  = 10.3;
        // Compétence
        DessinDebutHautComp:  Single;
        DessinHauteurComp:    Single  = 4.4;
        DessinNbLigComp:      Integer = 28;
        DessinLargeurComp:    Single  = 8.6;
        // Ambition (page 2 depuis le 27/09/2026, a cote du bloc Montures/Navires - NbLignes
        // fixe a 5 dans PdfBlocAmbitions, plus besoin de variable ici)
        DessinDebutHautAmb:   Single;
        DessinHauteurAmb:     Single  = 4.4;
        DessinHautMontures:   Single;
        // Résilience
        DessinDebutHautRes:   Single;
        DessinHauteurRes:     Single  = 4.4;
        DessinNbLigRes:       Integer = 4;
        // Destin
        DessinDebutHautDes:   Single;
        DessinHauteurDes:     Single  = 4.4;
        // Blessure
        DessinHauteurBle:     Single  = 4.6;
        DessinNbLigBle:       Integer = 6;
        // Expérience
        DessinDebutHautExp:   Single;
        DessinHauteurExp:     Single = 4.4;
        DessinNbLigExp:       Integer = 3;
        DessinLargeurExp:     Single = 45;
        // Mouvement
        DessinDebutGaucheMou: Single;
        DessinHauteurMou:     Single = 4.4;
        DessinNbLigMou:       Integer = 3;
        // Elargi de 22 a 30 le 12/09/2026 (Nono) : le bord droit (DessinDebutGaucheMou +
        // DessinLargeurMou) retombe ainsi sur DessinFinColG (98), comme Ambitions au-dessus -
        // le separateur libelles/valeur de PdfBlocMouvement a ete elargi a l'identique (+23
        // au lieu de +15) pour que les libelles gagnent cette largeur, pas la colonne valeur.
        DessinLargeurMou:     Single = 30;
        // Corruption
        DessinDebutHautCor:   Single;
        DessinHauteurCor:     Single = 4.4;
        DessinNbLigCor:       Integer = 6;
        DessinLargeurCor:     Single;
        // Corruption Détail (tableau Montant | Libellé, à droite d'Expérience/Corruption)
        DessinDebutGaucheCorDet: Single;
        DessinHauteurCorDet:     Single  = 4.4;
        DessinNbLigCorDet:       Integer = 11;
      // Colonne droite
        // Compétence Groupée
        DessinDebutHautComg:  Single;
        DessinHauteurComg:    Single  = 4.4;
        // 26 -> 24 le 20/09/2026 : deux lignes cédées aux Talents (19 -> 21).
        DessinNbLigComg:      Integer = 24;
        DessinLargeurComg:    Single  = 9;
        // Talents
        DessinDebutHautTal:   Single;
        DessinHauteurTal:     Single  = 4.4;
        // 24 -> 21 le 20/09/2026 : 3 lignes libérées en bas pour le bloc Mutations sous les
        // Talents (déplacé depuis la page 2, où la place revient au bloc monture) ; +2 lignes
        // gagnées sur les Compétences groupées (26 -> 24), qui remontent le tableau.
        DessinNbLigTal:       Integer = 21;
        // Répartition intelligente Compétences groupées / Talents (A FAIRE 20/09/2026)
        DessinMinLignesVides: Integer = 3;
        DessinNbLigMut:       Integer = 3;
        // Passe à blanc + répartition page 2 (A FAIRE 20/09/2026)
        PdfPageBlanc: TPDFPage;
        NbLigExpl: Integer;

    // Page 2
      // Armure
        DessinDebutHautArm:   Single;
        DessinHauteurArm:     Single = 4.4;
        DessinNbLigArm:       Integer = 6;
        DessinLargeurArm:     Single = 128;
      // Equipement
        DessinDebutHautEqu:   Single;
        DessinHauteurEqu:     Single = 4.4;
        DessinNbLigEqu:       Integer = 5;
        DessinLargeurEqu:     Single = 128;
      // Armes
        DessinDebutHautWea:   Single;
        DessinHauteurWea:     Single = 4.4;
        DessinNbLigWea:       Integer = 8;
        DessinLargeurWea:     Single = 200;
      // Sorts
        DessinDebutHautSor:   Single;
        DessinHauteurSor:     Single = 4.4;
        DessinNbLigSor:       Integer = 11;
        DessinLargeurSor:     Single = 200;
      // Explications
        DessinHauteurExl:     Single = 2.5;
      // Encombrement
        DessinDebutHautEnc:   Single;
        DessinHauteurEnc:     Single = 4.6;
        DessinNbLigEnc:       Integer = 5;
        DessinLargeurEnc:     Single = 44;
      // Compétence de combat
        DessinHauteurComC:    Single = 4.6;
        DessinNbLigComC:      Integer = 5;
        DessinLargeurComC:    Single = 200;


  procedure PdfPreparation;
    var
      Ind: Integer;
      PersonnageAttribut: StructurePersonnageAttribut;
      PRaceAttribut: StructureRaceAttribut;
    begin
    Personnage := PersonnageSansMunitions(Personnage);
    PdfChemin        := GetCurrentDir+ConstCheminPersonnage+Personnage.NomPersonnage+'\'+Personnage.NomPersonnage+' '+FormatDateTime('yyyymmdd-hhnnss', Now)+'.PDF';

    if (Pos(AjouteAccolade(ConstXmlOptionQuickArmor),Personnage.Options) > 0) then
      ArmureSet := True;
    // Habillage Warhammer (prototype) : fonds et couleurs seulement, voir PdfStyle.
    PdfStyle   := Pos(AjouteAccolade(ConstXmlOptionStylePdf), Personnage.Options) > 0;
    PdfEconomie := PdfStyle and (Pos(AjouteAccolade(ConstXmlOptionPdfEconomie), Personnage.Options) > 0);
    PdfCouleur := Pos(AjouteAccolade(ConstXmlOptionPdfSansCouleur), Personnage.Options) = 0;

    if FileExists(PdfChemin) then
      if not DeleteFile(PdfChemin) then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_038'));
          exit;
        end;

    PDFDoc          := TPDFDocument.Create(nil);
    PDFOption       := [poUseImageTransparency, poCompressImages, poCompressFonts, poCompressText ];
    PDFDoc.Options  := PDFOption;
    PDFDoc.StartDocument;
    PdfSection      := PDFDoc.Sections.AddSection;

  // PAGE 1
    PdfPage         := PDFDoc.Pages.AddPage;
    PdfPolicesDeRepli;
    PdfFontBack     := PdfDoc.AddFont(PdfCheminPolice('CaslonAntique-Bold.ttf'), ConstPoliceCarlson+ConstPoliceGras);
    // Habillage : Garamond a la place d'Arial pour les donnees si la police est disponible
    // (ConstPoliceArial sert de nom de famille a tous les PdfTaillePolice, remis a Arial en fin).
    PoliceGaramond := PdfStyle and PdfGaramondChemins(CheminGaramondIt, CheminGaramondGras, FamilleGaramond);
    if PoliceGaramond then
      begin
        ConstPoliceArial := FamilleGaramond;
        PdfFontValue    := PdfDoc.AddFont(CheminGaramondIt, ConstPoliceArial);
        PdfFontBold     := PdfDoc.AddFont(CheminGaramondGras, ConstPoliceArial+ConstPoliceGras);
      end
    else
      begin
        PdfFontValue    := PdfDoc.AddFont(PdfCheminPolice('ariali.ttf'), ConstPoliceArial);
        PdfFontBold     := PdfDoc.AddFont(PdfCheminPolice('arialbd.ttf'), ConstPoliceArial+ConstPoliceGras);
      end;

    PdfSection.AddPage(PdfPage);
    PdfPage.PaperType:= ptA4;
    PdfPage.UnitOfMeasure := uomMillimeters;

    PdfFeldoImagesEntete(PDFDoc, PdfPage, DessinDebutHautEntete);
    if PdfStyle then
      begin
        PdfStyleEncre(PdfPage);
        PdfStyleCadrePage(PdfPage);
        PdfStylePied(PdfPage, Personnage.NomPersonnage + '  -  ' + FormatDateTime('dd/mm/yyyy', Now) + '  -  1 / 2');
      end;

    // Paramétrages : liste des compétences de la page 1
    ListPage       := TStringList.Create;

    // gérer les lignes
    // Écrire du texte sur la page PDF
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);

    // Entête
    PRace          := ChercheRace(Personnage.Race);
    LocData        := PdfFeldoMetiersAnciens(Personnage);
    PMetier        := ChercheMetier(Personnage.MetierEnCours.CodeMetier);
    PMetierNiveau  := ChercheMetierNiveau(Personnage.MetierEnCours.CodeMetier, Personnage.MetierEnCours.NiveauMetier);
    PRaceAttribut  := ChercheRaceAttribut(Personnage.Race, IfThen(ValVersion = 'WFRP2', 'RULES-ATTR_M', ConstCaracMouvement));
    Mouv           := StrToIntDef(PRaceAttribut.CalculRace, 0);
    // Modificateurs de toutes les sources possedees (collecteur unique, CONTEXT.md 2.105 etape c)
    Mouv           := Mouv + PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracMouvement)
                            + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracMouvement);

    Chance         := 0;
    Determine      := 0;
    For PRaceAttribut in ListRaceAttribut do
      if CompareRechercheValeur(Personnage.Race, PRaceAttribut.CodeRace) then
        case PRaceAttribut.CodeAttribut of
          ConstCaracDestin: Chance    := Chance    + StrToIntDef(PRaceAttribut.CalculRace,0);
          ConstCaracResil:  Determine := Determine + StrToIntDef(PRaceAttribut.CalculRace,0);
        end;
    for PersonnageAttribut in Personnage.CreationAttribut do
      case PersonnageAttribut.CodeAttribut of
        ConstCaracDestin: Chance    := Chance    + PersonnageAttribut.Valeur;
        ConstCaracResil:  Determine := Determine + PersonnageAttribut.Valeur;
      end;


    // chercher les Valeur d'attributs
    for Ind := 0 to 9 do
      begin
        PAttribut      := ListeAttribut[Ind];
        AttributDonnee := PdfPersonnageAttribut(Personnage, PAttribut.CodeAttribut, Bonus);
        val            := AttributDonnee.Total;
        case PAttribut.CodeAttribut of
          ConstCaracE:  BE  := Val;
          ConstCaracF:  BF  := Val;
          ConstCaracFM: BFM := Val;
        end;
      end;

    // chercher les talents et calculer les bonus correspondants - genericise le
    // 10/09/2026 (A FAIRE.txt "GENERICISER LE CASE DE CALCUL DES TALENTS") : plus de code
    // de talent en dur, PersonnageTalentEffet lit <Effet Cible="..."/> sur n'importe quel
    // talent (ChargeTalentEffet), creation et augmentation confondues. ValDurACuire (rang
    // brut affiche a cote du total sur ce gabarit) vient du meme mecanisme, via
    // PersonnageTalentEffetRang.
    DurACuire    := PersonnageTalentEffet(Personnage, ConstCibleEffetDurACuire);
    ValDurACuire := PersonnageTalentEffetRang(Personnage, ConstCibleEffetDurACuire);
    BonusBlessureFab := PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracBlessure)
                        + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracBlessure);
    BonusEncomb  := PersonnageTalentEffet(Personnage, ConstCibleEffetBonusEncomb);
    // Mighty Blow/Accurate Shot migres vers ModifyDamage le 11/09/2026, meme raison qu'au
    // dessus (PdfPersonnageCreation).
    TBonusCC     := PersonnageModificateurUnique(Personnage, ConstXmlModifieDegat, ConstCibleModifieDegatCC, '', True);
    TBonusCT     := PersonnageModificateurUnique(Personnage, ConstXmlModifieDegat, ConstCibleModifieDegatCT, '', True);
    BonusSprint  := PersonnageTalentEffet(Personnage, ConstCibleEffetBonusSprint);
    AmePure      := PersonnageTalentEffet(Personnage, ConstCibleEffetAmePure);
    // Talents portant <ModifyCarac name="RULES-ATTR_Fate"/"RULES-ATTR_Resil"> (ex. Luck/Chanceux
    // RULES-T0020, Strong-Minded/Obstiné RULES-T0107) - ajouté le 06/09/2026, remplace les cas
    // TalentChanceux/TalentObstine du case ci-dessus, même mécanisme que Mouvement (§2.50).
    Chance    := Chance    + PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracDestin)
                           + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracDestin);
    Determine := Determine + PersonnageModificateurUnique(Personnage, ConstXmlModifieAttribut, ConstCaracResil)
                           + SigneAstralAttributModif(Personnage.SigneAstral, Personnage.SigneAstralVariante, ConstCaracResil);

    // Paramétrages : liste des compétences
    ListPage       := TStringList.Create;
    PdfPersonnageCompetenceTri(ListPage);

    // Astérisques des mutations (CONTEXT.md §2.7, étape 9) - calculés tôt, avant le tableau
    // Caractéristiques qui en a besoin (contrairement aux armures, qui ne touchent que des
    // compétences et sont calculées plus tard, juste avant les tableaux de compétences).
    // Départ à Personnage.Asterisque (même baseline que les talents) ; les armures enchaînent
    // ensuite après AsterisqueFinalMutation, pour ne jamais réutiliser un numéro déjà pris.
    ListAsterisqueMutation := PdfPersonnageMutationAsterisques(Personnage, Personnage.Asterisque, AsterisqueParMutation, AsterisqueArmure, AsterisqueFinalMutation);
    // "(N)" de l'asterisque des fabrications sur les Blessures, capture apres sa creation, avant la liberation de
    // ListAsterisqueMutation.
    AnnotBlessure := Trim(ListAsterisqueMutation.Values[ConstCaracBlessure]);
    if Pos('(', AnnotBlessure) > 0 then
      AnnotBlessure := Copy(AnnotBlessure, Pos('(', AnnotBlessure), Length(AnnotBlessure))
    else
      AnnotBlessure := '';
    end;

  procedure PdfPage1;
    var
      Ind: Integer;
      PersonnageCorruption: StructurePersonnageCorruption;
    begin
    // Bloc Entête (extrait dans PdfBlocEntete, CONTEXT.md §2.4)
    DessinDebutHautCarac := PdfBlocEntete(PdfPage, Personnage, PRace, PMetier, PMetierNiveau, LocData,
      DessinDebColCompG, DessinFinEntete, DessinDebutHautEntete, DessinHauteurEntete,
      DessinNbLigEntete + Ord(Personnage.SigneAstral <> ''), MinPolice,
      AsterisqueParMutation.Values['SIGNE']) - 3;

    // Tableau Caractéristiques (extrait dans DessinerTableau / PdfPreparerRecordSetCaracteristiques, CONTEXT.md §2.4)
    TableauCarac := PdfFeldoTableauCaracteristiques(DessinDebColCompG, DessinDebutHautCarac, DessinHauteurCarac, DessinLargeurCarac);

    DonneesCarac := PdfPreparerRecordSetCaracteristiques(Personnage, PMetier, ListAsterisqueMutation);
    DessinDebutHautComp := DessinerTableau(PdfPage, TableauCarac, DonneesCarac) - 3;
    DessinDebutHautComg := DessinDebutHautComp;

    // Tableau Compétences de base (extrait dans DessinerTableau (orLigne) /
    // PdfPreparerRecordSetCompetencesBase, CONTEXT.md §2.4)
    TableauComp := PdfFeldoTableauCompetencesBase(DessinDebColCompG, DessinDebColG, DessinNbLigComp, MinPolice, DessinDebutHautComp, DessinLargeurComp, DessinHauteurComp);

    // Astérisques numérotées des malus d'armure sur les compétences (CONTEXT.md §2.5,
    // conception validée avec Nono le 15-16/08/2026) - calculées ici, avant les tableaux de
    // Compétences de la page 1, car Personnage.Equipement est disponible dès le départ (pas
    // besoin d'attendre que la page 2 soit dessinée). Libérée après le tableau des
    // compétences groupées, seul autre endroit où elle sert.
    // Enchaîne après AsterisqueFinalMutation (calculé plus haut) pour ne jamais réutiliser un
    // numéro déjà pris par une mutation à effet sur une caractéristique.
    ListAsterisqueArmure := PdfPersonnageArmureAsterisques(Personnage, AsterisqueFinalMutation, AsterisqueParEquipement, AsterisqueFinalArmure);
    // Numero des fabrications (runes) a cote de la piece, a la suite de celui d'un eventuel bonus d'armure.
    for Ind := 0 to AsterisqueParMutation.Count - 1 do
      if Copy(AsterisqueParMutation.Names[Ind], 1, 4) = 'FAB:' then
        AsterisqueParEquipement.Values[Copy(AsterisqueParMutation.Names[Ind], 5, MaxInt)] :=
          AsterisqueParEquipement.Values[Copy(AsterisqueParMutation.Names[Ind], 5, MaxInt)] + AsterisqueParMutation.ValueFromIndex[Ind];
    // Montures : la capacite de charge ne s'ajoute plus a l'Encombrement max (CONTEXT.md 2.84,
    // etape 4). Un objet confie a un animal (PortePar) compte 0 pour le personnage et s'ecrit
    // entre parentheses dans sa liste.

    // Fusionne les annotations de compétence des mutations (CONTEXT.md §2.7, étape 9) dans
    // ListAsterisqueArmure, seule TStringList lue par PdfPreparerRecordSetCompetencesBase/
    // Groupees (Values[Comp] concaténé à l'annotation existante) - Name=CodeAttribut restées
    // dans ListAsterisqueMutation (utilisées plus haut pour Caractéristiques) n'y trouvent
    // simplement jamais de correspondance côté compétence, sans effet de bord.
    For Ind := 0 to ListAsterisqueMutation.Count - 1 do
      ListAsterisqueArmure.Values[ListAsterisqueMutation.Names[Ind]] :=
        ListAsterisqueArmure.Values[ListAsterisqueMutation.Names[Ind]] + ListAsterisqueMutation.ValueFromIndex[Ind];

    DonneesComp := PdfPreparerRecordSetCompetencesBase(Personnage, PMetier, ListPage, ListAsterisqueArmure, TotalEsquive, TotalCalme, TotalResitance, TotalCommandement, TotalIntuition, ListPris);
    ListPage.Destroy;
    DessinDebutHautAmb := DessinerTableau(PdfPage, TableauComp, DonneesComp) - 3;

    // Bloc Ambitions deplace en page 2 le 27/09/2026 (a la demande de Nono, a cote du bloc
    // Montures/Navires) : la place qu'il occupait ici est desormais libre, Resilience/Destin/
    // Mouvement demarrent directement sous le tableau de Competences groupees.
    DessinDebutHautRes := DessinDebutHautAmb;
    DessinDebutHautDes := DessinDebutHautRes;

    // Bloc Résilience / Destin (extrait dans PdfBlocResilience / PdfBlocDestin, CONTEXT.md §2.4)
    // Réagencement du 16/08/2026 : Résilience/Destin raccourci (78mm -> 53mm) pour laisser
    // la place à Mouvement sur la même rangée (voir CONTEXT.md §2.6).
    PdfBlocResilience(PdfPage, Personnage, DessinDebColCompG, DessinDebutHautRes, DessinNbLigRes, DessinHauteurRes, MinPolice, Determine, IndC);
    PdfBlocDestin(PdfPage, Personnage, DessinDebColCompG + 27, DessinDebutHautDes, DessinHauteurDes, MinPolice, Chance);
    DessinDebutGaucheMou := DessinDebColCompG + 56;
    PdfBlocMouvement(PdfPage, DessinDebutGaucheMou, DessinDebutGaucheMou + DessinLargeurMou, DessinDebutHautRes, DessinHauteurMou, DessinNbLigMou + 1, MinPolice, Mouv, BonusSprint);

    // Bloc Expérience (extrait dans PdfBlocExperience, CONTEXT.md §2.4), sous Résilience/Destin.
    DessinDebutHautExp   := DessinDebutHautDes - (DessinNbLigRes * DessinHauteurDes) - 3;
    PdfBlocExperience(PdfPage, Personnage, DessinDebColCompG, DessinLargeurExp, DessinDebutHautExp, DessinHauteurExp, DessinNbLigExp + 1, MinPolice);

    // Bloc Corruption (extrait dans PdfBlocCorruption, CONTEXT.md §2.4), sous Expérience
    // (réagencement du 16/08/2026 : anciennement à côté d'Expérience/Mouvement, voir §2.6).
    // Lost/Left (16/08/2026) : somme de l'historique Personnage.Corruption, voir §2.6.
    LostCorruption := 0;
    for PersonnageCorruption in Personnage.Corruption do
      LostCorruption := LostCorruption + PersonnageCorruption.Montant;
    DessinDebutHautCor := DessinDebutHautExp - ((DessinNbLigExp + 1) * DessinHauteurExp) - 3;
    DessinLargeurCor   := DessinLargeurExp;
    PdfBlocCorruption(PdfPage, DessinDebColCompG, DessinLargeurCor, DessinDebutHautCor, DessinHauteurCor, DessinNbLigCor + 1, MinPolice, BE, BFM, AmePure, LostCorruption);
    // Bloc Richesse, sous Corruption (30/09/2026)
    PdfBlocRichesse(PdfPage, Personnage, DessinDebColCompG, DessinLargeurCor, DessinDebutHautCor - ((DessinNbLigCor + 1) * DessinHauteurCor) - 3, DessinHauteurCor, MinPolice);

    // Bloc Corruption Détail (extrait dans PdfBlocCorruptionDetail, CONTEXT.md §2.6) :
    // tableau Montant | Libellé, à droite d'Expérience/Corruption, dans l'espace libéré
    // par le réagencement du 16/08/2026. DessinLargeurExp sert ici de bord droit absolu
    // du panneau Expérience/Corruption (nom trompeur, comportement pré-existant conservé
    // tel quel) - le nouveau tableau démarre 3mm après. Hauteur calée pour finir au même
    // Y que le bas du panneau Corruption (NbLignes = 11, à ajuster si Bonus T/WP/etc change).
    DessinDebutGaucheCorDet := DessinLargeurExp + 3;
    PdfBlocCorruptionDetail(PdfPage, Personnage, DessinDebutGaucheCorDet, DessinFinColG, DessinDebutHautExp, DessinHauteurCorDet, DessinNbLigCorDet, MinPolice);

    // Tableau Compétences groupées (extrait dans DessinerTableau (orLigne) /
    // PdfPreparerRecordSetCompetencesGroupees, CONTEXT.md §2.4)
    // Répartition du budget de lignes Compétences groupées / Talents / Mutations (extraite dans PdfFeldoRepartitionPage1)
    PdfFeldoRepartitionPage1(Personnage, ListPris, DessinMinLignesVides, DessinNbLigComg, DessinNbLigTal, DessinNbLigMut);
    TableauCompG := PdfFeldoTableauCompetencesGroupees(DessinDebColD, DessinNbLigComg, MinPolice, DessinDebutHautComg, DessinLargeurComg, DessinHauteurComg);

    DonneesCompG := PdfPreparerRecordSetCompetencesGroupees(Personnage, ListPris, DessinNbLigComg - 2, ListAsterisqueArmure);
    // ListAsterisqueArmure et AsterisqueParEquipement libérées plus loin, après
    // PdfBlocArmuresDonnees (page 2) qui utilise encore la seconde
    DessinDebutHautTal := DessinerTableau(PdfPage, TableauCompG, DonneesCompG) - 3;

    // Bloc Talents (extrait dans PdfBlocTalents, CONTEXT.md §2.4)
    PdfBlocTalents(PdfPage, Personnage, DessinDebColD, DessinFinColCompD, DessinDebutHautTal, DessinHauteurTal, DessinNbLigTal, MinPolice);

    // Table des mutations obtenues (CONTEXT.md §2.7, étape 9) - sous les Talents, même largeur,
    // même écart de 3mm que partout ailleurs entre deux blocs. Capacité fixe à 3 lignes.
    // AsterisqueParMutation est encore vivant ici (libéré en fin de page 2).
    PdfBlocMutations(PdfPage, Personnage, DessinDebColD, DessinFinColCompD,
      DessinDebutHautTal - (DessinNbLigTal * DessinHauteurTal) - 3, DessinHauteurTal, DessinNbLigMut, MinPolice, AsterisqueParMutation);
    end;

  procedure PdfPage2;
    begin
   // PAGE 2
     PdfPage         := PDFDoc.Pages.AddPage;
     PdfSection.AddPage(PdfPage);
     PdfPage.PaperType:= ptA4;
     PdfPage.UnitOfMeasure := uomMillimeters;
     PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
     if PdfStyle then
       begin
         PdfStyleEncre(PdfPage);
         PdfStyleCadrePage(PdfPage);
         PdfStylePied(PdfPage, Personnage.NomPersonnage + '  -  ' + FormatDateTime('dd/mm/yyyy', Now) + '  -  2 / 2');
       end;
     // silhouette du bloc "Armour Points" (PdfBlocArmourPoints, ajouté le 15/08/2026,
     // CONTEXT.md §2.4) - chargée ici comme les autres images (Warhammer/Fantasy/
     // Ubersreik sur la page 1), l'identifiant est passé au bloc qui la dessine
     PdfImgShadow := PdfDoc.Images.AddFromFile(CheminImagePdf(GetCurrentDir+ConstCheminPdfShadow),false);
     // PASSE A BLANC (PDF "intelligent" page 2, A FAIRE 20/09/2026) : ArmureBonii/ArmeBonii/
     // FabricationBonii ne se construisent qu'en dessinant les données, or les cadres doivent
     // être dimensionnés avant. On rejoue donc les 3 blocs de données sur une page jetable :
     // créée par Pages.AddPage mais jamais ajoutée à PdfSection, elle n'est pas écrite dans le
     // PDF (fppdf n'écrit que les pages des sections). Ces blocs ne modifient ni Personnage ni
     // les listes d'astérisques ; leurs sorties (Enc*, Armure*, Bonii) sont remises à zéro par
     // les vrais appels plus bas, sauf FabricationBonii (cumulatif), remis à '' ci-dessous.
     PdfPageBlanc := PDFDoc.Pages.AddPage;
     PdfPageBlanc.PaperType := ptA4;
     PdfPageBlanc.UnitOfMeasure := uomMillimeters;
     // une page neuve n'a pas de police : les blocs de données écrivent avant d'en choisir une
     // (comme la vraie page 2, qui reçoit sa police juste après sa création)
     PdfTaillePolice(PdfPageBlanc, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
     FabricationBonii := '';
     PdfBlocDiversDonnees(PdfPageBlanc, Personnage, DessinDebColCompG, DessinLargeurEqu, DessinDebutHautEntete, DessinHauteurEqu, DessinNbLigEqu, EncDivers, MinPolice, FabricationBonii);
     PdfBlocArmesDonnees(PdfPageBlanc, Personnage, DessinDebColCompG, DessinLargeurWea, DessinDebutHautEntete, DessinHauteurWea, BF, TBonusCC, TBonusCT, FabricationBonii, EncArme, ArmeBonii, ArmureBouclier, MinPolice, AsterisqueParMutation);
     PdfBlocArmuresDonnees(PdfPageBlanc, Personnage, DessinDebColCompG, DessinLargeurArm, DessinDebutHautEntete, DessinHauteurArm, ArmureSet, FabricationBonii, EncArmure, ArmureBras, ArmureCorps, ArmureJambe, ArmureTete, ArmureBonii, MinPolice, AsterisqueParEquipement);
     NbLigExpl := PdfNbLignesExplication(ArmureBonii, ArmeBonii, FabricationBonii);
     FabricationBonii := '';
     // Répartition des lignes de la colonne gauche (option A, Nono 20/09/2026) : les Sorts sont
     // l'élément élastique (peu de personnages en ont). Ils gardent leur besoin + le minimum de
     // lignes vides (au moins 4, au plus leur taille par défaut). Le bloc d'explications, à droite
     // d'Armure + Équipement, impose une hauteur minimale à ces deux blocs (capacité = leurs lignes
     // + 2) ; ce qui reste est partagé entre Équipement et Armes.
     PdfFeldoRepartitionPage2(Personnage, ArmureSet, NbLigExpl, DessinMinLignesVides, DessinNbLigArm, DessinNbLigEqu, DessinNbLigWea, DessinNbLigSor);
     // la passe à blanc a déplacé la police globale : on la rétablit avant le vrai dessin
     PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
     // Dessin Armures (extrait dans PdfBlocArmures, CONTEXT.md §2.4 - cadre uniquement,
     // le remplissage des lignes reste plus bas, dans la boucle Equipement/Armes/Sorts)
     DessinDebutHautArm := DessinDebutHautEntete;
     PdfBlocArmures(PdfPage, DessinDebColCompG, DessinLargeurArm, DessinDebutHautArm, DessinHauteurArm, DessinNbLigArm);
     // Dessin Equipement (extrait dans PdfBlocEquipement, CONTEXT.md §2.4 - cadre uniquement)
     DessinDebutHautEqu := DessinDebutHautArm - ((DessinNbLigArm + 1) * DessinHauteurArm) - 3;
     PdfBlocEquipement(PdfPage, DessinDebColCompG, DessinLargeurEqu, DessinDebutHautEqu, DessinHauteurEqu, DessinNbLigEqu);
     // Dessin Armes (extrait dans PdfBlocArmes, CONTEXT.md §2.4 - cadre uniquement)
     DessinDebutHautWea := DessinDebutHautEqu - ((DessinNbLigEqu + 1) * DessinHauteurEqu) - 3;
     PdfBlocArmes(PdfPage, DessinDebColCompG, DessinLargeurWea, DessinDebutHautWea, DessinHauteurWea, DessinNbLigWea);
     // Dessin Sorts (extrait dans PdfBlocSorts, CONTEXT.md §2.4 - cadre uniquement)
     DessinDebutHautSor := DessinDebutHautWea - ((DessinNbLigWea + 1) * DessinHauteurWea) - 3;
     PdfBlocSorts(PdfPage, DessinDebColCompG, DessinLargeurSor, DessinDebutHautSor, DessinHauteurSor, DessinNbLigSor);
     // Encombrement (extrait dans PdfBlocEncombrement, CONTEXT.md §2.4 - cadre uniquement)
     DessinDebutHautEnc := DessinDebutHautSor - ((DessinNbLigSor + 1) * DessinHauteurSor) - 3;
     PdfBlocEncombrement(PdfPage, DessinDebColCompG, DessinLargeurEnc, DessinDebutHautEnc, DessinHauteurEnc, DessinNbLigEnc, MinPolice);

     // Dessin Sorts (extrait dans PdfBlocSortsDonnees, CONTEXT.md §2.4 - remplissage)
     PdfBlocSortsDonnees(PdfPage, Personnage, DessinDebColCompG, DessinDebutHautSor, DessinHauteurSor, MinPolice);
     // Dessin Divers (extrait dans PdfBlocDiversDonnees, CONTEXT.md §2.4 - remplissage)
     PdfBlocDiversDonnees(PdfPage, Personnage, DessinDebColCompG, DessinLargeurEqu, DessinDebutHautEqu, DessinHauteurEqu, DessinNbLigEqu, EncDivers, MinPolice, FabricationBonii);
     // Dessin Armes (extrait dans PdfBlocArmesDonnees, CONTEXT.md §2.4 - remplissage)
     PdfBlocArmesDonnees(PdfPage, Personnage, DessinDebColCompG, DessinLargeurWea, DessinDebutHautWea, DessinHauteurWea, BF, TBonusCC, TBonusCT, FabricationBonii, EncArme, ArmeBonii, ArmureBouclier, MinPolice, AsterisqueParMutation);
     // Dessin Armures (extrait dans PdfBlocArmuresDonnees, CONTEXT.md §2.4 - remplissage) -
     // dernière des 4 boucles, les 4 sont maintenant toutes extraites de la boucle partagée
     PdfBlocArmuresDonnees(PdfPage, Personnage, DessinDebColCompG, DessinLargeurArm, DessinDebutHautArm, DessinHauteurArm, ArmureSet, FabricationBonii, EncArmure, ArmureBras, ArmureCorps, ArmureJambe, ArmureTete, ArmureBonii, MinPolice, AsterisqueParEquipement);
     ListAsterisqueArmure.Destroy;
     AsterisqueParEquipement.Destroy;

        // Écrire du texte sur la page PDF
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 7);

    // Encombrement (extrait dans PdfFeldoEncombrement)
    PdfFeldoEncombrement(PdfPage, DessinDebColCompG, DessinLargeurEnc, DessinDebutHautEnc, DessinHauteurEnc, DessinNbLigEnc, EncArmure, EncArme, EncDivers, BF, BE, BonusEncomb);

    // Dessin Armour Points (nouveau bloc PdfBlocArmourPoints, CONTEXT.md §2.4 - cadre +
    // contenu) - positionné sous l'Encombrement, demandé par Nono le 15/08/2026.
    // Correction du 15/08/2026 (retour de Nono) : le calcul précédent oubliait le "+1"
    // que tous les autres blocs appliquent à leur nombre de lignes pour retrouver le bas
    // réel d'un cadre (voir PdfBlocEncombrement : bas = Y - ((NbLignes+1)*HauteurLigne))
    // - du coup le nouveau bloc démarrait quasiment collé sous l'Encombrement au lieu de
    // laisser un espace. Formule corrigée pour utiliser exactement le même "-3" que
    // partout ailleurs entre deux blocs (le même écart qu'entre Sorts et Encombrement) ;
    // (X,Y) passé au bloc est maintenant le coin HAUT-GAUCHE de son cadre, aligné sur
    // DessinDebColCompG comme tous les autres blocs de la page (au lieu d'un décalage de
    // 4mm vers la gauche par rapport au bloc Encombrement).
    DessinHautArmourPoints := DessinDebutHautEnc - ((DessinNbLigEnc + 1) * DessinHauteurEnc) - 3;
    PdfBlocArmourPoints(PdfPage, PdfImgShadow, DessinDebColCompG, DessinHautArmourPoints, ArmureTete, ArmureBras, ArmureCorps, ArmureJambe, ArmureBouclier, PersonnageFabricationModificateur(Personnage, ConstXmlModifieDegatRecu, '*'), AsterisqueArmure);

    // Le bloc Mutations est passé sur la page 1 (sous les Talents, 20/09/2026) : la place à
    // droite d'Armour Points (même bord gauche que l'ancien bloc Mutations, bord droit commun
    // avec Armure/Équipement, 84mm de haut comme le cadre d'Armour Points) reçoit les fiches
    // de montures.
    // Bloc Ambitions (personnage + groupe), deplace ici depuis la page 1 le 27/09/2026 a la
    // demande de Nono : demarre au meme Y qu'Armour Points, Montures/Navires est repousse sous
    // lui d'autant (HauteurMax reduit du meme montant pour ne pas depasser le bas commun avec
    // Armour Points).
    // Bord droit sur DessinLargeurWea (celui des Armes, 200) et non DessinLargeurArm (celui de
    // l'Armure/Montures, 128) : demande de Nono, la zone de texte doit aller aussi loin a
    // droite que le tableau des Armes au-dessus.
    DessinHautMontures := PdfBlocAmbitions(PdfPage, Personnage, DessinDebColCompG + 63 + 3, DessinLargeurWea, DessinHautArmourPoints, DessinHauteurAmb, MinPolice) - 3;
    PdfBlocMontures(PdfPage, Personnage, DessinDebColCompG + 63 + 3, DessinLargeurArm, DessinHautMontures, 84 - (5 * DessinHauteurAmb) - 3, MinPolice);
    // Dernière utilisation de ListAsterisqueMutation/AsterisqueParMutation sur cette page -
    // libérées ici (même moment que ListAsterisqueArmure/AsterisqueParEquipement, juste avant,
    // après leur dernier usage respectif).
    ListAsterisqueMutation.Destroy;
    AsterisqueParMutation.Destroy;

    // Dessin Blessure (extrait dans PdfBlocBlessure, CONTEXT.md §2.4)
    PdfBlocBlessure(PdfPage, Personnage, DessinLargeurEnc + 3, DessinLargeurEqu, DessinDebutHautEnc, DessinHauteurBle, DessinNbLigBle, MinPolice, BF, BE, BFM, DurACuire, ValDurACuire, BonusBlessureFab, AnnotBlessure);

    // Dessin Competences de combat (extrait dans PdfBlocCompetencesCombat, CONTEXT.md §2.4)
    PdfBlocCompetencesCombat(PdfPage, DessinLargeurEqu + 3, DessinLargeurComC, DessinDebutHautEnc, DessinHauteurComC, DessinNbLigComC, MinPolice, TotalEsquive, TotalCalme, TotalIntuition, TotalCommandement, TotalResitance);

    // Dessin Explication (extrait dans PdfBlocDessinExplication, CONTEXT.md §2.4 - cadre + contenu)
    // Police Arial 6 comme le PDF normal : sous Carlson gras 10 (police du bloc precedent),
    // PdfEcritTient reduisait les lignes jusqu'a une taille minuscule (signale le 30/09/2026).
    PdfTaillePolice(PdfPage, PdfFontValue, ConstPoliceArial, 6);
    PdfBlocDessinExplication(PdfPage, DessinLargeurArm, DessinLargeurWea, DessinDebutHautArm, DessinDebutHautWea, DessinHauteurExl, ArmureBonii, ArmeBonii, FabricationBonii);
    PdfTaillePolice(PdfPage, PdfFontBack, ConstPoliceCarlson+ConstPoliceGras, 10);
    end;

  begin
    PdfPreparation;
    PdfPage1;
    PdfPage2;
    PDFDoc.SaveToFile(PdfChemin);
    PDFDoc.Free;
    PdfPurgeAnciens(PdfChemin);
    PdfStyle   := False;
    PdfEconomie := False;
    PdfCouleur := True;
    ConstPoliceArial := 'Arial';

    if not PdfSansOuverture then
      OpenDocument(PdfChemin);
  end;


end.


unit ChargeCreationTow;

// The Old World, etape 4a : origine et caracteristiques de depart (Player's Guide p.12-13).
// Logique PURE (pas de fenetre) : testable par --towcreer, reutilisee ensuite par la fenetre de creation TOW.
//   1. Origine au choix, ou au d10 (table p.13) = +1 XP.
//   2. Caracteristiques de depart de l origine (9 : WS BS S T I Ag Re Fel Fate).
//   3. Trois fois « +1 » par d10 : 1 a 8 = WS BS S T I Ag Re Fel (ordre du livre), 9 = Fate,
//      10 = au choix (jamais une caracteristique deja augmentee). Doublon de 1-9 = on relance.
//      Maximum de l origine respecte. Si les trois +1 sont tires au hasard : +1 XP (ConserveHasard).

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, XMLRead, DOM, ChargePersonnage;

const
  TowNbCarac = 9;
  TowCodesCarac: array[1..TowNbCarac] of String = (
    'RULES-ATTR_WS', 'RULES-ATTR_BS', 'RULES-ATTR_S', 'RULES-ATTR_T', 'RULES-ATTR_I',
    'RULES-ATTR_Ag', 'RULES-ATTR_Re', 'RULES-ATTR_Fel', 'RULES-ATTR_Fate');

type
  // emplacements de lores : un emplacement = la liste des codes possibles (un seul si lore fixe)
  TTowSlots = array of array of String;
  TTowLigneD10 = record
    Code: String;
    De, A: Integer;
  end;

  TTowOrigine = record
    Code:        String;
    Libelle:     String;
    DeD10:       Integer;  // plage RandomRange
    AuD10:       Integer;
    Depart:      array[1..TowNbCarac] of Integer;
    Maximum:     array[1..TowNbCarac] of Integer;  // 0 = pas de maximum (Fate)
    // etape 4c : competences de depart de l origine
    CompFixes:   array of String;  // montees au rang CompRang
    CompRang:    Integer;
    CompLibres:  Integer;          // nombre de competences au choix montees au meme rang
    // etape 4d : lores et talents d origine
    LoreSlots:   TTowSlots;
    TalentTirages: Integer;        // nombre de d10
    Echange:     String;           // NONE / OPTIONAL / MANDATORY
    TalentEchange: String;
    TalentsFixes: array of String;
    TableTalents: array of TTowLigneD10;
    Noms:        String;           // « Suggested Names » du livre, separes par des virgules
  end;
  TTowOrigines = array of TTowOrigine;

// Lit toutes les origines de DATABASE\WFRPTOW\BOOK_*.Xml
function TowChargeOrigines(const Dossier: String): TTowOrigines;
function TowOrigineDeD10(const Origines: TTowOrigines; D10: Integer): Integer;
function TowIndexCarac(const Code: String): Integer;
// Evolution (Player's Guide p.66) : maximum de l origine (0 = aucun), caracteristique favorisee par la carriere, cout d une avance
function TowPlafondCarac(const Origine, Code: String): Integer;
function TowCaracFavorite(const Carriere, Code: String): Boolean;
function TowCoutCarac(Valeur: Integer; Favorite: Boolean): Integer;
procedure TowMarqueDes(var Rang, Ticks: Integer; Des: Integer);
function TowTalentCout(const Code: String): Integer;
// Nombre maximum d achats d un talent (balise MaxPurchases : absent = 1, 0 = sans limite, rendu 99)
function TowTalentMax(const Code: String): Integer;
// Codes des <Option> d un talent (Familiar : les 9 effets), a liberer par l appelant
function TowOptionsTalent(const Code: String): TStringList;
// Libelle d un choix a plusieurs valeurs separees par « ; » (« Flight, Linked »)
function TowLibelleChoix(const Choix: String): String;
// Effets deja pris (Ancien) + effets en attente (Nouveau) : union sans doublon, coupee a Max valeurs (Max <= 0 : pas de coupe)
function TowFusionneEffets(const Ancien, Nouveau: String; Max: Integer): String;
// Cout d un achat pour CE personnage : Wizard coute 1 XP de moins par niveau avec Touched by the Winds
function TowTalentCoutPerso(const P: StructurePersonnage; const Code: String): Integer;
function TowTalentManque(const P: StructurePersonnage; const Code: String): String;

// Personnage vide avec les caracteristiques de depart de l origine (Fate = Fortune = depart).
function TowCommencer(const O: TTowOrigine; const Nom: String): StructurePersonnage;

// Un seul +1 : Index 1..9 (9 = Fate). Faux si le maximum est atteint.
function TowAjouteUn(var P: StructurePersonnage; const O: TTowOrigine; Index: Integer): Boolean;

// Tire un d10 de modificateur : renvoie 1..10 sans doublon parmi 1-9 deja tires (Pris[1..9]).
// Si 10 sort, Choix (1..9) doit etre rempli par l appelant (ou -1 pour le choix automatique : premier libre).
function TowTireTroisPlus(var P: StructurePersonnage; const O: TTowOrigine; Deja: TStringList): Integer;

// ---- Etape 4b : carriere (table d100 p.25, plages par origine) ----
type
  TTowPlage = record
    Origine: String;   // code de l origine
    De, A:   Integer;  // 0 / 0 = choix libre possible mais pas tirable
  end;
  TTowCarriere = record
    Code:    String;
    Libelle: String;
    Status:  String;   // BRASS / SILVER / GOLD
    Plages:  array of TTowPlage;
    Favoris:   array of String;  // les 3 caracteristiques favorisees de la carriere
    CompChoix: array of String;  // les 6 competences candidates
    CompNb:    Integer;          // combien monter de +1 (4)
    LoreSlots: TTowSlots;
    TalentCarriere: String;      // nom du Career Talent (libelle)
    TalentCarriereTexte: String;
    Familles: array of String;   // etape 4e : familles de contacts (2)
    TrappingSlots: TTowSlots;    // etape 4f : equipement de depart (emplacements)
    AssetSlots: TTowSlots;       // etape 4f : atouts de depart (emplacements)
  end;
  TTowCarrieres = array of TTowCarriere;

function TowChargeCarrieres(const Dossier: String): TTowCarrieres;
// Versions chargees une seule fois pour les fenetres de consultation (WinRace, WinMetier)
function TowOriginesCache: TTowOrigines;
function TowCarrieresCache: TTowCarrieres;
// Libelle (anglais) d un code de DATABASE\WFRPTOW : competence, talent, lore, dieu... Code rendu tel quel si inconnu.
function TowLibelleDe(const Code: String): String;
// Texte explicatif du livre pour ce code (vide si aucun)
function TowExplicationDe(const Code: String): String;
// Index de la carriere dont la plage pour cette origine contient D100 (-1 si aucune)
function TowCarriereDeD100(const Carrieres: TTowCarrieres; const Origine: String; D100: Integer): Integer;
// La carriere est-elle accessible (au choix) pour cette origine ? Une plage « - » n est pas ecrite.
function TowCarriereAdmise(const C: TTowCarriere; const Origine: String): Boolean;
// Fixe la carriere : choix libre = pas d XP, tirage = +1 XP (a faire par l appelant)
procedure TowFixeCarriere(var P: StructurePersonnage; const C: TTowCarriere);
// Changement de carriere (Player's Guide p.133) : libelle du premier lore obligatoire de la carriere que le
// personnage n a pas (« A / B » si le livre propose l un ou l autre), vide si tous sont connus
function TowLoreManquant(const P: StructurePersonnage; const C: TTowCarriere): String;
// Atouts (codes) que la carriere offre au choix, tous emplacements confondus
function TowAtoutsCarriere(const C: TTowCarriere): TStringList;
// Applique le changement : nouvelle carriere et Status, talent de carriere, un atout perdu, un atout gagne.
// Talents, lores, equipement, contacts et rangs de competences ne changent pas.
procedure TowChangeCarriere(var P: StructurePersonnage; const C: TTowCarriere; const AtoutPerdu, AtoutGagne: String);

// ---- Etape 4c : competences (16, rang de depart 2, maximum 6) ----
const
  TowNbComp = 16;
  TowCodesComp: array[1..TowNbComp] of String = (
    'RULES-COMP_MELEE', 'RULES-COMP_DEFENCE', 'RULES-COMP_SHOOTING', 'RULES-COMP_THROWING',
    'RULES-COMP_BRAWN', 'RULES-COMP_TOIL', 'RULES-COMP_SURVIVAL', 'RULES-COMP_ENDURANCE',
    'RULES-COMP_AWARENESS', 'RULES-COMP_DEXTERITY', 'RULES-COMP_ATHLETICS', 'RULES-COMP_STEALTH',
    'RULES-COMP_WILLPOWER', 'RULES-COMP_RECALL', 'RULES-COMP_LEADERSHIP', 'RULES-COMP_CHARM');
  TowRangDepart = 2;
  TowRangMax    = 6;

// Les 16 competences au rang de depart (a appeler une fois, avant l origine)
procedure TowInitCompetences(var P: StructurePersonnage);
// Rang d une competence (0 si absente)
function TowRangComp(const P: StructurePersonnage; const Code: String): Integer;
// Origine : fixes au rang de l origine, puis CompLibres au choix (Libres = codes choisis ; manque = hasard
// parmi celles encore au rang de depart). Renvoie le nombre de choix completes au hasard.
function TowCompetencesOrigine(var P: StructurePersonnage; const O: TTowOrigine; Libres: TStringList): Integer;
// Carriere : +1 sur CompNb des 6 candidates (Choix = codes ; manque = hasard). Maximum respecte.
function TowCompetencesCarriere(var P: StructurePersonnage; const C: TTowCarriere; Choix: TStringList): Integer;

// ---- Etape 4d : lores, talents d origine, talent de carriere ----
// Un lore par emplacement : Choix[i] s il est valide pour l emplacement i, sinon hasard. Renvoie les tires au hasard.
function TowChoisitLores(var P: StructurePersonnage; const Slots: TTowSlots; Choix: TStringList): Integer;
// Talents d origine : fixes, TalentTirages jets d10 (doublons relances), echange. Echange : index (0..) du
// talent tire a remplacer ; -1 = automatique (OPTIONAL : aucun, MANDATORY : le dernier tire).
// Renvoie le nombre de relances.
function TowTalentsOrigine(var P: StructurePersonnage; const O: TTowOrigine; IndexEchange: Integer): Integer;
// Career Talent : ligne de talent « CAREER-TALENT:<code carriere> » (le texte reste dans le livre)
// Arcane Wizard / Hedge Wizard : talent Wizard niveau 1 (Precision = Magic Lore, sinon hasard) ;
// Priest : un rang de Faith (Precision = dieu, sinon hasard). Wizard et Faith s excluent.
procedure TowTalentCarriere(var P: StructurePersonnage; const C: TTowCarriere; const Precision: String = '');

const
  // Magic Lores et dieux proposes pour les precisions de talent (Wizard, Touched by the Winds, Faith)
  TowLoresMagie: array[0..3] of String = ('RULES-LORE_MAGIC_BATTLE_MAGIC', 'RULES-LORE_MAGIC_ELEMENTALISM',
    'RULES-LORE_MAGIC_ILLUSION', 'RULES-LORE_MAGIC_NECROMANCY');
  TowDieux: array[0..9] of String = ('RULES-GOD_ULRIC', 'RULES-GOD_TAAL', 'RULES-GOD_RHYA', 'RULES-GOD_SIGMAR',
    'RULES-GOD_MANANN', 'RULES-GOD_MORR', 'RULES-GOD_RANALD', 'RULES-GOD_VERENA', 'RULES-GOD_MYRMIDIA',
    'RULES-GOD_SHALLYA');

// ---- Etape 4e : contacts (p.57) : deux jets d100 sur les tables de la carriere ----
type
  TTowRelation = record
    Famille: String;   // code de la famille de contacts
    Npc:     String;   // nom du PNJ
    Texte:   String;   // la relation
    De, A:   Integer;  // plage d100
  end;
  TTowRelations = array of TTowRelation;

// Lit les 80 relations de DATA_CONTACT dans DATABASE\WFRPTOW\BOOK_*.Xml
function TowChargeRelations(const Dossier: String): TTowRelations;
// Deux contacts : Choix = -1 un jet sur chaque table de la carriere, 0 ou 1 = deux jets sur cette famille.
// Un PNJ deja tire est relance. Renvoie le nombre de relances.
function TowTireContacts(var P: StructurePersonnage; const C: TTowCarriere; const Rel: TTowRelations;
  Choix: Integer): Integer;

// ---- Etape 4f : equipement, atouts, sorts de depart, Life in Disgrace, dernier bonus (p.61) ----
type
  TTowAtoutAleatoire = record
    De, A: Integer;
    Brass, Silver, Gold: String;   // codes d atouts de la table p.61
  end;
  TTowAtoutsAleatoires = array of TTowAtoutAleatoire;
  TTowSort = record
    Code, Lore: String;
  end;
  TTowSorts = array of TTowSort;

// Trappings « (choose one) » : armes du livre qui conviennent a une entree generique (« Silver weapon », « Silver melee
// weapon », « Brass or Silver melee weapon » : Status Brass ou Silver, melee seulement pour les deux derniers).
// Liste vide si le code n est pas un generique d arme. L appelant libere la liste.
// Aussi pour « Trade tools (match your Trade Lore) » : les outils de metier (categorie TRADE_TOOLS) dont le Lore requis
// est l un des lores de TowLoresPerso ; aucun ne correspond = tous les outils.
function TowArmesPour(const Generique: String): TStringList;
// Lore generique « (specify) » : codes qui peuvent la preciser (options du livre, sinon lores de la meme famille,
// les 4 ecoles pour Magic Lore). Liste vide = precision libre, non proposee. L appelant libere la liste.
function TowPrecisionsLore(const Generique: String): TStringList;
function TowLoreDuDieu(const Dieu: String): String;
procedure TowLoreFavorite(var P: StructurePersonnage);
// Vrai si ce code d emplacement est une lore generique « (specify) » avec des precisions proposees
function TowLoreGenerique(const Code: String): Boolean;
// Study Lore (Player's Guide p.136) : codes des lores que le perso ne connait pas encore (lores concretes du livre
// et precisions des lores generiques). Le test de l Endeavour se joue a la table. L appelant libere la liste.
function TowLoresApprenables(const P: StructurePersonnage): TStringList;
var
  // lore precisee pour chaque emplacement de lore (comme TowLoreChoix) ; '' = emplacement « (specify) » laisse generique
  TowLorePrecis: array of String;
  TowLoresPerso: array of String;   // codes des lores du perso (renseigne par la fenetre avant TowArmesPour)
  // arme nommee pour chaque emplacement d equipement (comme TowEqChoix) ; '' = hasard parmi les armes qui conviennent
  TowEqPrecis: array of String;

// Un objet (trapping) / un atout par emplacement de la carriere ; choix manquant = hasard. Renvoie les tires au hasard.
function TowChoisitEquipement(var P: StructurePersonnage; const Slots: TTowSlots; Choix: TStringList): Integer;
function TowChoisitAtouts(var P: StructurePersonnage; const Slots: TTowSlots; Choix: TStringList): Integer;
function TowChargeAtoutsAleatoires(const Dossier: String): TTowAtoutsAleatoires;
function TowChargeSorts(const Dossier: String): TTowSorts;
// Arcane Wizard : 3 sorts de la Magic Lore du Wizard, en grimoire (FORMALISED) ; Hedge Wizard : memorises (MEMORISED).
procedure TowSortsDepart(var P: StructurePersonnage; const Sorts: TTowSorts; const C: TTowCarriere);
// Life in Disgrace : Status d un cran plus bas (impossible en Brass). Renvoie les XP gagnes (1) ou 0.
function TowVieEnDisgrace(var P: StructurePersonnage): Integer;
// Final Steps : Mode 1 = competences (3 -> 4, ou deux 2 -> 3), 2 = un talent de plus sur la table de l origine,
// 3 = atout aleatoire de la colonne du Status (Paye = 1 XP depense pour monter d un cran). Mode 0 = au hasard.
// Renvoie le mode applique.
function TowDernierBonus(var P: StructurePersonnage; const O: TTowOrigine; const Table: TTowAtoutsAleatoires;
  Mode: Integer; Paye: Boolean): Integer;
var
  // resultat de de deja lance, pour le dernier bonus : 0 = tirer au hasard (d10 du talent de plus, d100 de l atout)
  TowJetTalentFinal: Integer = 0;
  TowJetAtoutFinal:  Integer = 0;

// Assemble le personnage depuis les choix faits dans la fenetre de creation (rien n est tire sauf ce qui manque).
// Plus = 9 drapeaux (+1 par caracteristique) ; LoreChoix = lores de l origine puis de la carriere ;
// TalTires / TalEchange = talents tires au d10 et index remplace (-1 = aucun) ; Bonus 0 = hasard.
// Debut du personnage (phases 1 a 3) : origine, caracteristiques de depart + les trois +1, carriere.
// Pose dans P seulement ces champs (le reste de P est laisse tel quel), comme les phases V1-V5.
procedure TowPoseDebut(var P: StructurePersonnage; const O: TTowOrigine; const C: TTowCarriere; AvecCarriere: Boolean;
  const Plus: array of Integer);
procedure TowPoseTalents(var P: StructurePersonnage; const O: TTowOrigine; const TalTires: array of String; TalEchange: Integer);
procedure TowPoseCompetences(var P: StructurePersonnage; const O: TTowOrigine; const C: TTowCarriere; AvecCarriere: Boolean;
  const Libres, CompCar, LoreChoix: array of String);
// Phases 7 et 8 : talent de carriere, contacts, equipement, sorts, dernier bonus, a partir d un P deja pose.
procedure TowPoseEquipement(var P: StructurePersonnage; const C: TTowCarriere;
  const EqChoix, AtChoix, ContFam, ContNpc, ContTxt, SortsCodes: array of String;
  const PrecCarriere: String; const Sorts: TTowSorts);
procedure TowPoseFin(var P: StructurePersonnage; const O: TTowOrigine; const Nom: String;
  const Table: TTowAtoutsAleatoires; Disgrace: Boolean; Bonus: Integer; PayeBonus: Boolean);
function TowAssemble(const O: TTowOrigine; const C: TTowCarriere; const Nom: String; const Plus: array of Integer;
  const Libres, CompCar, TalTires, LoreChoix, EqChoix, AtChoix, ContFam, ContNpc, ContTxt, SortsCodes: array of String;
  TalEchange: Integer; const PrecCarriere: String; const Sorts: TTowSorts; const Table: TTowAtoutsAleatoires;
  Disgrace: Boolean; Bonus: Integer; PayeBonus: Boolean): StructurePersonnage;

// Lignes propres a TOW dans StructurePersonnage (atouts / contacts = LignesTow, sorts = Equipement de type sort)
procedure TowAjouteLigne(var P: StructurePersonnage; const Genre, Code, Famille, Texte: String);
function TowAjouteEquip(var P: StructurePersonnage; const Code, Texte: String): Integer;
// Objet (arme / armure) que donne un atout : balise GrantsItem de l Asset du livre, '' si aucun
function TowObjetDeAsset(const CodeAsset: String): String;
// Objets donnes par les atouts du perso (non enregistres, recalcules comme les objets de mutation) ;
// Source = code de l atout, TypeEquipement = arme ou armure selon le catalogue
function TowEquipementAssets(const P: StructurePersonnage): TArrayPersonnageEquipement;
function TowAjouteSort(var P: StructurePersonnage; const Code, Texte: String): Integer;
function TowIndexSort(const P: StructurePersonnage; N: Integer): Integer;
function TowNbSorts(const P: StructurePersonnage): Integer;
function PersonnageTowDump(const P: StructurePersonnage): TStringList;
// Fixe l XP total en gardant l XP deja depense (XP depense = XpTotal - XpActuel)
procedure TowFixeXp(var P: StructurePersonnage; Total: Integer);

implementation

uses ChargeTalent, ChargeCompetence, ChargeArme, ChargeArmure, ChargeConstantes;

procedure TowFixeXp(var P: StructurePersonnage; Total: Integer);
  var Depense: Integer;
  begin
    Depense := P.XpTotal - P.XpActuel;
    P.XpTotal  := Total;
    P.XpActuel := Total - Depense;
  end;

// Les livres TOW (DATABASE/WFRPTOW/BOOK_*.Xml) sont lus UNE SEULE FOIS ; tous les chargeurs partent de ces documents.
var
  LivresDossier: String = '';
  LivresDocs: array of TXMLDocument;

procedure TowOuvreLivres(const Dossier: String);
  var
    Rech: TSearchRec;
    D:    String;
    Doc:  TXMLDocument;
    I:    Integer;
  begin
    D := IncludeTrailingPathDelimiter(Dossier);
    if (LivresDossier = D) and (Length(LivresDocs) > 0) then Exit;
    for I := 0 to High(LivresDocs) do LivresDocs[I].Free;
    SetLength(LivresDocs, 0);
    LivresDossier := D;
    if FindFirst(D + 'BOOK_*.Xml', faAnyFile, Rech) <> 0 then Exit;
    try
      repeat
        Doc := nil;
        ReadXMLFile(Doc, D + Rech.Name);
        SetLength(LivresDocs, Length(LivresDocs) + 1);
        LivresDocs[High(LivresDocs)] := Doc;
      until FindNext(Rech) <> 0;
    finally
      FindClose(Rech);
    end;
  end;

function TowNbLivres: Integer;
  begin
    Result := Length(LivresDocs);
  end;

function TowLivreDoc(Index: Integer): TXMLDocument;
  begin
    Result := LivresDocs[Index];
  end;

function Chaine(Noeud: TDOMNode; const Nom: String): String;
  var E: TDOMNode;
  begin
    Result := '';
    E := Noeud.FirstChild;
    while E <> nil do
      begin
        if (E.NodeType = ELEMENT_NODE) and (E.NodeName = Nom) then
          begin
            Result := Trim(E.TextContent);
            if (Length(Result) >= 2) and (Result[1] = '"') then
              Result := Copy(Result, 2, Length(Result) - 2);
            Exit;
          end;
        E := E.NextSibling;
      end;
  end;

function TowIndexCarac(const Code: String): Integer;
  var I: Integer;
  begin
    Result := 0;
    for I := 1 to TowNbCarac do
      if TowCodesCarac[I] = Code then
        begin
          Result := I;
          Exit;
        end;
  end;

var
  CacheTalentCout: TStringList = nil;   // code du talent = cout en XP
  CacheTalentExig: TStringList = nil;   // code du talent = exigences « type:nom=valeur » separees par « ; »
  CacheTalentMax:  TStringList = nil;   // code du talent = nombre maximum d achats (MaxPurchases)
  CacheTalentOpt:  TStringList = nil;   // code du talent = codes de ses <Option> separes par « ; » (Familiar : les 9 effets)

procedure TowChargeLibellesCache; forward;

// Evolution (Player's Guide p.66) : maximum de l origine pour cette caracteristique (0 = aucun)
function TowPlafondCarac(const Origine, Code: String): Integer;
  var
    Origines: TTowOrigines;
    I, K:     Integer;
  begin
    Result := 0;
    K := TowIndexCarac(Code);
    if K = 0 then Exit;
    Origines := TowOriginesCache;
    for I := 0 to High(Origines) do
      if Origines[I].Code = Origine then
        Exit(Origines[I].Maximum[K]);
  end;

// La caracteristique est-elle favorisee par cette carriere (cout de l avance reduit de 1) ?
function TowCaracFavorite(const Carriere, Code: String): Boolean;
  var
    Carrieres: TTowCarrieres;
    I, J:      Integer;
  begin
    Result := False;
    Carrieres := TowCarrieresCache;
    for I := 0 to High(Carrieres) do
      if Carrieres[I].Code = Carriere then
        begin
          for J := 0 to High(Carrieres[I].Favoris) do
            if Carrieres[I].Favoris[J] = Code then
              Exit(True);
          Exit;
        end;
  end;

// XP pour porter une caracteristique a Valeur : Valeur, moins 1 si favorisee
function TowCoutCarac(Valeur: Integer; Favorite: Boolean): Integer;
  begin
    Result := Valeur;
    if Favorite then Dec(Result);
    if Result < 0 then Result := 0;
  end;

// Des rates marques sur la piste d une competence : quand elle depasse le rang, le rang monte de 1 (maximum 6),
// la piste repart a zero et le surplus est perdu. Au maximum, la piste reste au plus au rang.
procedure TowMarqueDes(var Rang, Ticks: Integer; Des: Integer);
  begin
    Ticks := Ticks + Des;
    if Ticks > Rang then
      if Rang < TowRangMax then
        begin
          Inc(Rang);
          Ticks := 0;
        end
      else
        Ticks := Rang;
  end;

// Cout en XP d un talent (balise Cost du livre), 0 si inconnu
function TowTalentCout(const Code: String): Integer;
  begin
    TowChargeLibellesCache;
    Result := StrToIntDef(CacheTalentCout.Values[Code], 0);
  end;

function TowTalentMax(const Code: String): Integer;
  begin
    TowChargeLibellesCache;
    Result := StrToIntDef(CacheTalentMax.Values[Code], 1);
    if Result <= 0 then Result := 99;
    // Familiar (9 achats, un effet a choisir a chaque achat) : le choix est fait par TowChoixFamiliar (winpersonnage.pas)
    if (Result > 1) and (Code <> 'RULES-T_WIZARD') and (Code <> 'RULES-T_FAITH') and (Code <> 'RULES-T_FAMILIAR') then Result := 1;
  end;

// Codes des <Option> d un talent (Familiar : les effets), dans l ordre du livre
function TowOptionsTalent(const Code: String): TStringList;
  var I: Integer;
  begin
    TowChargeLibellesCache;
    Result := TStringList.Create;
    Result.Delimiter := ';';
    Result.StrictDelimiter := True;
    Result.DelimitedText := CacheTalentOpt.Values[Code];
    for I := Result.Count - 1 downto 0 do
      if Result[I] = '' then Result.Delete(I);
  end;

function TowFusionneEffets(const Ancien, Nouveau: String; Max: Integer): String;
  var
    L, N: TStringList;
    I: Integer;
  begin
    L := TStringList.Create;
    N := TStringList.Create;
    try
      L.Delimiter := ';';
      L.StrictDelimiter := True;
      L.DelimitedText := Ancien;
      N.Delimiter := ';';
      N.StrictDelimiter := True;
      N.DelimitedText := Nouveau;
      for I := L.Count - 1 downto 0 do
        if L[I] = '' then L.Delete(I);
      for I := 0 to N.Count - 1 do
        if (N[I] <> '') and (L.IndexOf(N[I]) < 0) then L.Add(N[I]);
      while (Max > 0) and (L.Count > Max) do L.Delete(L.Count - 1);
      Result := L.DelimitedText;
    finally
      L.Free;
      N.Free;
    end;
  end;

// Libelle d un choix a plusieurs valeurs separees par « ; » (effets de Familiar) : « Flight, Linked »
function TowLibelleChoix(const Choix: String): String;
  var
    L: TStringList;
    I: Integer;
  begin
    Result := '';
    L := TStringList.Create;
    try
      L.Delimiter := ';';
      L.StrictDelimiter := True;
      L.DelimitedText := Choix;
      for I := 0 to L.Count - 1 do
        if L[I] <> '' then
          begin
            if Result <> '' then Result := Result + ', ';
            Result := Result + TowLibelleDe(L[I]);
          end;
    finally
      L.Free;
    end;
  end;

function TowTalentCoutPerso(const P: StructurePersonnage; const Code: String): Integer;
  var
    I:     Integer;
    Touche: Boolean;
  begin
    Result := TowTalentCout(Code);
    // Touched by the Winds : le talent Wizard coute 1 XP de moins a chaque niveau (Player's Guide p.81)
    if (Code = 'RULES-T_WIZARD') and (Result > 0) then
      begin
        Touche := False;
        for I := 0 to High(P.CreationTalent) do
          if P.CreationTalent[I].CodeTalent = 'RULES-T_TOUCHED_BY_THE_WINDS' then Touche := True;
        for I := 0 to High(P.AugmentationTalent) do
          if (P.AugmentationTalent[I].CodeTalent = 'RULES-T_TOUCHED_BY_THE_WINDS') and (P.AugmentationTalent[I].Valeur > 0) then Touche := True;
        if Touche then Dec(Result);
      end;
  end;

// Premiere exigence du talent que le personnage ne remplit pas (texte lisible), '' si toutes sont remplies.
// ITEM n est pas controle (a la discretion du MJ : l objet peut etre acquis plus tard) ; STATUS compare le Status de depart.
function TowTalentManque(const P: StructurePersonnage; const Code: String): String;
  var
    Liste:      TStringList;
    I, K, Egal: Integer;
    Ligne, Type_, Nom, Val: String;
    Valeur:     Integer;
    Trouve:     Boolean;
  begin
    Result := '';
    TowChargeLibellesCache;
    // Wizard et Faith s excluent (Player's Guide p.75 et p.81), creation ou evolution
    if (Code = 'RULES-T_FAITH') or (Code = 'RULES-T_WIZARD') then
      begin
        if Code = 'RULES-T_FAITH' then Nom := 'RULES-T_WIZARD' else Nom := 'RULES-T_FAITH';
        for K := 0 to High(P.CreationTalent) do
          if P.CreationTalent[K].CodeTalent = Nom then Exit(TowLibelleDe(Nom));
        for K := 0 to High(P.AugmentationTalent) do
          if (P.AugmentationTalent[K].CodeTalent = Nom) and (P.AugmentationTalent[K].Valeur > 0) then Exit(TowLibelleDe(Nom));
      end;
    Liste := TStringList.Create;
    try
      Liste.Delimiter := ';';
      Liste.StrictDelimiter := True;
      Liste.DelimitedText := CacheTalentExig.Values[Code];
      for I := 0 to Liste.Count - 1 do
        begin
          Ligne := Liste[I];
          K     := Pos(':', Ligne);
          Egal  := Pos('=', Ligne);
          if (K = 0) or (Egal = 0) then Continue;
          Type_ := Copy(Ligne, 1, K - 1);
          Nom   := Copy(Ligne, K + 1, Egal - K - 1);
          Val   := Copy(Ligne, Egal + 1, 99);
          if Type_ = 'ATTR' then
            begin
              Valeur := 0;
              for K := 0 to High(P.CreationAttribut) do
                if P.CreationAttribut[K].CodeAttribut = Nom then Valeur := Valeur + P.CreationAttribut[K].Valeur;
              for K := 0 to High(P.AugmentationAttribut) do
                if P.AugmentationAttribut[K].CodeAttribut = Nom then Valeur := Valeur + P.AugmentationAttribut[K].Valeur;
              if Valeur < StrToIntDef(Val, 0) then
                Exit(TowLibelleDe(Nom) + ' ' + Val + '+');
            end
          else if Type_ = 'ORIGIN' then
            begin
              if P.Race <> Nom then Exit(TowLibelleDe(Nom));
            end
          else if Type_ = 'ORIGIN_NOT' then
            begin
              if P.Race = Nom then Exit(TowLibelleDe(Nom));
            end
          else if Type_ = 'LORE' then
            begin
              // « RULES-LORE_MAGIC__* » = n importe quelle Magic Lore (prefixe avant l etoile)
              Trouve := False;
              if (Nom <> '') and (Nom[Length(Nom)] = '*') then
                begin
                  Nom := Copy(Nom, 1, Length(Nom) - 1);
                  while (Nom <> '') and (Nom[Length(Nom)] = '_') do Nom := Copy(Nom, 1, Length(Nom) - 1);
                  for K := 0 to High(P.LoresTow) do
                    if Pos(Nom, P.LoresTow[K].Code) = 1 then Trouve := True;
                end
              else
                for K := 0 to High(P.LoresTow) do
                  if P.LoresTow[K].Code = Nom then Trouve := True;
              if not Trouve then Exit(TowLibelleDe(Nom));
            end
          else if Type_ = 'TALENT' then
            begin
              Trouve := False;
              for K := 0 to High(P.CreationTalent) do
                if P.CreationTalent[K].CodeTalent = Nom then Trouve := True;
              for K := 0 to High(P.AugmentationTalent) do
                if P.AugmentationTalent[K].CodeTalent = Nom then Trouve := True;
              if not Trouve then Exit(TowLibelleDe(Nom));
            end
          else if Type_ = 'STATUS' then
            begin
              if (Val = 'SILVER_OR_GOLD') and (P.StatusTow = 'BRASS') then Exit(Val);
            end;
        end;
    finally
      Liste.Free;
    end;
  end;

function Sans(const S: String): String;
  begin
    Result := S;
    if (Length(Result) >= 2) and (Result[1] = '"') then
      Result := Copy(Result, 2, Length(Result) - 2);
  end;

procedure LitCaracs(Noeud: TDOMNode; var Tab: array of Integer);
  var A: TDOMNode; I: Integer;
  begin
    if Noeud = nil then Exit;
    A := Noeud.FirstChild;
    while A <> nil do
      begin
        if (A.NodeType = ELEMENT_NODE) and (A.NodeName = 'Attribut') then
          begin
            I := TowIndexCarac(TDOMElement(A).GetAttribute('name'));
            if I > 0 then Tab[I - 1] := StrToIntDef(Sans(Trim(A.TextContent)), 0);
          end;
        A := A.NextSibling;
      end;
  end;

procedure LitCompOrigine(Noeud: TDOMNode; var O: TTowOrigine);
  var A: TDOMNode;
  begin
    A := Noeud.FirstChild;
    while A <> nil do
      begin
        if A.NodeType = ELEMENT_NODE then
          begin
            if A.NodeName = 'Skill' then
              begin
                SetLength(O.CompFixes, Length(O.CompFixes) + 1);
                O.CompFixes[High(O.CompFixes)] := TDOMElement(A).GetAttribute('name');
                O.CompRang := StrToIntDef(Sans(Trim(A.TextContent)), 0);
              end
            else if A.NodeName = 'SkillFree' then
              O.CompLibres := StrToIntDef(Sans(Trim(A.TextContent)), 0);
          end;
        A := A.NextSibling;
      end;
    // Empire : seulement des libres, le rang est celui du livre (3)
    if (O.CompRang = 0) and (O.CompLibres > 0) then O.CompRang := 3;
  end;

procedure LitCompCarriere(Noeud: TDOMNode; var C: TTowCarriere);
  var A: TDOMNode;
  begin
    A := Noeud.FirstChild;
    while A <> nil do
      begin
        if A.NodeType = ELEMENT_NODE then
          begin
            if A.NodeName = 'Skill' then
              begin
                SetLength(C.CompChoix, Length(C.CompChoix) + 1);
                C.CompChoix[High(C.CompChoix)] := TDOMElement(A).GetAttribute('name');
              end
            else if A.NodeName = 'SkillPick' then
              C.CompNb := StrToIntDef(Sans(Trim(A.TextContent)), 0);
          end;
        A := A.NextSibling;
      end;
  end;

procedure LitSlots(Noeud: TDOMNode; const NomSlot: String; var Slots: TTowSlots);
  var A, Op: TDOMNode; K: Integer;
  begin
    A := Noeud.FirstChild;
    while A <> nil do
      begin
        if (A.NodeType = ELEMENT_NODE) and (A.NodeName = NomSlot) then
          begin
            SetLength(Slots, Length(Slots) + 1);
            Op := A.FirstChild;
            while Op <> nil do
              begin
                if (Op.NodeType = ELEMENT_NODE) and (Op.NodeName = 'Option') then
                  begin
                    K := Length(Slots[High(Slots)]);
                    SetLength(Slots[High(Slots)], K + 1);
                    Slots[High(Slots)][K] := TDOMElement(Op).GetAttribute('name');
                  end;
                Op := Op.NextSibling;
              end;
          end;
        A := A.NextSibling;
      end;
  end;

procedure LitTalentsOrigine(Noeud: TDOMNode; var O: TTowOrigine);
  var A: TDOMNode; V: String; P: Integer; L: TTowLigneD10;
  begin
    A := Noeud.FirstChild;
    while A <> nil do
      begin
        if A.NodeType = ELEMENT_NODE then
          begin
            V := Sans(Trim(A.TextContent));
            if A.NodeName = 'TalentRolls' then O.TalentTirages := StrToIntDef(V, 0)
            else if A.NodeName = 'SwapMode' then O.Echange := V
            else if A.NodeName = 'SwapTalent' then O.TalentEchange := V
            else if A.NodeName = 'FixedTalent' then
              begin
                SetLength(O.TalentsFixes, Length(O.TalentsFixes) + 1);
                O.TalentsFixes[High(O.TalentsFixes)] := V;
              end
            else if A.NodeName = 'Roll' then
              begin
                L.Code := TDOMElement(A).GetAttribute('name');
                P := Pos('-', V);
                if P > 0 then
                  begin
                    L.De := StrToIntDef(Copy(V, 1, P - 1), 0);
                    L.A := StrToIntDef(Copy(V, P + 1, 9), 0);
                  end
                else
                  begin
                    L.De := StrToIntDef(V, 0);
                    L.A := L.De;
                  end;
                SetLength(O.TableTalents, Length(O.TableTalents) + 1);
                O.TableTalents[High(O.TableTalents)] := L;
              end;
          end;
        A := A.NextSibling;
      end;
  end;

function TowChargeOrigines(const Dossier: String): TTowOrigines;
  var
    IL:   Integer;
    Doc:   TXMLDocument;
    Liste, N, Sub: TDOMNode;
    O:     TTowOrigine;
    Plage: String;
    P:     Integer;
    Dep, Max: array[0..TowNbCarac - 1] of Integer;
    I, K:  Integer;
  begin
    SetLength(Result, 0);
    TowOuvreLivres(IncludeTrailingPathDelimiter(Dossier));
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              if (Liste.NodeType = ELEMENT_NODE) and (Liste.NodeName = 'DATA_ORIGIN') then
                begin
                  N := Liste.FirstChild;
                  while N <> nil do
                    begin
                      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Origin') then
                        begin
                          O := Default(TTowOrigine);
                          O.Code := TDOMElement(N).GetAttribute('id');
                          O.Libelle := Chaine(N, 'Description');
                          O.Noms := Chaine(N, 'Names');
                          Plage := Chaine(N, 'RandomRange');
                          P := Pos('-', Plage);
                          if P > 0 then
                            begin
                              O.DeD10 := StrToIntDef(Copy(Plage, 1, P - 1), 0);
                              O.AuD10 := StrToIntDef(Copy(Plage, P + 1, 9), 0);
                            end
                          else
                            begin
                              O.DeD10 := StrToIntDef(Plage, 0);
                              O.AuD10 := O.DeD10;
                            end;
                          for K := 0 to TowNbCarac - 1 do begin Dep[K] := 0; Max[K] := 0; end;
                          Sub := N.FirstChild;
                          while Sub <> nil do
                            begin
                              if Sub.NodeName = 'SUBCHAPTER_ATTR' then LitCaracs(Sub, Dep);
                              if Sub.NodeName = 'SUBCHAPTER_MAX' then LitCaracs(Sub, Max);
                              if Sub.NodeName = 'SUBCHAPTER_SKILL' then LitCompOrigine(Sub, O);
                              if Sub.NodeName = 'SUBCHAPTER_LORE' then LitSlots(Sub, 'LoreSlot', O.LoreSlots);
                              if Sub.NodeName = 'SUBCHAPTER_TALENT' then LitTalentsOrigine(Sub, O);
                              Sub := Sub.NextSibling;
                            end;
                          for I := 1 to TowNbCarac do
                            begin
                              O.Depart[I] := Dep[I - 1];
                              O.Maximum[I] := Max[I - 1];
                            end;
                          SetLength(Result, Length(Result) + 1);
                          Result[High(Result)] := O;
                        end;
                      N := N.NextSibling;
                    end;
                end;
              Liste := Liste.NextSibling;
            end;
  end;
  end;

function TowChargeCarrieres(const Dossier: String): TTowCarrieres;
  var
    IL:   Integer;
    Doc:   TXMLDocument;
    Liste, N, Sub, Ori, A: TDOMNode;
    C:     TTowCarriere;
    Plage: String;
    P:     Integer;
    Pl:    TTowPlage;
  begin
    SetLength(Result, 0);
    TowOuvreLivres(IncludeTrailingPathDelimiter(Dossier));
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              if (Liste.NodeType = ELEMENT_NODE) and (Liste.NodeName = 'DATA_CAREER') then
                begin
                  N := Liste.FirstChild;
                  while N <> nil do
                    begin
                      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Career') then
                        begin
                          C := Default(TTowCarriere);
                          C.Code := TDOMElement(N).GetAttribute('id');
                          C.Libelle := Chaine(N, 'Description');
                          C.Status := Chaine(N, 'Status');
                          Sub := N.FirstChild;
                          while Sub <> nil do
                            begin
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'SUBCHAPTER_SKILL') then
                                LitCompCarriere(Sub, C);
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'SUBCHAPTER_FAVOURED') then
                                begin
                                  A := Sub.FirstChild;
                                  while A <> nil do
                                    begin
                                      if (A.NodeType = ELEMENT_NODE) and (A.NodeName = 'Attribut') then
                                        begin
                                          SetLength(C.Favoris, Length(C.Favoris) + 1);
                                          C.Favoris[High(C.Favoris)] := TDOMElement(A).GetAttribute('name');
                                        end;
                                      A := A.NextSibling;
                                    end;
                                end;
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'SUBCHAPTER_LORE') then
                                LitSlots(Sub, 'Slot', C.LoreSlots);
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'SUBCHAPTER_TRAPPING') then
                                LitSlots(Sub, 'Slot', C.TrappingSlots);
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'SUBCHAPTER_ASSET') then
                                LitSlots(Sub, 'Slot', C.AssetSlots);
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'SUBCHAPTER_CONTACT') then
                                begin
                                  Ori := Sub.FirstChild;
                                  while Ori <> nil do
                                    begin
                                      if (Ori.NodeType = ELEMENT_NODE) and (Ori.NodeName = 'Contact') then
                                        begin
                                          SetLength(C.Familles, Length(C.Familles) + 1);
                                          C.Familles[High(C.Familles)] := TDOMElement(Ori).GetAttribute('name');
                                        end;
                                      Ori := Ori.NextSibling;
                                    end;
                                end;
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'CareerTalent') then
                                begin
                                  C.TalentCarriere := Chaine(Sub, 'Description');
                                  C.TalentCarriereTexte := Chaine(Sub, 'Explanation');
                                end;
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'SUBCHAPTER_ORIGIN') then
                                begin
                                  Ori := Sub.FirstChild;
                                  while Ori <> nil do
                                    begin
                                      if (Ori.NodeType = ELEMENT_NODE) and (Ori.NodeName = 'Origin') then
                                        begin
                                          Pl.Origine := TDOMElement(Ori).GetAttribute('name');
                                          Plage := Sans(Trim(Ori.TextContent));
                                          P := Pos('-', Plage);
                                          if P > 0 then
                                            begin
                                              Pl.De := StrToIntDef(Copy(Plage, 1, P - 1), 0);
                                              Pl.A := StrToIntDef(Copy(Plage, P + 1, 9), 0);
                                            end
                                          else
                                            begin
                                              Pl.De := StrToIntDef(Plage, 0);
                                              Pl.A := Pl.De;
                                            end;
                                          SetLength(C.Plages, Length(C.Plages) + 1);
                                          C.Plages[High(C.Plages)] := Pl;
                                        end;
                                      Ori := Ori.NextSibling;
                                    end;
                                end;
                              Sub := Sub.NextSibling;
                            end;
                          SetLength(Result, Length(Result) + 1);
                          Result[High(Result)] := C;
                        end;
                      N := N.NextSibling;
                    end;
                end;
              Liste := Liste.NextSibling;
            end;
  end;
  end;

function TowCarriereDeD100(const Carrieres: TTowCarrieres; const Origine: String; D100: Integer): Integer;
  var I, K: Integer;
  begin
    Result := -1;
    for I := 0 to High(Carrieres) do
      for K := 0 to High(Carrieres[I].Plages) do
        if (Carrieres[I].Plages[K].Origine = Origine) and (Carrieres[I].Plages[K].De > 0)
           and (D100 >= Carrieres[I].Plages[K].De) and (D100 <= Carrieres[I].Plages[K].A) then
          begin
            Result := I;
            Exit;
          end;
  end;

function TowCarriereAdmise(const C: TTowCarriere; const Origine: String): Boolean;
  var K: Integer;
  begin
    Result := False;
    for K := 0 to High(C.Plages) do
      if C.Plages[K].Origine = Origine then
        begin
          Result := True;
          Exit;
        end;
  end;

// Lignes propres a TOW dans StructurePersonnage : atouts et contacts = LignesTow (Genre ASSET / CONTACT),
// sorts = lignes d equipement de type sort, equipement = ligne d equipement (type deduit de la fiche).
procedure TowAjouteLigne(var P: StructurePersonnage; const Genre, Code, Famille, Texte: String);
  var N: Integer;
  begin
    N := Length(P.LignesTow);
    SetLength(P.LignesTow, N + 1);
    P.LignesTow[N].Genre   := Genre;
    P.LignesTow[N].Code    := Code;
    P.LignesTow[N].Famille := Famille;
    P.LignesTow[N].Texte   := Texte;
  end;

function TowAjouteEquip(var P: StructurePersonnage; const Code, Texte: String): Integer;
  begin
    Result := Length(P.Equipement);
    SetLength(P.Equipement, Result + 1);
    P.Equipement[Result] := Default(StructurePersonnageEquipement);
    P.Equipement[Result].CodeEquipement := Code;
    P.Equipement[Result].TexteTow       := Texte;
    P.Equipement[Result].Quantite       := 1;
    if ChercheArme(Code).CodeArme <> '' then
      P.Equipement[Result].TypeEquipement := TrimRight(TypeEquipWe)
    else if ChercheArmure(Code).CodeArmure <> '' then
      P.Equipement[Result].TypeEquipement := TrimRight(TypeEquipAr)
    else
      P.Equipement[Result].TypeEquipement := TrimRight(TypeEquipDi);
  end;

function TowObjetDeAsset(const CodeAsset: String): String;
  var
    IL:   Integer;
    Doc: TXMLDocument;
    Liste, N, Sub: TDOMNode;
  begin
    Result := '';
    if CodeAsset = '' then Exit;
    TowOuvreLivres(IncludeTrailingPathDelimiter(GetCurrentDir + '/DATABASE/WFRPTOW'));
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
        Liste := Doc.DocumentElement.FirstChild;
        while Liste <> nil do
          begin
            N := Liste.FirstChild;
            while N <> nil do
              begin
                if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Asset') and (TDOMElement(N).GetAttribute('id') = CodeAsset) then
                  begin
                    Sub := N.FirstChild;
                    while Sub <> nil do
                      begin
                        if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'GrantsItem') then
                          Result := StringReplace(Trim(Sub.TextContent), '"', '', [rfReplaceAll]);
                        Sub := Sub.NextSibling;
                      end;
                  end;
                N := N.NextSibling;
              end;
            Liste := Liste.NextSibling;
          end;
        if Result <> '' then Break;
      end;
  end;

function TowEquipementAssets(const P: StructurePersonnage): TArrayPersonnageEquipement;
  var
    I:    Integer;
    Code: String;
    E:    StructurePersonnageEquipement;
  begin
    Result := [];
    for I := 0 to High(P.LignesTow) do
      if P.LignesTow[I].Genre = 'ASSET' then
        begin
          Code := TowObjetDeAsset(P.LignesTow[I].Code);
          if Code = '' then Continue;
          E := Default(StructurePersonnageEquipement);
          E.CodeEquipement := Code;
          E.Source         := P.LignesTow[I].Code;
          E.Quantite       := 1;
          if ChercheArme(Code).CodeArme <> '' then
            E.TypeEquipement := TrimRight(TypeEquipWe)
          else if ChercheArmure(Code).CodeArmure <> '' then
            E.TypeEquipement := TrimRight(TypeEquipAr)
          else
            E.TypeEquipement := TrimRight(TypeEquipDi);
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := E;
        end;
  end;

function TowAjouteSort(var P: StructurePersonnage; const Code, Texte: String): Integer;
  begin
    Result := TowAjouteEquip(P, Code, Texte);
    P.Equipement[Result].TypeEquipement := TrimRight(TypeEquipSp);
  end;

// Index dans Equipement du N-ieme sort (0..), -1 s il n y en a pas autant
function TowIndexSort(const P: StructurePersonnage; N: Integer): Integer;
  var I, K: Integer;
  begin
    Result := -1;
    K := 0;
    for I := 0 to High(P.Equipement) do
      if P.Equipement[I].TypeEquipement = TrimRight(TypeEquipSp) then
        begin
          if K = N then Exit(I);
          Inc(K);
        end;
  end;

function TowNbSorts(const P: StructurePersonnage): Integer;
  var I: Integer;
  begin
    Result := 0;
    for I := 0 to High(P.Equipement) do
      if P.Equipement[I].TypeEquipement = TrimRight(TypeEquipSp) then Inc(Result);
  end;

procedure TowFixeCarriere(var P: StructurePersonnage; const C: TTowCarriere);
  begin
    P.MetierEnCours.CodeMetier   := C.Code;
    P.MetierEnCours.NiveauMetier := 1;
    P.StatusTow := C.Status;
  end;

function TowLoreManquant(const P: StructurePersonnage; const C: TTowCarriere): String;
  var
    I, K, J: Integer;
    Opt, Racine: String;
    Trouve: Boolean;
  begin
    Result := '';
    for I := 0 to High(C.LoreSlots) do
      begin
        if Length(C.LoreSlots[I]) = 0 then Continue;
        Trouve := False;
        for K := 0 to High(C.LoreSlots[I]) do
          begin
            Opt := C.LoreSlots[I][K];
            Racine := Opt;
            if (Racine <> '') and (Racine[Length(Racine)] = '*') then SetLength(Racine, Length(Racine) - 1);
            for J := 0 to High(P.LoresTow) do
              if (P.LoresTow[J].Code = Opt) or ((Racine <> Opt) and (Pos(Racine, P.LoresTow[J].Code) = 1)) then
                Trouve := True;
          end;
        if not Trouve then
          begin
            for K := 0 to High(C.LoreSlots[I]) do
              begin
                if K > 0 then Result := Result + ' / ';
                Result := Result + TowLibelleDe(C.LoreSlots[I][K]);
              end;
            Exit;
          end;
      end;
  end;

function TowAtoutsCarriere(const C: TTowCarriere): TStringList;
  var I, K: Integer;
  begin
    Result := TStringList.Create;
    for I := 0 to High(C.AssetSlots) do
      for K := 0 to High(C.AssetSlots[I]) do
        if Result.IndexOf(C.AssetSlots[I][K]) < 0 then Result.Add(C.AssetSlots[I][K]);
  end;

procedure TowChangeCarriere(var P: StructurePersonnage; const C: TTowCarriere; const AtoutPerdu, AtoutGagne: String);
  var I, K: Integer;
  begin
    TowFixeCarriere(P, C);
    TowTalentCarriere(P, C);
    for I := 0 to High(P.LignesTow) do
      if (P.LignesTow[I].Genre = 'ASSET') and (P.LignesTow[I].Code = AtoutPerdu) then
        begin
          for K := I to High(P.LignesTow) - 1 do P.LignesTow[K] := P.LignesTow[K + 1];
          SetLength(P.LignesTow, Length(P.LignesTow) - 1);
          Break;
        end;
    if AtoutGagne <> '' then TowAjouteLigne(P, 'ASSET', AtoutGagne, '', '');
  end;

function TowOrigineDeD10(const Origines: TTowOrigines; D10: Integer): Integer;
  var I: Integer;
  begin
    Result := -1;
    for I := 0 to High(Origines) do
      if (D10 >= Origines[I].DeD10) and (D10 <= Origines[I].AuD10) then
        begin
          Result := I;
          Exit;
        end;
  end;

function TowCommencer(const O: TTowOrigine; const Nom: String): StructurePersonnage;
  var I: Integer;
  begin
    Result := Default(StructurePersonnage);
    Result.NomPersonnage := Nom;
    Result.Race := O.Code;
    Result.MetierEnCours.NiveauMetier := 1;
    Result.HeightUnit := ConstUniteInch;
    SetLength(Result.CreationAttribut, TowNbCarac);
    for I := 1 to TowNbCarac do
      begin
        Result.CreationAttribut[I - 1].CodeAttribut := TowCodesCarac[I];
        Result.CreationAttribut[I - 1].Valeur := O.Depart[I];
      end;
    Result.FateTow := O.Depart[TowNbCarac];
    Result.FortuneTow := Result.FateTow;
  end;

function TowAjouteUn(var P: StructurePersonnage; const O: TTowOrigine; Index: Integer): Boolean;
  begin
    Result := False;
    if (Index < 1) or (Index > TowNbCarac) then Exit;
    if (O.Maximum[Index] > 0) and (P.CreationAttribut[Index - 1].Valeur >= O.Maximum[Index]) then Exit;
    Inc(P.CreationAttribut[Index - 1].Valeur);
    if Index = TowNbCarac then
      begin
        Inc(P.FateTow);
        Inc(P.FortuneTow);
      end;
    Result := True;
  end;

function TowTireTroisPlus(var P: StructurePersonnage; const O: TTowOrigine; Deja: TStringList): Integer;
  // Trois +1 au hasard. Renvoie le nombre de relances. Deja recoit les index (1..9) augmentes, dans l ordre.
  var
    Fait, D, I, Relances: Integer;
    Libre: Boolean;
  begin
    Fait := 0;
    Relances := 0;
    while Fait < 3 do
      begin
        D := Random(10) + 1;
        if D = 10 then
          begin
            // au choix : premier non augmente et non au maximum (choix automatique du tirage au hasard)
            Libre := False;
            for I := 1 to TowNbCarac do
              if (Deja.IndexOf(IntToStr(I)) < 0) and
                 ((O.Maximum[I] = 0) or (P.CreationAttribut[I - 1].Valeur < O.Maximum[I])) then
                begin
                  D := I;
                  Libre := True;
                  Break;
                end;
            if not Libre then Continue;
          end
        else if Deja.IndexOf(IntToStr(D)) >= 0 then
          begin
            Inc(Relances);
            Continue;
          end;
        if TowAjouteUn(P, O, D) then
          begin
            Deja.Add(IntToStr(D));
            Inc(Fait);
          end
        else
          Inc(Relances);
      end;
    Result := Relances;
  end;

procedure TowInitCompetences(var P: StructurePersonnage);
  var I: Integer;
  begin
    SetLength(P.CreationCompetence35, TowNbComp);
    for I := 1 to TowNbComp do
      begin
        P.CreationCompetence35[I - 1].CodeCompetence := TowCodesComp[I];
        P.CreationCompetence35[I - 1].Valeur := TowRangDepart;
        P.CreationCompetence35[I - 1].TicksTow := 0;
      end;
  end;

function TowIndexComp(const P: StructurePersonnage; const Code: String): Integer;
  var I: Integer;
  begin
    Result := -1;
    for I := 0 to High(P.CreationCompetence35) do
      if P.CreationCompetence35[I].CodeCompetence = Code then
        begin
          Result := I;
          Exit;
        end;
  end;

function TowRangComp(const P: StructurePersonnage; const Code: String): Integer;
  var I: Integer;
  begin
    I := TowIndexComp(P, Code);
    if I < 0 then Result := 0 else Result := P.CreationCompetence35[I].Valeur;
  end;

function TowCompetencesOrigine(var P: StructurePersonnage; const O: TTowOrigine; Libres: TStringList): Integer;
  var
    I, K, Fait, Cible: Integer;
    Candidats: TStringList;
  begin
    Result := 0;
    for I := 0 to High(O.CompFixes) do
      begin
        K := TowIndexComp(P, O.CompFixes[I]);
        if (K >= 0) and (P.CreationCompetence35[K].Valeur < O.CompRang) then P.CreationCompetence35[K].Valeur := O.CompRang;
      end;
    Fait := 0;
    if Libres <> nil then
      for I := 0 to Libres.Count - 1 do
        if Fait < O.CompLibres then
          begin
            K := TowIndexComp(P, Libres[I]);
            if (K >= 0) and (P.CreationCompetence35[K].Valeur < O.CompRang) then
              begin
                P.CreationCompetence35[K].Valeur := O.CompRang;
                Inc(Fait);
              end;
          end;
    // le reste au hasard parmi celles encore au rang de depart
    while Fait < O.CompLibres do
      begin
        Candidats := TStringList.Create;
        try
          for K := 0 to High(P.CreationCompetence35) do
            if P.CreationCompetence35[K].Valeur < O.CompRang then Candidats.Add(IntToStr(K));
          if Candidats.Count = 0 then Break;
          Cible := StrToInt(Candidats[Random(Candidats.Count)]);
        finally
          Candidats.Free;
        end;
        P.CreationCompetence35[Cible].Valeur := O.CompRang;
        Inc(Fait);
        Inc(Result);
      end;
  end;

function TowCompetencesCarriere(var P: StructurePersonnage; const C: TTowCarriere; Choix: TStringList): Integer;
  var
    I, K, Fait, Cible: Integer;
    Reste: TStringList;
  begin
    Result := 0;
    Fait := 0;
    if Choix <> nil then
      for I := 0 to Choix.Count - 1 do
        if Fait < C.CompNb then
          begin
            K := TowIndexComp(P, Choix[I]);
            if (K >= 0) and (P.CreationCompetence35[K].Valeur < TowRangMax) then
              begin
                Inc(P.CreationCompetence35[K].Valeur);
                Inc(Fait);
              end;
          end;
    while Fait < C.CompNb do
      begin
        Reste := TStringList.Create;
        try
          // candidates non encore augmentees par la carriere : on les retire au fur et a mesure
          for I := 0 to High(C.CompChoix) do
            if (Choix = nil) or (Choix.IndexOf(C.CompChoix[I]) < 0) then
              Reste.Add(C.CompChoix[I]);
          if Reste.Count = 0 then Break;
          Cible := TowIndexComp(P, Reste[Random(Reste.Count)]);
          if Choix = nil then Break;  // garde : l appelant doit fournir la liste pour le suivi
          Choix.Add(P.CreationCompetence35[Cible].CodeCompetence);
        finally
          Reste.Free;
        end;
        if P.CreationCompetence35[Cible].Valeur < TowRangMax then Inc(P.CreationCompetence35[Cible].Valeur);
        Inc(Fait);
        Inc(Result);
      end;
  end;

procedure TowPrecisionTouched(var P: StructurePersonnage; Choix: String); forward;

function TowAjouteTalent(var P: StructurePersonnage; const Code, Source: String): Boolean;
  var I: Integer;
  begin
    for I := 0 to High(P.CreationTalent) do
      if P.CreationTalent[I].CodeTalent = Code then
        begin
          Result := False;
          Exit;
        end;
    I := Length(P.CreationTalent);
    SetLength(P.CreationTalent, I + 1);
    P.CreationTalent[I].CodeTalent := Code;
    P.CreationTalent[I].Valeur := 1;
    P.CreationTalent[I].ChoixTow := '';
    P.CreationTalent[I].SourceTow := Source;
    Result := True;
  end;

function TowChoisitLores(var P: StructurePersonnage; const Slots: TTowSlots; Choix: TStringList): Integer;
  var
    I, K, N: Integer;
    Code: String;
    Deja: Boolean;
  begin
    Result := 0;
    for I := 0 to High(Slots) do
      begin
        if Length(Slots[I]) = 0 then Continue;
        Code := '';
        if (Choix <> nil) and (I < Choix.Count) then
          for K := 0 to High(Slots[I]) do
            if Slots[I][K] = Choix[I] then Code := Choix[I];
        if Code = '' then
          begin
            Code := Slots[I][Random(Length(Slots[I]))];
            Inc(Result);
          end;
        Deja := False;
        for K := 0 to High(P.LoresTow) do
          if P.LoresTow[K].Code = Code then Deja := True;
        if not Deja then
          begin
            N := Length(P.LoresTow);
            SetLength(P.LoresTow, N + 1);
            P.LoresTow[N].Code := Code;
            P.LoresTow[N].Texte := '';
          end;
      end;
  end;

function TowTalentsOrigine(var P: StructurePersonnage; const O: TTowOrigine; IndexEchange: Integer): Integer;
  var
    I, Fait, D, K: Integer;
    Tires: TStringList;
  begin
    Result := 0;
    for I := 0 to High(O.TalentsFixes) do
      TowAjouteTalent(P, O.TalentsFixes[I], 'origin');
    Tires := TStringList.Create;
    try
      Fait := 0;
      while Fait < O.TalentTirages do
        begin
          D := Random(10) + 1;
          for K := 0 to High(O.TableTalents) do
            if (D >= O.TableTalents[K].De) and (D <= O.TableTalents[K].A) then
              begin
                if Tires.IndexOf(O.TableTalents[K].Code) >= 0 then
                  Inc(Result)
                else
                  begin
                    Tires.Add(O.TableTalents[K].Code);
                    Inc(Fait);
                  end;
                Break;
              end;
        end;
      // echange : un talent tire est remplace par TalentEchange
      if (O.TalentEchange <> '') and (Tires.Count > 0) and (O.Echange <> 'NONE') then
        begin
          if IndexEchange >= 0 then K := IndexEchange
          else if O.Echange = 'MANDATORY' then K := Tires.Count - 1
          else K := -1;
          if (K >= 0) and (K < Tires.Count) then Tires[K] := O.TalentEchange;
        end;
      for I := 0 to Tires.Count - 1 do
        TowAjouteTalent(P, Tires[I], 'origin');
      // precisions : Touched by the Winds = une Magic Lore ; Faith = un dieu (hasard)
      TowPrecisionTouched(P, '');
      K := -1;
      for I := 0 to High(P.CreationTalent) do
        if (P.CreationTalent[I].CodeTalent = 'RULES-T_FAITH') and (P.CreationTalent[I].ChoixTow = '') then K := I;
      if K >= 0 then P.CreationTalent[K].ChoixTow := TowDieux[Random(Length(TowDieux))];
    finally
      Tires.Free;
    end;
  end;

function TowAjouteLore(var P: StructurePersonnage; const Code: String): Boolean;
  var K, N: Integer;
  begin
    for K := 0 to High(P.LoresTow) do
      if P.LoresTow[K].Code = Code then
        begin
          Result := False;
          Exit;
        end;
    N := Length(P.LoresTow);
    SetLength(P.LoresTow, N + 1);
    P.LoresTow[N].Code := Code;
    P.LoresTow[N].Texte := '';
    Result := True;
  end;

function TowIndexTalent(const P: StructurePersonnage; const Code: String): Integer;
  var I: Integer;
  begin
    Result := -1;
    for I := 0 to High(P.CreationTalent) do
      if P.CreationTalent[I].CodeTalent = Code then Result := I;
  end;

// Touched by the Winds : une Magic Lore (Choix valide, sinon hasard), ajoutee aux lores
procedure TowPrecisionTouched(var P: StructurePersonnage; Choix: String);
  var I, J, K: Integer;
  begin
    I := TowIndexTalent(P, 'RULES-T_TOUCHED_BY_THE_WINDS');
    if I < 0 then Exit;
    if P.CreationTalent[I].ChoixTow = '' then
      begin
        K := -1;
        for J := 0 to High(TowLoresMagie) do
          if TowLoresMagie[J] = Choix then K := J;
        if K < 0 then K := Random(Length(TowLoresMagie));
        P.CreationTalent[I].ChoixTow := TowLoresMagie[K];
      end;
    TowAjouteLore(P, P.CreationTalent[I].ChoixTow);
  end;

// Faith : un seul dieu, rang +1 par achat ; impossible avec la magie (Wizard). Renvoie False si refuse.
function TowAjouteFaith(var P: StructurePersonnage; Dieu: String; const Source: String): Boolean;
  var I, K: Integer;
  begin
    Result := False;
    if TowIndexTalent(P, 'RULES-T_WIZARD') >= 0 then Exit;
    I := TowIndexTalent(P, 'RULES-T_FAITH');
    if I >= 0 then
      begin
        Inc(P.CreationTalent[I].Valeur);
        Result := True;
        Exit;
      end;
    K := -1;
    for I := 0 to High(TowDieux) do
      if TowDieux[I] = Dieu then K := I;
    if K < 0 then K := Random(Length(TowDieux));
    TowAjouteTalent(P, 'RULES-T_FAITH', Source);
    P.CreationTalent[TowIndexTalent(P, 'RULES-T_FAITH')].ChoixTow := TowDieux[K];
    Result := True;
  end;

// Wizard : rang = Wizard Level (1 a 4) ; une Magic Lore requise, ajoutee aux lores ; impossible avec Faith
function TowAjouteWizard(var P: StructurePersonnage; Lore: String; const Source: String): Boolean;
  var I, K: Integer;
  begin
    Result := False;
    if TowIndexTalent(P, 'RULES-T_FAITH') >= 0 then Exit;
    I := TowIndexTalent(P, 'RULES-T_WIZARD');
    if I >= 0 then
      begin
        if P.CreationTalent[I].Valeur >= 4 then Exit;
        Inc(P.CreationTalent[I].Valeur);
        P.WizardLevelTow := P.CreationTalent[I].Valeur;
        Result := True;
        Exit;
      end;
    // pas de precision donnee : on garde la Magic Lore deja precisee sur un emplacement de lore
    if Lore = '' then
      for I := 0 to High(P.LoresTow) do
        for K := 0 to High(TowLoresMagie) do
          if P.LoresTow[I].Code = TowLoresMagie[K] then Lore := TowLoresMagie[K];
    K := -1;
    for I := 0 to High(TowLoresMagie) do
      if TowLoresMagie[I] = Lore then K := I;
    if K < 0 then K := Random(Length(TowLoresMagie));
    TowAjouteTalent(P, 'RULES-T_WIZARD', Source);
    P.CreationTalent[TowIndexTalent(P, 'RULES-T_WIZARD')].ChoixTow := TowLoresMagie[K];
    // l emplacement generique « Magic Lore (au choix) » de la carriere prend cette lore
    I := -1;
    for K := 0 to High(P.LoresTow) do
      if Copy(P.LoresTow[K].Code, 1, 19) = 'RULES-LORE_MAGIC__*' then I := K;
    K := TowIndexTalent(P, 'RULES-T_WIZARD');
    if I >= 0 then P.LoresTow[I].Code := P.CreationTalent[K].ChoixTow
    else TowAjouteLore(P, P.CreationTalent[K].ChoixTow);
    P.WizardLevelTow := 1;
    Result := True;
  end;

function TowChargeRelations(const Dossier: String): TTowRelations;
  var
    IL:   Integer;
    Doc: TXMLDocument;
    Liste, N, Npc, Rel: TDOMNode;
    Fam, Nom, Plage: String;
    P: Integer;
    R: TTowRelation;
  begin
    SetLength(Result, 0);
    TowOuvreLivres(IncludeTrailingPathDelimiter(Dossier));
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              if (Liste.NodeType = ELEMENT_NODE) and (Liste.NodeName = 'DATA_CONTACT') then
                begin
                  N := Liste.FirstChild;
                  while N <> nil do
                    begin
                      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Contact') then
                        begin
                          Fam := TDOMElement(N).GetAttribute('id');
                          Npc := N.FirstChild;
                          while Npc <> nil do
                            begin
                              if (Npc.NodeType = ELEMENT_NODE) and (Npc.NodeName = 'Npc') then
                                begin
                                  Nom := Chaine(Npc, 'Description');
                                  Rel := Npc.FirstChild;
                                  while Rel <> nil do
                                    begin
                                      if (Rel.NodeType = ELEMENT_NODE) and (Rel.NodeName = 'Relation') then
                                        begin
                                          Plage := TDOMElement(Rel).GetAttribute('range');
                                          P := Pos('-', Plage);
                                          R.Famille := Fam;
                                          R.Npc := Nom;
                                          R.Texte := Sans(Trim(Rel.TextContent));
                                          if P > 0 then
                                            begin
                                              R.De := StrToIntDef(Copy(Plage, 1, P - 1), 0);
                                              R.A := StrToIntDef(Copy(Plage, P + 1, 9), 0);
                                            end
                                          else
                                            begin
                                              R.De := StrToIntDef(Plage, 0);
                                              R.A := R.De;
                                            end;
                                          SetLength(Result, Length(Result) + 1);
                                          Result[High(Result)] := R;
                                        end;
                                      Rel := Rel.NextSibling;
                                    end;
                                end;
                              Npc := Npc.NextSibling;
                            end;
                        end;
                      N := N.NextSibling;
                    end;
                end;
              Liste := Liste.NextSibling;
            end;
  end;
  end;

function TowTireContacts(var P: StructurePersonnage; const C: TTowCarriere; const Rel: TTowRelations;
  Choix: Integer): Integer;
  var
    Jet, F, I, K, Fait: Integer;
    Famille: String;
    Deja: Boolean;
  begin
    Result := 0;
    if Length(C.Familles) = 0 then Exit;
    Fait := 0;
    while Fait < 2 do
      begin
        if (Choix >= 0) and (Choix < Length(C.Familles)) then F := Choix
        else if Length(C.Familles) > 1 then F := Fait
        else F := 0;
        Famille := C.Familles[F];
        Jet := Random(100) + 1;
        for I := 0 to High(Rel) do
          if (Rel[I].Famille = Famille) and (Jet >= Rel[I].De) and (Jet <= Rel[I].A) then
            begin
              Deja := False;
              for K := 0 to High(P.LignesTow) do
                if (P.LignesTow[K].Genre = 'CONTACT') and (P.LignesTow[K].Famille = Famille) and
                   (P.LignesTow[K].Code = Rel[I].Npc) then Deja := True;
              if Deja then Inc(Result)
              else
                begin
                  TowAjouteLigne(P, 'CONTACT', Rel[I].Npc, Famille, Rel[I].Texte);
                  Inc(Fait);
                end;
              Break;
            end;
      end;
  end;

procedure TowTalentCarriere(var P: StructurePersonnage; const C: TTowCarriere; const Precision: String);
  var I, K: Integer;
  begin
    TowAjouteTalent(P, 'CAREER-TALENT:' + C.Code, 'career');
    // Career Talents qui donnent un talent chiffre : Arcane Study / Wisdom of the Hedge = Wizard niveau 1,
    // True Faith = un rang de Faith (le dieu : Precision, sinon hasard)
    if (C.Code = 'RULES-WORK_ARCANE_WIZARD') or (C.Code = 'RULES-WORK_HEDGE_WIZARD') then
      begin
        // le Career Talent est explicite (« Level 1 Wizard ») : il remplace un Faith tire par l origine
        I := TowIndexTalent(P, 'RULES-T_FAITH');
        if I >= 0 then
          begin
            for K := I to High(P.CreationTalent) - 1 do P.CreationTalent[K] := P.CreationTalent[K + 1];
            SetLength(P.CreationTalent, Length(P.CreationTalent) - 1);
          end;
        TowAjouteWizard(P, Precision, 'career');
      end
    else if C.Code = 'RULES-WORK_PRIEST' then
      TowAjouteFaith(P, Precision, 'career');
  end;

var
  CacheArmes: TStringList = nil;   // « code|categorie|cout » de chaque arme du livre
  CacheOutils: TStringList = nil;  // « code|lore requis » de chaque outil de metier (TRADE_TOOLS)

procedure TowChargeArmes;
  var
    IL:   Integer;
    Doc: TXMLDocument;
    Liste, N: TDOMNode;
    Dossier, Cat: String;
  begin
    if CacheArmes <> nil then Exit;
    CacheArmes := TStringList.Create;
    CacheOutils := TStringList.Create;
    Dossier := IncludeTrailingPathDelimiter(GetCurrentDir + '/DATABASE/WFRPTOW');
    TowOuvreLivres(Dossier);
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              N := Liste.FirstChild;
              while N <> nil do
                begin
                  // armes : fiches Weapon comme les autres livres ; categorie deduite de la competence
                  if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Weapon') and (Chaine(N, 'Price') <> '') then
                    begin
                      if Chaine(N, 'Skill') = 'RULES-COMP_MELEE' then Cat := 'MELEE'
                      else if Chaine(N, 'Skill') = 'RULES-COMP_SHOOTING' then Cat := 'RANGED'
                      else Cat := 'THROWN';
                      CacheArmes.Add(TDOMElement(N).GetAttribute('id') + '|' + Cat + '|' + Chaine(N, 'Price'));
                    end;
                  if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Trapping') and
                     (Chaine(N, 'Category') = 'TRADE_TOOLS') and (Chaine(N, 'RequiredLore') <> '') then
                    CacheOutils.Add(TDOMElement(N).GetAttribute('id') + '|' + Chaine(N, 'RequiredLore'));
                  N := N.NextSibling;
                end;
              Liste := Liste.NextSibling;
            end;
  end;
  end;

var
  CacheLores: TStringList = nil;   // « code|famille|parent|specify|option;option » de chaque lore du livre

procedure TowChargeLores;
  var
    IL:   Integer;
    Doc: TXMLDocument;
    Liste, N, Sub: TDOMNode;
    Dossier, Opts: String;
  begin
    if CacheLores <> nil then Exit;
    CacheLores := TStringList.Create;
    Dossier := IncludeTrailingPathDelimiter(GetCurrentDir + '/DATABASE/WFRPTOW');
    TowOuvreLivres(Dossier);
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              if (Liste.NodeType = ELEMENT_NODE) and (Liste.NodeName = 'DATA_LORE') then
                begin
                  N := Liste.FirstChild;
                  while N <> nil do
                    begin
                      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Lore') then
                        begin
                          Opts := '';
                          Sub := N.FirstChild;
                          while Sub <> nil do
                            begin
                              if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'Option') then
                                Opts := Opts + TDOMElement(Sub).GetAttribute('name') + ';';
                              Sub := Sub.NextSibling;
                            end;
                          CacheLores.Add(TDOMElement(N).GetAttribute('id') + '|' + Chaine(N, 'Family') + '|' +
                                         Chaine(N, 'Parent') + '|' + Chaine(N, 'Specify') + '|' + Opts);
                        end;
                      N := N.NextSibling;
                    end;
                end;
              Liste := Liste.NextSibling;
            end;
  end;
  end;

function TowPrecisionsLore(const Generique: String): TStringList;
  var
    I, J: Integer;
    Gen, Fam, Ligne: String;
    Champs: TStringList;
  begin
    Result := TStringList.Create;
    Gen := Generique;
    if (Gen <> '') and (Gen[Length(Gen)] = '*') then Delete(Gen, Length(Gen), 1);
    if Gen = 'RULES-LORE_MAGIC__' then
      begin
        for I := 0 to High(TowLoresMagie) do Result.Add(TowLoresMagie[I]);
        Exit;
      end;
    TowChargeLores;
    Champs := TStringList.Create;
    try
      Champs.Delimiter := '|';
      Champs.StrictDelimiter := True;
      Fam := '';
      for I := 0 to CacheLores.Count - 1 do
        begin
          Champs.DelimitedText := CacheLores[I];
          if (Champs.Count >= 5) and (Champs[0] = Gen) then
            begin
              Fam := Champs[1];
              Ligne := Champs[4];
              while Ligne <> '' do
                begin
                  J := Pos(';', Ligne);
                  if J = 0 then J := Length(Ligne) + 1;
                  if J > 1 then Result.Add(Copy(Ligne, 1, J - 1));
                  Delete(Ligne, 1, J);
                end;
            end;
        end;
      // pas d options : lores concretes de la meme famille (Academic, Enemy, Environment, Trade) ;
      // les familles culturelles sans options (rien de tel dans le livre) restent libres
      if (Result.Count = 0) and (Fam <> '') and (Fam <> 'CULTURAL') and (Fam <> 'MAGIC') then
        for I := 0 to CacheLores.Count - 1 do
          begin
            Champs.DelimitedText := CacheLores[I];
            if (Champs.Count >= 5) and (Champs[1] = Fam) and (Champs[2] = '') and (Champs[3] = '') then
              Result.Add(Champs[0]);
          end;
    finally
      Champs.Free;
    end;
  end;

// Favoured Lore d un dieu (balise FavouredLore de la fiche God) ; '' si inconnue
function TowLoreDuDieu(const Dieu: String): String;
  var
    IL:   Integer;
    Doc: TXMLDocument;
    Liste, N, Sub: TDOMNode;
    Dossier: String;
  begin
    Result := '';
    if Dieu = '' then Exit;
    Dossier := IncludeTrailingPathDelimiter(GetCurrentDir + '/DATABASE/WFRPTOW');
    TowOuvreLivres(Dossier);
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              N := Liste.FirstChild;
              while N <> nil do
                begin
                  if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'God') and (TDOMElement(N).GetAttribute('id') = Dieu) then
                    begin
                      Sub := N.FirstChild;
                      while Sub <> nil do
                        begin
                          if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'FavouredLore') then
                            Result := TDOMElement(Sub).GetAttribute('name');
                          Sub := Sub.NextSibling;
                        end;
                    end;
                  N := N.NextSibling;
                end;
              Liste := Liste.NextSibling;
            end;
        if Result <> '' then Break;
      end;
  end;

// « Favoured Lore of your god » : la lore du dieu de la Faith remplace l emplacement generique
procedure TowLoreFavorite(var P: StructurePersonnage);
  var
    I, J, K: Integer;
    Code: String;
    Deja: Boolean;
  begin
    for I := 0 to High(P.CreationTalent) do
      if (P.CreationTalent[I].CodeTalent = 'RULES-T_FAITH') and (P.CreationTalent[I].ChoixTow <> '') then
        begin
          Code := TowLoreDuDieu(P.CreationTalent[I].ChoixTow);
          K := -1;
          for J := 0 to High(P.LoresTow) do
            if (P.LoresTow[J].Code = 'RULES-LORE_GODS_FAVOURED__*') or (P.LoresTow[J].Code = 'RULES-LORE_GODS_FAVOURED__') then K := J;
          if (Code <> '') and (K >= 0) then
            begin
              Deja := False;
              for J := 0 to High(P.LoresTow) do
                if P.LoresTow[J].Code = Code then Deja := True;
              if Deja then
                begin
                  for J := K to High(P.LoresTow) - 1 do P.LoresTow[J] := P.LoresTow[J + 1];
                  SetLength(P.LoresTow, Length(P.LoresTow) - 1);
                end
              else
                P.LoresTow[K].Code := Code;
            end;
          Break;
        end;
  end;

function TowLoreGenerique(const Code: String): Boolean;
  var L: TStringList;
  begin
    Result := False;
    if Copy(Code, Length(Code) - 2, 3) <> '__*' then Exit;
    L := TowPrecisionsLore(Code);
    try
      Result := L.Count > 0;
    finally
      L.Free;
    end;
  end;

function TowLoresApprenables(const P: StructurePersonnage): TStringList;
  var
    I, J: Integer;
    Champs, Precisions: TStringList;
    Connue: Boolean;

  procedure Ajoute(const Code: String);
    var K: Integer;
    begin
      if (Code = '') or (Copy(Code, Length(Code) - 1, 2) = '__') or (Result.IndexOf(Code) >= 0) then Exit;
      Connue := False;
      for K := 0 to High(P.LoresTow) do
        if P.LoresTow[K].Code = Code then Connue := True;
      if not Connue then Result.Add(Code);
    end;

  begin
    Result := TStringList.Create;
    TowChargeLores;
    Champs := TStringList.Create;
    try
      Champs.Delimiter := '|';
      Champs.StrictDelimiter := True;
      for I := 0 to CacheLores.Count - 1 do
        begin
          Champs.DelimitedText := CacheLores[I];
          if Champs.Count < 5 then Continue;
          if Champs[3] = '' then
            Ajoute(Champs[0])
          else
            begin
              // lore generique : ses precisions (options du livre) deviennent des lores a part entiere
              Precisions := TowPrecisionsLore(Champs[0]);
              try
                for J := 0 to Precisions.Count - 1 do
                  if Precisions[J] <> '' then Ajoute(Precisions[J]);
              finally
                Precisions.Free;
              end;
            end;
        end;
    finally
      Champs.Free;
    end;
  end;

function TowArmesPour(const Generique: String): TStringList;
  var
    I, P1, P2: Integer;
    Ligne, Cat, Cout, Gen: String;
    Melee: Boolean;
  begin
    Result := TStringList.Create;
    Gen := Generique;
    // les emplacements de carriere portent une etoile en fin de code (« __* ») : on la retire
    if (Gen <> '') and (Gen[Length(Gen)] = '*') then Delete(Gen, Length(Gen), 1);
    if Gen = 'RULES-TRAP_TRADE_TOOLS__' then
      begin
        TowChargeArmes;
        for I := 0 to CacheOutils.Count - 1 do
          begin
            P1 := Pos('|', CacheOutils[I]);
            Ligne := Copy(CacheOutils[I], P1 + 1, 99);
            for P2 := 0 to High(TowLoresPerso) do
              if TowLoresPerso[P2] = Ligne then
                begin
                  Result.Add(Copy(CacheOutils[I], 1, P1 - 1));
                  Break;
                end;
          end;
        if Result.Count = 0 then
          for I := 0 to CacheOutils.Count - 1 do
            Result.Add(Copy(CacheOutils[I], 1, Pos('|', CacheOutils[I]) - 1));
        Exit;
      end;
    if (Gen <> 'RULES-TRAP_SILVER_WEAPON__') and (Gen <> 'RULES-TRAP_SILVER_MELEE_WEAPON__') and
       (Gen <> 'RULES-TRAP_BRASS_OR_SILVER_MELEE_WEAPON__') then Exit;
    Melee := Gen <> 'RULES-TRAP_SILVER_WEAPON__';
    TowChargeArmes;
    for I := 0 to CacheArmes.Count - 1 do
      begin
        Ligne := CacheArmes[I];
        P1 := Pos('|', Ligne);
        Cat := Copy(Ligne, P1 + 1, 99);
        P2 := Pos('|', Cat);
        Cout := Copy(Cat, P2 + 1, 99);
        Cat := Copy(Cat, 1, P2 - 1);
        if (Cout <> 'BRASS') and (Cout <> 'SILVER') then Continue;
        if Melee and (Cat <> 'MELEE') then Continue;
        Result.Add(Copy(Ligne, 1, P1 - 1));
      end;
  end;

// Un code par emplacement : Choix[i] s il est valide, sinon hasard. Cible 0 = equipement, 1 = atouts.
function ChoisitLignes(var P: StructurePersonnage; const Slots: TTowSlots; Choix: TStringList; Cible: Integer): Integer;
  var
    I, K, N: Integer;
    Code: String;
    Armes: TStringList;
  begin
    Result := 0;
    for I := 0 to High(Slots) do
      begin
        if Length(Slots[I]) = 0 then Continue;
        Code := '';
        if (Choix <> nil) and (I < Choix.Count) then
          for K := 0 to High(Slots[I]) do
            if Slots[I][K] = Choix[I] then Code := Choix[I];
        if Code = '' then
          begin
            Code := Slots[I][Random(Length(Slots[I]))];
            Inc(Result);
          end;
        if Cible = 0 then
          begin
            // generique d arme : l arme nommee (choix du joueur, sinon hasard parmi celles qui conviennent)
            // est enregistree comme une vraie ligne d equipement, avec son propre code (comme V1-V5)
            Armes := TowArmesPour(Code);
            try
              if Armes.Count > 0 then
                begin
                  if (I <= High(TowEqPrecis)) and (Armes.IndexOf(TowEqPrecis[I]) >= 0) then
                    N := TowAjouteEquip(P, TowEqPrecis[I], '')
                  else
                    N := TowAjouteEquip(P, Armes[Random(Armes.Count)], '');
                end
              else
                N := TowAjouteEquip(P, Code, '');
            finally
              Armes.Free;
            end;
          end
        else
          begin
            TowAjouteLigne(P, 'ASSET', Code, '', '');
          end;
      end;
  end;

function TowChoisitEquipement(var P: StructurePersonnage; const Slots: TTowSlots; Choix: TStringList): Integer;
  begin
    Result := ChoisitLignes(P, Slots, Choix, 0);
  end;

function TowChoisitAtouts(var P: StructurePersonnage; const Slots: TTowSlots; Choix: TStringList): Integer;
  begin
    Result := ChoisitLignes(P, Slots, Choix, 1);
  end;

function TowChargeAtoutsAleatoires(const Dossier: String): TTowAtoutsAleatoires;
  var
    IL:   Integer;
    Doc: TXMLDocument;
    Liste, N, Col: TDOMNode;
    Plage: String;
    P: Integer;
    R: TTowAtoutAleatoire;
  begin
    SetLength(Result, 0);
    TowOuvreLivres(IncludeTrailingPathDelimiter(Dossier));
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              if (Liste.NodeType = ELEMENT_NODE) and (Liste.NodeName = 'DATA_RANDOM_ASSET') then
                begin
                  N := Liste.FirstChild;
                  while N <> nil do
                    begin
                      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Row') then
                        begin
                          R := Default(TTowAtoutAleatoire);
                          Plage := TDOMElement(N).GetAttribute('range');
                          P := Pos('-', Plage);
                          if P > 0 then
                            begin
                              R.De := StrToIntDef(Copy(Plage, 1, P - 1), 0);
                              R.A := StrToIntDef(Copy(Plage, P + 1, 9), 0);
                            end
                          else
                            begin
                              R.De := StrToIntDef(Plage, 0);
                              R.A := R.De;
                            end;
                          Col := N.FirstChild;
                          while Col <> nil do
                            begin
                              if Col.NodeType = ELEMENT_NODE then
                                begin
                                  if Col.NodeName = 'Brass' then R.Brass := TDOMElement(Col).GetAttribute('name');
                                  if Col.NodeName = 'Silver' then R.Silver := TDOMElement(Col).GetAttribute('name');
                                  if Col.NodeName = 'Gold' then R.Gold := TDOMElement(Col).GetAttribute('name');
                                end;
                              Col := Col.NextSibling;
                            end;
                          SetLength(Result, Length(Result) + 1);
                          Result[High(Result)] := R;
                        end;
                      N := N.NextSibling;
                    end;
                end;
              Liste := Liste.NextSibling;
            end;
  end;
  end;

function TowChargeSorts(const Dossier: String): TTowSorts;
  var
    IL:   Integer;
    Doc: TXMLDocument;
    Liste, N, L: TDOMNode;
    S: TTowSort;
  begin
    SetLength(Result, 0);
    TowOuvreLivres(IncludeTrailingPathDelimiter(Dossier));
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              if (Liste.NodeType = ELEMENT_NODE) and (Liste.NodeName = 'DATA_SPELL') then
                begin
                  N := Liste.FirstChild;
                  while N <> nil do
                    begin
                      if (N.NodeType = ELEMENT_NODE) and (N.NodeName = 'Spell') then
                        begin
                          S.Code := TDOMElement(N).GetAttribute('id');
                          S.Lore := '';
                          L := N.FirstChild;
                          while L <> nil do
                            begin
                              if (L.NodeType = ELEMENT_NODE) and (L.NodeName = 'Lore') then
                                S.Lore := TDOMElement(L).GetAttribute('name');
                              L := L.NextSibling;
                            end;
                          SetLength(Result, Length(Result) + 1);
                          Result[High(Result)] := S;
                        end;
                      N := N.NextSibling;
                    end;
                end;
              Liste := Liste.NextSibling;
            end;
  end;
  end;

procedure TowSortsDepart(var P: StructurePersonnage; const Sorts: TTowSorts; const C: TTowCarriere);
  var
    I, K, N: Integer;
    Lore, Etat: String;
    Candidats: array of Integer;
    T: Integer;
  begin
    I := TowIndexTalent(P, 'RULES-T_WIZARD');
    if I < 0 then Exit;
    Lore := P.CreationTalent[I].ChoixTow;
    if C.Code = 'RULES-WORK_ARCANE_WIZARD' then Etat := 'FORMALISED'
    else if C.Code = 'RULES-WORK_HEDGE_WIZARD' then Etat := 'MEMORISED'
    else Exit;
    SetLength(Candidats, 0);
    for K := 0 to High(Sorts) do
      if Sorts[K].Lore = Lore then
        begin
          SetLength(Candidats, Length(Candidats) + 1);
          Candidats[High(Candidats)] := K;
        end;
    // 3 sorts sans doublon (moins s il n y en a pas autant)
    N := 0;
    while (N < 3) and (Length(Candidats) > 0) do
      begin
        K := Random(Length(Candidats));
        T := TowAjouteSort(P, Sorts[Candidats[K]].Code, Etat);
        Candidats[K] := Candidats[High(Candidats)];
        SetLength(Candidats, Length(Candidats) - 1);
        Inc(N);
      end;
  end;

function TowVieEnDisgrace(var P: StructurePersonnage): Integer;
  begin
    Result := 0;
    if P.StatusTow = 'GOLD' then P.StatusTow := 'SILVER'
    else if P.StatusTow = 'SILVER' then P.StatusTow := 'BRASS'
    else Exit;
    Result := 1;
  end;

function TowDernierBonus(var P: StructurePersonnage; const O: TTowOrigine; const Table: TTowAtoutsAleatoires;
  Mode: Integer; Paye: Boolean): Integer;
  var
    I, K, Jet, Essais, N: Integer;
    Statut, Code: String;
    A3, A2: array of Integer;
  begin
    if Mode = 0 then Mode := Random(3) + 1;
    Result := Mode;
    if Mode = 1 then
      begin
        SetLength(A3, 0);
        SetLength(A2, 0);
        for I := 0 to High(P.CreationCompetence35) do
          begin
            if P.CreationCompetence35[I].Valeur = 3 then
              begin
                SetLength(A3, Length(A3) + 1);
                A3[High(A3)] := I;
              end;
            if P.CreationCompetence35[I].Valeur = 2 then
              begin
                SetLength(A2, Length(A2) + 1);
                A2[High(A2)] := I;
              end;
          end;
        if (Length(A3) > 0) and ((Length(A2) < 2) or (Random(2) = 0)) then
          Inc(P.CreationCompetence35[A3[Random(Length(A3))]].Valeur)
        else
          begin
            // deux competences differentes de 2 a 3
            for N := 1 to 2 do
              if Length(A2) > 0 then
                begin
                  K := Random(Length(A2));
                  Inc(P.CreationCompetence35[A2[K]].Valeur);
                  A2[K] := A2[High(A2)];
                  SetLength(A2, Length(A2) - 1);
                end;
          end;
      end
    else if Mode = 2 then
      begin
        // un talent de plus sur la table de l origine (doublon relance ; Faith impossible avec Wizard)
        Essais := 0;
        while Essais < 200 do
          begin
            Inc(Essais);
            if (TowJetTalentFinal >= 1) and (TowJetTalentFinal <= 10) and (Essais = 1) then Jet := TowJetTalentFinal
            else Jet := Random(10) + 1;
            Code := '';
            for K := 0 to High(O.TableTalents) do
              if (Jet >= O.TableTalents[K].De) and (Jet <= O.TableTalents[K].A) then Code := O.TableTalents[K].Code;
            if (Code = '') or (TowIndexTalent(P, Code) >= 0) then Continue;
            if (Code = 'RULES-T_FAITH') and (P.WizardLevelTow > 0) then Continue;
            TowAjouteTalent(P, Code, 'final');
            TowPrecisionTouched(P, '');
            if Code = 'RULES-T_FAITH' then
              P.CreationTalent[TowIndexTalent(P, Code)].ChoixTow := TowDieux[Random(Length(TowDieux))];
            Break;
          end;
      end
    else
      begin
        // atout aleatoire : colonne du Status, un cran plus haut contre 1 XP
        Statut := P.StatusTow;
        if Paye then
          begin
            if Statut = 'BRASS' then Statut := 'SILVER'
            else if Statut = 'SILVER' then Statut := 'GOLD';
            Dec(P.XpActuel);   // XP depense = XpTotal - XpActuel
          end;
        if (TowJetAtoutFinal >= 1) and (TowJetAtoutFinal <= 100) then Jet := TowJetAtoutFinal
        else Jet := Random(100) + 1;
        for K := 0 to High(Table) do
          if (Jet >= Table[K].De) and (Jet <= Table[K].A) then
            begin
              if Statut = 'GOLD' then Code := Table[K].Gold
              else if Statut = 'SILVER' then Code := Table[K].Silver
              else Code := Table[K].Brass;
              TowAjouteLigne(P, 'ASSET', Code, '', 'FINAL');
              Break;
            end;
      end;
  end;

function ListeDe(const A: array of String; De, Nb: Integer): TStringList;
  var I: Integer;
  begin
    Result := TStringList.Create;
    for I := De to De + Nb - 1 do
      if I <= High(A) then Result.Add(A[I]) else Result.Add('');
  end;

procedure TowPoseDebut(var P: StructurePersonnage; const O: TTowOrigine; const C: TTowCarriere; AvecCarriere: Boolean;
  const Plus: array of Integer);
  var
    D: StructurePersonnage;
    I: Integer;
  begin
    D := TowCommencer(O, P.NomPersonnage);
    for I := 1 to TowNbCarac do
      if (I - 1 <= High(Plus)) and (Plus[I - 1] > 0) then TowAjouteUn(D, O, I);
    P.Race             := D.Race;
    P.HeightUnit       := D.HeightUnit;
    P.CreationAttribut := D.CreationAttribut;
    P.FateTow          := D.FateTow;
    P.FortuneTow       := D.FortuneTow;
    if AvecCarriere then TowFixeCarriere(P, C)
    else P.MetierEnCours.NiveauMetier := 1;
  end;

// Phase 4 : talents d origine (fixes, tires, un seul remplace par l echange, precisions Touched / Faith).
procedure TowPoseTalents(var P: StructurePersonnage; const O: TTowOrigine; const TalTires: array of String; TalEchange: Integer);
  var
    I, K: Integer;
    Code: String;
  begin
    SetLength(P.CreationTalent, 0);
    for I := 0 to High(O.TalentsFixes) do
      TowAjouteTalent(P, O.TalentsFixes[I], 'origin');
    for I := 0 to High(TalTires) do
      begin
        Code := TalTires[I];
        if (I = TalEchange) and (O.TalentEchange <> '') then Code := O.TalentEchange;
        TowAjouteTalent(P, Code, 'origin');
      end;
    TowPrecisionTouched(P, '');
    K := -1;
    for I := 0 to High(P.CreationTalent) do
      if (P.CreationTalent[I].CodeTalent = 'RULES-T_FAITH') and (P.CreationTalent[I].ChoixTow = '') then K := I;
    if K >= 0 then P.CreationTalent[K].ChoixTow := TowDieux[Random(Length(TowDieux))];
  end;

// Phases 5 et 6 : competences et lores. AvecCarriere = False a la phase 5 (competences et lores d origine seulement).
// Repart de zero (rangs de depart, lores vides), puis remet la lore du talent Touched by the Winds s il y en a une.
procedure TowPoseCompetences(var P: StructurePersonnage; const O: TTowOrigine; const C: TTowCarriere; AvecCarriere: Boolean;
  const Libres, CompCar, LoreChoix: array of String);
  var
    L: TStringList;
    I, J, K: Integer;
    Deja: Boolean;
  begin
    SetLength(P.LoresTow, 0);
    TowInitCompetences(P);
    L := ListeDe(Libres, 0, Length(Libres));
    try TowCompetencesOrigine(P, O, L); finally L.Free; end;
    L := ListeDe(LoreChoix, 0, Length(O.LoreSlots));
    try TowChoisitLores(P, O.LoreSlots, L); finally L.Free; end;
    if AvecCarriere then
      begin
        L := ListeDe(CompCar, 0, Length(CompCar));
        try TowCompetencesCarriere(P, C, L); finally L.Free; end;
        L := ListeDe(LoreChoix, Length(O.LoreSlots), Length(C.LoreSlots));
        try TowChoisitLores(P, C.LoreSlots, L); finally L.Free; end;
      end;
    // lore « (specify) » precisee dans la fenetre : le generique prend la lore choisie
    for I := 0 to High(TowLorePrecis) do
      if (TowLorePrecis[I] <> '') and (I <= High(LoreChoix)) and (Copy(LoreChoix[I], Length(LoreChoix[I]) - 2, 3) = '__*') then
        begin
          K := -1;
          for J := 0 to High(P.LoresTow) do
            if P.LoresTow[J].Code = LoreChoix[I] then K := J;
          if K >= 0 then
            begin
              Deja := False;
              for J := 0 to High(P.LoresTow) do
                if P.LoresTow[J].Code = TowLorePrecis[I] then Deja := True;
              if Deja then
                begin
                  for J := K to High(P.LoresTow) - 1 do P.LoresTow[J] := P.LoresTow[J + 1];
                  SetLength(P.LoresTow, Length(P.LoresTow) - 1);
                end
              else
                P.LoresTow[K].Code := TowLorePrecis[I];
            end;
        end;
    // lore du talent Touched by the Winds (effacee avec les lores) : sa precision est deja choisie, rien n est tire
    TowPrecisionTouched(P, '');
  end;

function TowAssemble(const O: TTowOrigine; const C: TTowCarriere; const Nom: String; const Plus: array of Integer;
  const Libres, CompCar, TalTires, LoreChoix, EqChoix, AtChoix, ContFam, ContNpc, ContTxt, SortsCodes: array of String;
  TalEchange: Integer; const PrecCarriere: String; const Sorts: TTowSorts; const Table: TTowAtoutsAleatoires;
  Disgrace: Boolean; Bonus: Integer; PayeBonus: Boolean): StructurePersonnage;
  var
    P: StructurePersonnage;
  begin
    P := Default(StructurePersonnage);
    TowPoseDebut(P, O, C, True, Plus);
    TowPoseTalents(P, O, TalTires, TalEchange);
    TowPoseCompetences(P, O, C, True, Libres, CompCar, LoreChoix);
    TowPoseEquipement(P, C, EqChoix, AtChoix, ContFam, ContNpc, ContTxt, SortsCodes, PrecCarriere, Sorts);
    TowPoseFin(P, O, Nom, Table, Disgrace, Bonus, PayeBonus);
    Result := P;
  end;

procedure TowPoseEquipement(var P: StructurePersonnage; const C: TTowCarriere;
  const EqChoix, AtChoix, ContFam, ContNpc, ContTxt, SortsCodes: array of String;
  const PrecCarriere: String; const Sorts: TTowSorts);
  var
    L: TStringList;
    I, N: Integer;
    Famille, Texte: String;
  begin
    // repart de zero : contacts / atouts, equipement et sorts (le talent de carriere s ajoute aux talents d origine)
    SetLength(P.LignesTow, 0);
    SetLength(P.Equipement, 0);
    // talents d origine, competences et lores : deja poses par TowPoseTalents / TowPoseCompetences (phases 4 a 6)
    TowTalentCarriere(P, C, PrecCarriere);
    TowLoreFavorite(P);
    // contacts
    for I := 0 to High(ContNpc) do
      begin
        Famille := '';
        Texte   := '';
        if I <= High(ContFam) then Famille := ContFam[I];
        if I <= High(ContTxt) then Texte   := ContTxt[I];
        TowAjouteLigne(P, 'CONTACT', ContNpc[I], Famille, Texte);
      end;
    // equipement, atouts, sorts de depart
    L := ListeDe(EqChoix, 0, Length(EqChoix));
    try TowChoisitEquipement(P, C.TrappingSlots, L); finally L.Free; end;
    L := ListeDe(AtChoix, 0, Length(AtChoix));
    try TowChoisitAtouts(P, C.AssetSlots, L); finally L.Free; end;
    TowSortsDepart(P, Sorts, C);
    N := TowNbSorts(P);
    for I := 0 to High(SortsCodes) do
      if (I < N) and (SortsCodes[I] <> '') then P.Equipement[TowIndexSort(P, I)].CodeEquipement := SortsCodes[I];
  end;

// Phase 8 : nom, Life in Disgrace, dernier bonus (Final Steps).
procedure TowPoseFin(var P: StructurePersonnage; const O: TTowOrigine; const Nom: String;
  const Table: TTowAtoutsAleatoires; Disgrace: Boolean; Bonus: Integer; PayeBonus: Boolean);
  begin
    P.NomPersonnage := Nom;
    if Disgrace then TowVieEnDisgrace(P);
    TowDernierBonus(P, O, Table, Bonus, PayeBonus);
  end;

var
  CacheOrigines:  TTowOrigines;
  CacheCarrieres: TTowCarrieres;
  CacheOk:        Boolean = False;
  CacheLibelles:  TStringList = nil;
  CacheExplications: TStringList = nil;

procedure TowChargeCaches;
  begin
    if CacheOk then Exit;
    CacheOk := True;
    CacheOrigines  := TowChargeOrigines(GetCurrentDir + '/DATABASE/WFRPTOW');
    CacheCarrieres := TowChargeCarrieres(GetCurrentDir + '/DATABASE/WFRPTOW');
  end;

function TowOriginesCache: TTowOrigines;
  begin
    TowChargeCaches;
    Result := CacheOrigines;
  end;

function TowCarrieresCache: TTowCarrieres;
  begin
    TowChargeCaches;
    Result := CacheCarrieres;
  end;

// Tous les elements a attribut id et sous-element Description des listes DATA_* des livres TOW.
procedure TowChargeLibellesCache;
  var
    IL:   Integer;
    Doc:  TXMLDocument;
    Liste, N, Sub: TDOMNode;
    Id, Opt, Txt, Gen: String;
  begin
    if CacheLibelles <> nil then Exit;
    CacheLibelles := TStringList.Create;
    CacheExplications := TStringList.Create;
    CacheTalentCout   := TStringList.Create;
    CacheTalentExig   := TStringList.Create;
    CacheTalentMax    := TStringList.Create;
    CacheTalentOpt    := TStringList.Create;
    TowOuvreLivres(GetCurrentDir + '/DATABASE/WFRPTOW/');
    for IL := 0 to TowNbLivres - 1 do
      begin
        Doc := TowLivreDoc(IL);
          Liste := Doc.DocumentElement.FirstChild;
          while Liste <> nil do
            begin
              if (Liste.NodeType = ELEMENT_NODE) and (Copy(Liste.NodeName, 1, 5) = 'DATA_') then
                begin
                  N := Liste.FirstChild;
                  while N <> nil do
                    begin
                      if N.NodeType = ELEMENT_NODE then
                        begin
                          Id := TDOMElement(N).GetAttribute('id');
                          if (Id <> '') and (Chaine(N, 'Description') <> '') then
                            begin
                              CacheLibelles.Values[Id] := Chaine(N, 'Description');
                              if Chaine(N, 'Explanation') <> '' then
                                CacheExplications.Values[Id] := Chaine(N, 'Explanation');
                              // talent : cout en XP et exigences (Cost / Requirement type=... name=...)
                              if N.NodeName = 'Talent' then
                                begin
                                  CacheTalentCout.Values[Id] := Chaine(N, 'Cost');
                                  CacheTalentMax.Values[Id]  := Chaine(N, 'MaxPurchases');
                                  Gen := '';
                                  Sub := N.FirstChild;
                                  while Sub <> nil do
                                    begin
                                      // <Option name="RULES-FAMILIAR_FLIGHT">"Flight: The familiar can fly."</Option> :
                                      // libelle = texte avant « : », explication = texte apres
                                      if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'Option') then
                                        begin
                                          Opt := TDOMElement(Sub).GetAttribute('name');
                                          Txt := StringReplace(Trim(Sub.TextContent), '"', '', [rfReplaceAll]);
                                          if Opt <> '' then
                                            begin
                                              if Pos(':', Txt) > 0 then
                                                begin
                                                  CacheLibelles.Values[Opt]     := Trim(Copy(Txt, 1, Pos(':', Txt) - 1));
                                                  CacheExplications.Values[Opt] := Trim(Copy(Txt, Pos(':', Txt) + 1, 2000));
                                                end
                                              else
                                                CacheLibelles.Values[Opt] := Txt;
                                              CacheTalentOpt.Values[Id] := CacheTalentOpt.Values[Id] + Opt + ';';
                                            end;
                                        end;
                                      if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'Requirement') then
                                        begin
                                          if Gen <> '' then Gen := Gen + ';';
                                          Gen := Gen + TDOMElement(Sub).GetAttribute('type') + ':' + TDOMElement(Sub).GetAttribute('name')
                                                 + '=' + StringReplace(Trim(Sub.TextContent), '"', '', [rfReplaceAll]);
                                        end;
                                      Sub := Sub.NextSibling;
                                    end;
                                  if Gen <> '' then CacheTalentExig.Values[Id] := Gen;
                                end;
                              // lore generique a options (ville, culte, province...) : « City Lore (Talagaad) »
                              if N.NodeName = 'Lore' then
                                begin
                                  Sub := N.FirstChild;
                                  while Sub <> nil do
                                    begin
                                      if (Sub.NodeType = ELEMENT_NODE) and (Sub.NodeName = 'Option') then
                                        begin
                                          Opt := TDOMElement(Sub).GetAttribute('name');
                                          Txt := StringReplace(Trim(Sub.TextContent), '"', '', [rfReplaceAll]);
                                          Gen := StringReplace(Chaine(N, 'Description'), ' (specify)', '', []);
                                          if (Opt <> '') and (Txt <> '') and (CacheLibelles.Values[Opt] = '') then
                                            CacheLibelles.Values[Opt] := Gen + ' (' + Txt + ')';
                                        end;
                                      Sub := Sub.NextSibling;
                                    end;
                                end;
                            end;
                        end;
                      N := N.NextSibling;
                    end;
                end;
              Liste := Liste.NextSibling;
            end;
  end;
  end;

function TowLibelleDe(const Code: String): String;
  var C: String;
  begin
    // Talents, competences, armes et armures sont deja charges par le moteur commun (XmlImport) :
    // leur libelle vient de ses listes ; le cache TOW ne sert que pour les codes propres a TOW.
    Result := '';
    if (Code <> '') and (Pos('*', Code) = 0) then
      begin
        if Assigned(ListTalent) and (Pos('RULES-T_', Code) = 1) then
          Result := ChercheTalent(Code).Libelle
        else if Assigned(ListCompetence) and (Pos('RULES-COMP_', Code) = 1) then
          Result := ChercheCompetence(Code).Libelle
        else if Assigned(ListArme) and ((Pos('RULES-COMB_', Code) = 1) or (Pos('RULES-PROJ_', Code) = 1)) then
          Result := ChercheArme(Code).Libelle
        else if Assigned(ListArmure) and (Pos('RULES-ARMO_', Code) = 1) then
          Result := ChercheArmure(Code).Libelle;
        if Result <> '' then Exit;
      end;
    TowChargeLibellesCache;
    C := Code;
    Result := CacheLibelles.Values[C];
    // emplacement generique « RULES-LORE_CITY__* » : libelle du generique « ...__ »
    if (Result = '') and (Copy(C, Length(C), 1) = '*') then
      Result := CacheLibelles.Values[Copy(C, 1, Length(C) - 1)];
    if Result = '' then Result := C;
  end;

function TowExplicationDe(const Code: String): String;
  begin
    Result := '';
    if Assigned(ListTalent) and (Pos('*', Code) = 0) and (Pos('RULES-T_', Code) = 1) then
      Result := ChercheTalent(Code).Description;
    if Result <> '' then Exit;
    TowChargeLibellesCache;
    Result := CacheExplications.Values[Code];
    if (Result = '') and (Copy(Code, Length(Code), 1) = '*') then
      Result := CacheExplications.Values[Copy(Code, 1, Length(Code) - 1)];
  end;

// Texte stable, une ligne par valeur (aller-retour XML, scripts tow_*) ; meme format qu avant le regroupement
function PersonnageTowDump(const P: StructurePersonnage): TStringList;
  var I: Integer;
  begin
    Result := TStringList.Create;
    Result.Add('PERSONNAGE ' + P.NomPersonnage);
    Result.Add('IDENTITE origine=' + P.Race + ' carriere=' + P.MetierEnCours.CodeMetier + ' status=' + P.StatusTow
      + ' niveau-status=' + IntToStr(P.StatusNiveauTow) + ' xp=' + IntToStr(P.XpTotal)
      + ' xp-depense=' + IntToStr(P.XpTotal - P.XpActuel) + ' fate=' + IntToStr(P.FateTow)
      + ' fortune=' + IntToStr(P.FortuneTow) + ' wizard=' + IntToStr(P.WizardLevelTow));
    for I := 0 to High(P.CreationAttribut) do
      Result.Add('CARAC ' + P.CreationAttribut[I].CodeAttribut + ' valeur=' + IntToStr(P.CreationAttribut[I].Valeur));
    for I := 0 to High(P.CreationCompetence35) do
      Result.Add('COMPETENCE ' + P.CreationCompetence35[I].CodeCompetence + ' rang=' + IntToStr(P.CreationCompetence35[I].Valeur)
        + ' ticks=' + IntToStr(P.CreationCompetence35[I].TicksTow));
    for I := 0 to High(P.CreationTalent) do
      Result.Add('TALENT ' + P.CreationTalent[I].CodeTalent + ' rang=' + IntToStr(P.CreationTalent[I].Valeur)
        + ' choix=' + P.CreationTalent[I].ChoixTow + ' source=' + P.CreationTalent[I].SourceTow);
    for I := 0 to High(P.LoresTow) do
      Result.Add('LORE ' + P.LoresTow[I].Code + ' ' + P.LoresTow[I].Texte);
    for I := 0 to High(P.Equipement) do
      if P.Equipement[I].TypeEquipement <> TrimRight(TypeEquipSp) then
        Result.Add('OBJET ' + P.Equipement[I].CodeEquipement + ' ' + P.Equipement[I].TexteTow);
    for I := 0 to High(P.LignesTow) do
      if P.LignesTow[I].Genre = 'ASSET' then
        begin
          Result.Add('ATOUT ' + P.LignesTow[I].Code + ' ' + P.LignesTow[I].Texte);
          if TowObjetDeAsset(P.LignesTow[I].Code) <> '' then
            Result.Add('OBJET-ATOUT ' + P.LignesTow[I].Code + ' -> ' + TowObjetDeAsset(P.LignesTow[I].Code));
        end;
    for I := 0 to High(P.Equipement) do
      if P.Equipement[I].TypeEquipement = TrimRight(TypeEquipSp) then
        Result.Add('SORT ' + P.Equipement[I].CodeEquipement + ' ' + P.Equipement[I].TexteTow);
    for I := 0 to High(P.LignesTow) do
      if P.LignesTow[I].Genre = 'CONTACT' then
        Result.Add('CONTACT famille=' + P.LignesTow[I].Famille + ' nom=' + P.LignesTow[I].Code + ' ' + P.LignesTow[I].Texte);
    if P.GrimPortentTow <> '' then Result.Add('GRIM-PORTENT ' + P.GrimPortentTow);
    if P.NotesTow <> '' then Result.Add('NOTES ' + P.NotesTow);
  end;

end.

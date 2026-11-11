unit ChargeRaceMetier;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, ChargeMetier, Generics.Collections, ChargeRace, ChargeEspece, UnitCalcul;

Type
    StructureRaceMetier	= Record
	CodeMetier:	String;
	Chance:	        String;
	CodeRace:	String;
        Livre:          String;
End;

  TListRaceMetier = specialize TList<StructureRaceMetier>;

  // Ce que les livres DECLARENT, tel quel : jamais developpe par ethnie ni propage (a la
  // difference de ListRaceMetier, transformee apres chargement par CompleteRaceMetierParEspece).
  // Sert a l'export, qui doit reecrire ce que l'auteur a ecrit, et a la forme ou il l'a ecrit.
  StructureRaceMetierSource = Record
    Forme:      Integer;
    Livre:      String;
    CodeRace:   String;
    CodeMetier: String;
    Chance:     String;
  End;
  TListRaceMetierSource = specialize TList<StructureRaceMetierSource>;

Const
  FormeRaceMetierBlocEspece  = 0;  // <Specie>/SUBCHAPTER_CAREER/<Career name>chance
  FormeRaceMetierData        = 1;  // DATA_CAREER_SPECIE/<Entry>
  FormeRaceMetierFicheMetier = 2;  // <Career>/<Specie>code
  FormeRaceMetierSousChapitre = 3; // <Career>/SUBCHAPTER_SPECIE/<Specie name>chance

Var
  ListRaceMetier:   TListRaceMetier;
  ListRaceMetierSource: TListRaceMetierSource;
  NbRaceMetier:     Integer;

Function VerifieRaceMetier(RaceChoisie: String; MetierAVerifier: String):Boolean;
Function MetierRaceCourt(MetierActuel: String):String;
Function MetierRaceNbSuivant(RaceEnCours:String; MetierEnCours: String):Integer;
Procedure CompleteRaceMetierParEspece;
Procedure AjouteRaceMetierSiAbsent(Livre, CodeRace, CodeMetier: String);
Procedure AjouteRaceMetierSource(Forme: Integer; Livre, CodeRace, CodeMetier, Chance: String);

implementation

type
  TEnsembleCodes = specialize TDictionary<String, Byte>;

Procedure AjouteRaceMetierSource(Forme: Integer; Livre, CodeRace, CodeMetier, Chance: String);
  var
    PSource: StructureRaceMetierSource;
  begin
    PSource.Forme      := Forme;
    PSource.Livre      := Livre;
    PSource.CodeRace   := CodeRace;
    PSource.CodeMetier := CodeMetier;
    PSource.Chance     := Chance;
    ListRaceMetierSource.Add(PSource);
  end;

// Un metier peut porter ses races dans sa propre fiche (<Specie> dans <Career>) : l'auteur
// donne une race (toutes ses ethnies, developpees apres chargement) ou une ethnie precise.
// Meme entree 'X' que DATA_CAREER_SPECIE ; pas de doublon si le metier est aussi
// declare par l'une des autres ecritures.
Procedure AjouteRaceMetierSiAbsent(Livre, CodeRace, CodeMetier: String);
  var
    PExistant: StructureRaceMetier;
    PNouveau:  StructureRaceMetier;
  begin
    For PExistant in ListRaceMetier do
      if (PExistant.CodeRace = CodeRace) and (PExistant.CodeMetier = CodeMetier) then
        exit;
    PNouveau.Livre      := Livre;
    PNouveau.CodeRace   := CodeRace;
    PNouveau.CodeMetier := CodeMetier;
    PNouveau.Chance     := 'X';
    ListRaceMetier.Add(PNouveau);
    inc(NbRaceMetier);
  end;

// Tout métier accessible à une ethnie l'est pour toutes les ethnies de la même RACE
// (décision Nono du 20/08/2026) : un Humain de Middenheim doit pouvoir choisir un métier
// déclaré sur le Reiklander. Seule l'ACCESSIBILITE se propage, jamais la table de jet d100 :
// les entrées ajoutées le sont toujours en 'X' (éligible hors tirage), donc les fourchettes
// de dés propres à chaque région restent intactes (ChargeTabMetier exclut déjà les 'X').
//
// A appeler APRES le chargement de TOUS les livres : au moment où un livre est lu, les
// ethnies déclarées par les autres livres ne sont pas forcément encore dans ListRace
// (l'ordre de FindFirst/FindNext n'est pas garanti - voir CONTEXT.md §2.9).
//
// Deux phases : (1) développer les entrées ciblant une RACE en une entrée par ethnie,
// (2) propager l'accessibilité entre ethnies d'une même race.
Procedure CompleteRaceMetierParEspece;
  var
    Existant:     TEnsembleCodes;
    AvecTirage:   TStringList;
    Donneur:      TStringList;
    NbInitial:    Integer;
    Ind:          Integer;
    PSource:      StructureRaceMetier;
    PNouveau:     StructureRaceMetier;
    PRaceCible:   StructureRace;
    EspeceSource: String;
    Cle:          String;
    CleEspece:    String;
    NbRaces:      Integer;
    IndRace:      Integer;
    IndCache:     Integer;
    IndTrouve:    Integer;
    CacheCode:    TStringList;
    RaceCode, RaceCodeCourt, RaceEspeceCourt: array of String;

  // Normalisation identique à DecoupeCodeValeur (UnitCalcul), mais en local : passer par
  // CompareRechercheValeur écraserait les variables globales CodeValeur/CodeRecherche,
  // dont dépendent d'autres traitements (CheminMetierImage notamment).
  Function CodeSansLivre(Code: String): String;
    begin
      if Pos(SeparateurLivre, Code) > 0 then
        Result := ExtractStringAfter(Code, SeparateurLivre)
      else
        Result := Code;
    end;

  begin
    Existant   := TEnsembleCodes.Create;
    AvecTirage := TStringList.Create;
    Donneur    := TStringList.Create;
    CacheCode  := TStringList.Create;
    CacheCode.Sorted := True;
    try
      // CaseSensitive avant Sorted : la comparaison insensible a la casse est celle de la
      // locale Windows (lente) et IndexOf est appele des dizaines de milliers de fois ;
      // les codes sont ecrits avec une casse unique.
      AvecTirage.CaseSensitive := True;
      CacheCode.CaseSensitive := True;
      For PSource in ListRaceMetier do
        Existant.AddOrSetValue(PSource.CodeRace + '|' + PSource.CodeMetier, 1);

      // Codes de ListRace calcules une fois : les boucles ci-dessous parcouraient toute la
      // liste (copie de l'enregistrement + CodeSansLivre) pour CHAQUE entree de
      // ListRaceMetier, ce qui coutait 300 a 500 ms au demarrage.
      NbRaces := ListRace.Count;
      SetLength(RaceCode, NbRaces);
      SetLength(RaceCodeCourt, NbRaces);
      SetLength(RaceEspeceCourt, NbRaces);
      For Ind := 0 to NbRaces - 1 do
        begin
          PRaceCible          := ListRace[Ind];
          RaceCode[Ind]       := PRaceCible.CodeRace;
          RaceCodeCourt[Ind]  := CodeSansLivre(PRaceCible.CodeRace);
          RaceEspeceCourt[Ind] := CodeSansLivre(PRaceCible.Espece);
        end;

      // ---- Phase 1 : développer les entrées qui ciblent une RACE ----
      // DATA_CAREER_SPECIE accepte, comme DATA_CAREER_ROLL, un code de RACE
      // (RULES-SPECIE_HUMAN) aussi bien qu'un code d'ETHNIE (RULES-RACE_HUM). Les
      // consommateurs de ListRaceMetier (winmetier, VerifieRaceMetier, ChargeTabMetier)
      // comparent tous à l'ethnie du personnage : une entrée restée en code de race ne
      // matcherait jamais, sans le moindre message. On la remplace donc ici par une
      // entrée par ethnie concernée. Ce développement doit se faire APRES le chargement
      // de tous les livres, sinon les ethnies des autres livres manqueraient à l'appel.
      NbInitial := ListRaceMetier.Count;
      For Ind := NbInitial - 1 downto 0 do
        begin
          PSource := ListRaceMetier[Ind];
          if ChercheEspece(PSource.CodeRace).CodeEspece = '' then
            continue;
          CleEspece := CodeSansLivre(PSource.CodeRace);
          For IndRace := 0 to NbRaces - 1 do
            if RaceEspeceCourt[IndRace] = CleEspece then
              begin
                Cle := RaceCode[IndRace] + '|' + PSource.CodeMetier;
                if not Existant.ContainsKey(Cle) then
                  begin
                    PNouveau          := PSource;
                    PNouveau.CodeRace := RaceCode[IndRace];
                    ListRaceMetier.Add(PNouveau);
                    inc(NbRaceMetier);
                    Existant.AddOrSetValue(Cle, 1);
                  end;
              end;
          ListRaceMetier.Delete(Ind);
          dec(NbRaceMetier);
        end;

      // ---- Pré-calcul pour la phase 2 : qui a déjà une table de tirage, et qui la donne ----
      // Une ethnie qui n'a AUCUNE fourchette de dés à elle (cas du nain norse de Sea of
      // Claws, dont l'encadré p.41 ne donne que des compétences et des talents) doit
      // hériter de la table de sa RACE, et pas seulement de l'accessibilité en 'X' :
      // sans cela sa table de tirage est vide et le joueur n'a aucun métier à tirer
      // (bug trouvé au test par Nono le 25/08/2026). C'est le même principe que celui
      // déjà posé pour les règles dans ChargeRegle - "une ethnie non couverte par la
      // règle retombe sur la table par défaut" - appliqué cette fois aux ethnies.
      //
      // AvecTirage : les ethnies qui possèdent au moins une fourchette propre. Calculé
      // AVANT la phase 2, sinon la première fourchette héritée ferait basculer l'ethnie
      // dans cette liste et les suivantes repasseraient en 'X'.
      AvecTirage.Sorted     := True;
      AvecTirage.Duplicates := dupIgnore;
      For PSource in ListRaceMetier do
        if (PSource.Chance <> 'X') and (PSource.Chance <> SeparateurChance) then
          AvecTirage.Add(CodeSansLivre(PSource.CodeRace));

      // Donneur : pour chaque RACE, l'UNE de ses ethnies dont la table sera recopiée.
      // Il en faut une seule, sinon une ethnie sans table hériterait des fourchettes de
      // toutes ses soeurs à la fois et les plages se chevaucheraient (cas des Humains,
      // qui ont cinq ethnies avec chacune sa table). En cas de plusieurs candidates, on
      // retient celle qui vient du même livre que la RACE elle-même, c'est-à-dire
      // l'ethnie de référence - RULES-RACE_HUM pour les Humains, RULES-RACE_DWAR pour
      // les Nains. Choix déterministe, qui ne dépend donc pas de l'ordre de chargement
      // des livres (lequel n'est pas garanti, voir CONTEXT.md §2.9).
      For PRaceCible in ListRace do
        begin
          if AvecTirage.IndexOf(CodeSansLivre(PRaceCible.CodeRace)) < 0 then
            continue;
          CleEspece := CodeSansLivre(PRaceCible.Espece);
          if CleEspece = '' then
            continue;
          if (Donneur.Values[CleEspece] = '')
             or (PRaceCible.Livre = ChercheEspece(PRaceCible.Espece).Livre) then
            Donneur.Values[CleEspece] := CodeSansLivre(PRaceCible.CodeRace);
        end;

      // ---- Phase 2 : propager l'accessibilité entre ethnies d'une même race ----
      // borne figée avant la boucle : on ajoute dans la liste qu'on parcourt
      NbInitial := ListRaceMetier.Count;
      For Ind := 0 to NbInitial - 1 do
        begin
          PSource := ListRaceMetier[Ind];
          // une entrée explicitement indisponible ne se propage pas
          if PSource.Chance = SeparateurChance then
            continue;

          // Espece de la race source : un seul ChercheRace par code distinct (il parcourait
          // ListRace avec CompareRechercheValeur pour chacune des milliers d'entrees).
          IndCache := CacheCode.IndexOf(PSource.CodeRace);
          if IndCache < 0 then
            begin
              IndRace := -1;
              For IndTrouve := 0 to NbRaces - 1 do
                if CompareRechercheValeur(RaceCode[IndTrouve], PSource.CodeRace) then
                  begin
                    IndRace := IndTrouve;
                    break;
                  end;
              IndCache := CacheCode.AddObject(PSource.CodeRace, TObject(PtrInt(IndRace + 1)));
            end;
          IndRace := PtrInt(CacheCode.Objects[IndCache]) - 1;
          if IndRace >= 0 then
            EspeceSource := RaceEspeceCourt[IndRace]
          else
            EspeceSource := '';
          if EspeceSource = '' then
            continue;

          CleEspece := CodeSansLivre(PSource.CodeRace);
          For IndRace := 0 to NbRaces - 1 do
            begin
              if RaceEspeceCourt[IndRace] <> EspeceSource then
                continue;
              if RaceCodeCourt[IndRace] = CleEspece then
                continue;

              Cle := RaceCode[IndRace] + '|' + PSource.CodeMetier;
              // garde-fou anti-doublon : ChargerLivre peut être rappelée sans vider les listes
              if Existant.ContainsKey(Cle) then
                continue;

              PNouveau          := PSource;
              PNouveau.CodeRace := RaceCode[IndRace];
              // L'ethnie cible n'a pas de table à elle ET la source est l'ethnie de
              // référence de la race : on lui transmet la fourchette telle quelle, donc
              // sa vraie table de tirage. Dans tous les autres cas on garde le
              // comportement d'origine, 'X' = éligible hors tirage.
              if (AvecTirage.IndexOf(RaceCodeCourt[IndRace]) < 0)
                 and (Donneur.Values[RaceEspeceCourt[IndRace]] = CleEspece) then
                PNouveau.Chance := PSource.Chance
              else
                PNouveau.Chance := 'X';
              ListRaceMetier.Add(PNouveau);
              inc(NbRaceMetier);
              Existant.AddOrSetValue(Cle, 1);
            end;
        end;
    finally
      Existant.Free;
      AvecTirage.Free;
      Donneur.Free;
      CacheCode.Free;
    end;
  end;

// Cette ethnie peut-elle prendre ce metier ? C'est ce que le nom promet, et c'est desormais
// ce que la fonction fait.
//
// AVANT LE 01/09/2026 elle prenait un troisieme parametre, MetierActuel, et sa condition
// etait "(MetierActuel <> '') and (MetierActuel <> PRaceMetier.CodeMetier)" : elle renvoyait
// donc TOUJOURS FAUX si on lui passait une chaine vide. Son unique appelant lui passait '.',
// une valeur bidon choisie pour n'etre egale a aucun code - le contrat etait deja contourne
// au point d'appel. Le parametre a ete supprime et l'appelant nettoye.
//
// Piege bien reel : en ecrivant la liste de bifurcation des carrieres avancees
// (CONTEXT.md 2.24) j'allais m'en servir pour filtrer par ethnie ; elle aurait repondu faux
// partout, et le filtre n'aurait rien laisse passer.
Function VerifieRaceMetier(RaceChoisie: String; MetierAVerifier: String):Boolean;
  var
    PRaceMetier: StructureRaceMEtier;
    Trouve:      Boolean = false;
    RaceCouverte: Boolean = false;
  begin
    // Une ethnie qu'aucune table ne couvre (cas du Rulebook V5, qui n'a aucun lien ethnie ->
    // metier) n'a pas de liste fermee : tous les metiers lui sont ouverts.
    For PRaceMetier in ListRaceMetier do
      if CompareRechercheValeur(PRaceMetier.CodeRace, RaceChoisie) then
        begin
          RaceCouverte := true;
          break;
        end;
    if not RaceCouverte then
      begin
        Result := true;
        exit;
      end;
    For PRaceMetier in ListRaceMetier do
      if CompareRechercheValeur(PRaceMetier.CodeRace, RaceChoisie) and CompareRechercheValeur(PRaceMetier.CodeMetier, MetierAVerifier) then
        begin
          // Un 'X' compte : il veut dire "eligible hors tirage". Seul SeparateurChance,
          // qui signifie explicitement indisponible, exclut.
          Trouve := (PRaceMetier.Chance <> SeparateurChance);
          break;
        end;
    Result := Trouve;
  end;

Function MetierRaceCourt(MetierActuel: String):String;
  var
    PRaceMetier: StructureRaceMEtier;
    PRace:       StructureRace;
    List:        String = '';
    Espece:      String;
  begin
    For PRaceMetier in ListRaceMetier do
      if CompareRechercheValeur(PRaceMetier.CodeMetier, MetierActuel) then
        begin
          PRace := chercheRace(PRaceMetier.CodeRace);
          Espece:= ChercheEspece(PRace.Espece).Libelle;
          if Pos(Espece, List) = 0 then
            begin
              if List <> '' then
                List := List + ', ';
              List := List + Espece;
            end;
        end;
    Result := List;
  end;

Function MetierRaceNbSuivant(RaceEnCours:String; MetierEnCours: String):Integer;
  var
    PRaceMetier:   StructureRaceMEtier;
    PMetier:       StructureMetier;
    TrouveMetier:  Boolean = false;
    ClasseEnCours: String;
    NbApres:       Integer = 0;

  begin
    For PRaceMetier in ListRaceMetier do
      if CompareRechercheValeur(PRaceMetier.CodeRace, RaceEnCours) then
        begin
          if not TrouveMetier then
            begin
              if CompareRechercheValeur(PRaceMetier.CodeMetier, MetierEncours) then
                begin
                  TrouveMetier  := true;
                  PMetier       := ChercheMetier(PRaceMetier.CodeMetier);
                  ClasseEnCours := PMetier.LibelleGroupe;
                end
            end
          else
            begin
              PMetier := ChercheMetier(PRaceMetier.CodeMetier);
              if PMetier.LibelleGroupe = ClasseEnCours then
                if PRaceMetier.Chance <> 'X' then
                  NbApres := NbApres + 1;
            end;
        end;
    Result := NbApres;
  end;


end.


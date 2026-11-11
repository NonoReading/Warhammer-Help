unit ChargeRegle;

{$mode ObjFPC}{$H+}

interface

// Une REGLE est une variante optionnelle de règles apportée par un livre, que le joueur
// choisit au moment de la création (décision Nono du 20/08/2026). La première est la
// "Lustrian Class and Career Table" (Lustria p.192-193), qui remplace la table de tirage
// des métiers des pages 30-31 du livre de règles pour une campagne située en Lustria.
//
// Règles retenues avec Nono :
//  - La règle n'est PAS mémorisée dans le personnage : elle ne sert qu'à la création.
//    Une fois créé, le personnage voyage et peut apprendre un métier hors de sa règle.
//  - Elle ne retire jamais rien : son tirage remplace le d100 habituel, mais en choix
//    libre ses métiers s'AJOUTENT à ceux déjà accessibles (la table lustrienne ne liste
//    que les 64 métiers de base, elle ignore les métiers de suppléments accumulés en 'X').
//  - Une ethnie non couverte par la règle retombe sur la table par défaut.
//
// Les entrées de tirage vivent dans un bloc à plat (DATA_CAREER_ROLL) porté par le livre
// qui apporte la règle - jamais dans les <Specie> des autres livres, pour les mêmes raisons
// que DATA_CAREER_SPECIE (voir CONTEXT.md §2.9 et §2.10).
// CodeRace y désigne indifféremment une ETHNIE (RULES-RACE_HUM) ou une RACE
// (RULES-SPECIE_HUMAN) : la colonne "Old World Human" de Lustria couvre les cinq ethnies
// Humaines d'un coup.

uses
  Classes, SysUtils, Generics.Collections, UnitCalcul, ChargeRace, ChargeRaceTalent, ChargeRaceCompetence;

Type
  StructureRegle	= Record
	CodeRegle:	String;
	Libelle:	String;
	Livre:		String;
	// Classe de base remplacee par une regle PARTIELLE (vide = regle totale), voir ChargeTirageMetier
	ClasseRemplacee: String;
	// Chance (pour cent) de commencer avec une mutation ; vide = aucune (balise StartingMutation de la regle)
	MutationDepart:  String;
	// Ce que la regle implique pour la creation (balise Explanation), montre dans la fenetre des regles optionnelles
	Explication:     String;
  End;

  StructureRegleMetier	= Record
	CodeRegle:	String;
	CodeRace:	String;
	CodeMetier:	String;
	Chance:		String;
	Livre:		String;
  End;

  // Competence ('S') ou talent ('T') qu'une regle donne a une ethnie en REMPLACEMENT des
  // siens (DATA_RULE_SPECIE, 19/10/2026) : une regle qui porte au moins une entree d'un genre
  // pour l'ethnie remplace tout le bloc competences (ou talents) de cette ethnie.
  StructureRegleEthnie	= Record
	CodeRegle:	String;
	CodeRace:	String;
	Genre:		String;
	Code:		String;
	Livre:		String;
  End;

  // Ligne de la table qui tire le BACKGROUND d'une ethnie (DATA_RULE_BACKGROUND, 19/10/2026) :
  // CodeRegle = regle de background obtenue, Chance = poids dans le d100 (somme 100 par ethnie).
  StructureRegleFond	= Record
	CodeRace:	String;
	CodeRegle:	String;
	Chance:		String;
	Livre:		String;
  End;

  // Ligne des tables de competences ('S') et de talents ('T') d'un background (DATA_RULE_SKILL_ROLL / _TALENT_ROLL)
  StructureFondTirage	= Record
	CodeRegle:	String;
	Genre:		String;
	Code:		String;
	Chance:		String;
	Livre:		String;
  End;

  // Table du d10 qui donne le nombre de competences et de talents (DATA_RULE_BACKGROUND_COUNT) ;
  // Second = pas de nombres : il faut un second background (resultat 10).
  StructureFondCompte	= Record
	Poids:		Integer;
	NbCompetence:	Integer;
	NbTalent:	Integer;
	Second:		Boolean;
	Livre:		String;
  End;

  TListFondTirage  = Specialize TList<StructureFondTirage>;
  TListFondCompte  = Specialize TList<StructureFondCompte>;
  TListRegleFond   = Specialize TList<StructureRegleFond>;
  TListRegle       = Specialize TList<StructureRegle>;
  TListRegleMetier = Specialize TList<StructureRegleMetier>;
  TListRegleEthnie = Specialize TList<StructureRegleEthnie>;

var
  ListFondTirage:   TListFondTirage;
  ListFondCompte:   TListFondCompte;
  ListRegleFond:    TListRegleFond;
  ListRegleEthnie:  TListRegleEthnie;
  ListRegle:        TListRegle;
  // Toutes les regles DECLAREES, meme celles que le toggle .INI empeche de charger : pour l'export
  ListRegleSource:  TListRegle;
  NbRegle:          Integer;
  ListRegleMetier:  TListRegleMetier;
  NbRegleMetier:    Integer;

Function ChercheRegle(CodeRegle :String): StructureRegle;
Function RegleCibleEthnie(CodeRegle: String; CodeRace: String): Boolean;
Function RegleMetierApplicable(PRegleMetier: StructureRegleMetier; CodeRegle: String; CodeRace: String; EthnieSeule: Boolean): Boolean;
Function RegleCouvreRace(CodeRegle: String; CodeRace: String): Boolean;
Function RegleConcerneRace(CodeRegle: String; CodeRace: String): Boolean;
// La regle remplace-t-elle les competences ('S') ou les talents ('T') de cette ethnie ?
Function RegleRemplaceGenre(CodeRegle: String; CodeRace: String; Genre: String): Boolean;
// Codes de remplacement ('S' ou 'T') ; liste toujours creee, a liberer par l'appelant.
Function RegleCodesGenre(CodeRegle: String; CodeRace: String; Genre: String): TStringList;

// Competences ('S') ou talents ('T') EFFECTIFS d'une ethnie a la creation : ceux de l'ethnie, sauf si
// la regle choisie (CodeRegle, '' = aucune) les remplace. Liste toujours creee, a liberer par l'appelant.
Function CodesRaceEffectifs(Genre: String; CodeRegle: String; CodeRace: String): TStringList;

// Un livre declare-t-il une table de tirage du background pour cette ethnie (ou sa race) ?
Function RegleFondDisponible(CodeRace: String): Boolean;
// Regle de background (code) pour un d100 (1..100) ; '' si aucune table. Poids cumules dans l'ordre du livre.
Function RegleFondTirage(CodeRace: String; Jet: Integer): String;

// Le background a-t-il une table de competences ('S') ou de talents ('T') ?
Function FondATable(CodeRegle, Genre: String): Boolean;
// Tire un code ('S' ou 'T') sur la table du background ; Jet = equivalent d100 (1..100) ; '' si pas de table.
Function FondTire(CodeRegle, Genre: String; out Jet: Integer): String;
// d10 du nombre de competences / talents ; Second = resultat 10 (pas de nombres). Jet = 1..10. Faux si pas de table.
Function FondTireCompte(out Jet, NbCompetence, NbTalent: Integer; out Second: Boolean): Boolean;

implementation

Function FondATable(CodeRegle, Genre: String): Boolean;
Var
  P: StructureFondTirage;
Begin
  Result := False;
  For P in ListFondTirage do
    if (P.Genre = Genre) and CompareRechercheValeur(P.CodeRegle, CodeRegle) then
      begin
        Result := True;
        Exit;
      end;
End;

Function FondTire(CodeRegle, Genre: String; out Jet: Integer): String;
Var
  P:          StructureFondTirage;
  Total, R, Cum: Integer;
Begin
  Result := '';
  Jet    := 0;
  Total  := 0;
  For P in ListFondTirage do
    if (P.Genre = Genre) and CompareRechercheValeur(P.CodeRegle, CodeRegle) then
      Total := Total + StrToIntDef(P.Chance, 0);
  if Total <= 0 then Exit;
  R   := Random(Total);
  Cum := 0;
  For P in ListFondTirage do
    if (P.Genre = Genre) and CompareRechercheValeur(P.CodeRegle, CodeRegle) then
      begin
        Cum := Cum + StrToIntDef(P.Chance, 0);
        if R < Cum then
          begin
            Result := P.Code;
            Jet    := (R * 100) div Total + 1;
            Exit;
          end;
      end;
End;

Function FondTireCompte(out Jet, NbCompetence, NbTalent: Integer; out Second: Boolean): Boolean;
Var
  P:          StructureFondCompte;
  Total, R, Cum: Integer;
Begin
  Result := False;
  Jet := 0; NbCompetence := 0; NbTalent := 0; Second := False;
  Total := 0;
  For P in ListFondCompte do
    Total := Total + P.Poids;
  if Total <= 0 then Exit;
  R   := Random(Total);
  Cum := 0;
  Jet := R + 1;
  For P in ListFondCompte do
    begin
      Cum := Cum + P.Poids;
      if R < Cum then
        begin
          NbCompetence := P.NbCompetence;
          NbTalent     := P.NbTalent;
          Second       := P.Second;
          Result       := True;
          Exit;
        end;
    end;
End;

// Entrees de la table pour cette ethnie, sinon pour sa race : l'ethnie prime.
Function EntreesFond(CodeRace: String): TStringList;
Var
  PFond:      StructureRegleFond;
  Espece:     String;
  EthnieSeule: Boolean = False;
Begin
  Result := TStringList.Create;
  if CodeRace = '' then Exit;
  For PFond in ListRegleFond do
    if CompareRechercheValeur(PFond.CodeRace, CodeRace) then
      EthnieSeule := True;
  Espece := ChercheRace(CodeRace).Espece;
  For PFond in ListRegleFond do
    if CompareRechercheValeur(PFond.CodeRace, CodeRace)
       or (not EthnieSeule and (Espece <> '') and CompareRechercheValeur(PFond.CodeRace, Espece)) then
      Result.Add(PFond.CodeRegle + '=' + PFond.Chance);
End;

Function RegleFondDisponible(CodeRace: String): Boolean;
Var
  L: TStringList;
Begin
  L := EntreesFond(CodeRace);
  try
    Result := L.Count > 0;
  finally
    L.Free;
  end;
End;

Function RegleFondTirage(CodeRace: String; Jet: Integer): String;
Var
  L:      TStringList;
  I, Cum: Integer;
Begin
  Result := '';
  L := EntreesFond(CodeRace);
  try
    Cum := 0;
    For I := 0 to L.Count - 1 do
      begin
        Cum := Cum + StrToIntDef(L.ValueFromIndex[I], 0);
        if Jet <= Cum then
          begin
            Result := L.Names[I];
            Exit;
          end;
      end;
  finally
    L.Free;
  end;
End;

Function CodesRaceEffectifs(Genre: String; CodeRegle: String; CodeRace: String): TStringList;
Var
  PTalent:      StructureRaceTalent;
  PCompetence:  StructureRaceCompetence;
Begin
  if RegleRemplaceGenre(CodeRegle, CodeRace, Genre) then
    begin
      Result := RegleCodesGenre(CodeRegle, CodeRace, Genre);
      Exit;
    end;
  Result := TStringList.Create;
  if Genre = 'T' then
    begin
      For PTalent in ListRaceTalent do
        if CompareRechercheValeur(PTalent.CodeRace, CodeRace) then
          Result.Add(PTalent.CodeTalent);
    end
  else
    For PCompetence in ListRaceCompetence do
      if CompareRechercheValeur(PCompetence.CodeRace, CodeRace) then
        Result.Add(PCompetence.CodeCompetence);
End;

// Meme ciblage que RegleMetierApplicable : l'ethnie, ou la race dont elle fait partie ;
// l'ethnie prime sur la race (EthnieSeule).
Function EntreeEthnieApplicable(PEntree: StructureRegleEthnie; CodeRegle, CodeRace, Genre: String; EthnieSeule: Boolean): Boolean;
Var
  Espece: String;
Begin
  Result := False;
  if (PEntree.Genre = Genre) and CompareRechercheValeur(PEntree.CodeRegle, CodeRegle) then
    begin
      if CompareRechercheValeur(PEntree.CodeRace, CodeRace) then
        Result := True
      else if not EthnieSeule then
        begin
          Espece := ChercheRace(CodeRace).Espece;
          if (Espece <> '') and CompareRechercheValeur(PEntree.CodeRace, Espece) then
            Result := True;
        end;
    end;
End;

Function RegleCodesGenre(CodeRegle: String; CodeRace: String; Genre: String): TStringList;
Var
  PEntree:      StructureRegleEthnie;
  EthnieSeule:  Boolean = False;
Begin
  Result := TStringList.Create;
  if (CodeRegle = '') or (CodeRace = '') then Exit;
  For PEntree in ListRegleEthnie do
    if (PEntree.Genre = Genre) and CompareRechercheValeur(PEntree.CodeRegle, CodeRegle)
       and CompareRechercheValeur(PEntree.CodeRace, CodeRace) then
      EthnieSeule := True;
  For PEntree in ListRegleEthnie do
    if EntreeEthnieApplicable(PEntree, CodeRegle, CodeRace, Genre, EthnieSeule) then
      Result.Add(PEntree.Code);
End;

Function RegleRemplaceGenre(CodeRegle: String; CodeRace: String; Genre: String): Boolean;
Var
  Codes: TStringList;
Begin
  Codes := RegleCodesGenre(CodeRegle, CodeRace, Genre);
  try
    Result := Codes.Count > 0;
  finally
    Codes.Free;
  end;
End;

Function ChercheRegle(CodeRegle :String): StructureRegle;
Var
  PRegle:   StructureRegle;
  PVide:    StructureRegle;
  Trouve:   Boolean = false;
Begin
  for PRegle in ListRegle do
    if CompareRechercheValeur(PRegle.CodeRegle, CodeRegle) then
      begin
        Result := PRegle;
        Trouve := true;
        break;
      end;
  if not Trouve then
    begin
      Finalize(PVide);
      FillChar(PVide, SizeOf(PVide), 0);
      Result := PVide;
    end;
end;

// Une entrée de table de tirage s'applique à une ethnie si elle porte la bonne règle ET
// qu'elle cible soit cette ethnie précisément (RULES-RACE_HUM), soit la RACE dont elle
// fait partie (RULES-SPECIE_HUMAN) - la colonne "Old World Human" de la table lustrienne
// couvre les cinq ethnies Humaines d'un coup (Lustria p.193, note 1).
//
// L'ethnie PRIME sur la race. Une même règle peut porter les deux niveaux : la table
// lustrienne a une colonne "Old World Human" (visant la RACE Humaine) ET une colonne
// "Norse" (visant les trois ETHNIES norses). Sans cette précédence, un Norse recevait
// la fusion des deux colonnes - bug trouvé au test par Nono le 21/08/2026.
// EthnieSeule vient de RegleCibleEthnie : true si la règle a au moins une entrée visant
// précisément cette ethnie, auquel cas les entrées de niveau race sont ignorées.
Function RegleMetierApplicable(PRegleMetier: StructureRegleMetier; CodeRegle: String; CodeRace: String; EthnieSeule: Boolean): Boolean;
Var
  Espece: String;
  Res:    Boolean = false;
Begin
  if CompareRechercheValeur(PRegleMetier.CodeRegle, CodeRegle) then
    begin
      if CompareRechercheValeur(PRegleMetier.CodeRace, CodeRace) then
        Res := true
      else if not EthnieSeule then
        begin
          Espece := ChercheRace(CodeRace).Espece;
          if (Espece <> '') and CompareRechercheValeur(PRegleMetier.CodeRace, Espece) then
            Res := true;
        end;
    end;
  Result := Res;
End;

// La règle a-t-elle au moins une entrée visant précisément cette ethnie ?
Function RegleCibleEthnie(CodeRegle: String; CodeRace: String): Boolean;
Var
  PRegleMetier: StructureRegleMetier;
  Res:          Boolean = false;
Begin
  if (CodeRegle <> '') and (CodeRace <> '') then
    For PRegleMetier in ListRegleMetier do
      if CompareRechercheValeur(PRegleMetier.CodeRegle, CodeRegle)
         and CompareRechercheValeur(PRegleMetier.CodeRace, CodeRace) then
        begin
          Res := true;
          break;
        end;
  Result := Res;
End;

// Une règle ne couvre pas forcément toutes les ethnies : la table lustrienne n'a pas de
// colonne Gnome, Ogre, Elfe Noir ni Peau-Verte (ni Norse, absent de la base). Dans ce cas
// l'appelant doit retomber sur la table de tirage par défaut (décision Nono du 20/08/2026).
Function RegleCouvreRace(CodeRegle: String; CodeRace: String): Boolean;
Var
  PRegleMetier: StructureRegleMetier;
  Res:          Boolean = false;
Begin
  if (CodeRegle <> '') and (CodeRace <> '') then
    For PRegleMetier in ListRegleMetier do
      if RegleMetierApplicable(PRegleMetier, CodeRegle, CodeRace, false) then
        begin
          Res := true;
          break;
        end;
  Result := Res;
End;

// La regle a-t-elle un effet sur cette ethnie (table de carrieres, competences ou talents) ?
// Sert a la liste du combo des regles ; NE PAS l'utiliser pour choisir la table de tirage :
// une regle qui ne remplace que des competences n'a pas de table de carrieres.
Function RegleConcerneRace(CodeRegle: String; CodeRace: String): Boolean;
Begin
  Result := RegleCouvreRace(CodeRegle, CodeRace)
         or RegleRemplaceGenre(CodeRegle, CodeRace, 'S')
         or RegleRemplaceGenre(CodeRegle, CodeRace, 'T');
End;

end.

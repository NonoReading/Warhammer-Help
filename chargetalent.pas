unit ChargeTalent;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes, UnitCalcul, Generics.Collections;

Type
  StructureTalent             = Record
	CodeTalent:	      string;
	Libelle:	      string;
	Tests:	              string;
	Description:          string;
	MaxiTalent:	      string;
	SousTalent:	      boolean;
        // Trait de creature (Rulebook p.338-341) : un talent qu'on ne peut pas CHOISIR.
        // Il arrive uniquement par la race (SUBCHAPTER_TALENT), jamais par un niveau de
        // metier. Le livre lui-meme fait ce pont : "Night Vision - The creature has the
        // Night Vision Talent". Voir CONTEXT.md 2.15.
        Trait:                Boolean;
        // Acces aux sorts (voir ConstXmlMagie dans chargeconstantes.pas). Renseignes sur les
        // entrees GENERIQUES (T0012_*, T0080_*, T0088_*, T0089) ; ChercheTalent les reporte
        // sur les specialisations, comme il le fait deja pour Resume.
        Magie:                Integer;
        ModeSort:             String;
        // Valeurs de <TypSpell> que ce talent ouvre, separees par des virgules ("Arcane Magic,
        // Domain Magic,Ritual"), valeurs XML anglaises. Declare sur l'entree GENERIQUE comme
        // Magie ; ChercheTalent le reporte sur les specialisations. Vide = pas declare.
        // CONTEXT.md 2.1, chantier coherence type de sort / talent d'acces.
        TypesSort:            String;
        // Tarif des sorts ouverts par ce talent - voir ConstXmlXpMultiplicateur dans
        // chargeconstantes.pas pour la formule et le sens de chaque champ. Herites de
        // l'entree generique par ChercheTalent, comme Magie et ModeSort juste au-dessus.
        XpMultiplicateur:     Integer;
        XpPlancher:           Integer;
        XpDiviseur:           String;
        XpOfferts:            String;
        XpGroupe:             String;
        // "CODE_METIER/NIVEAU" (ConstXmlOctroiCarriere / ConstXmlRetraitCarriere), vide si absent.
        OctroiCarriere:       String;
        RetraitCarriere:      String;
        Livre:                String;
        TalentPdf:            String;
        Resume:               String;
        ModifyCarac:          String;
        // Code complet du talent generique dont celui-ci est une specialisation, lu depuis
        // <Generique> quand present (CONTEXT.md 2.67). Vide si non renseigne (talent non
        // specialise, ou specialisation sans generique '_*' identifiee).
        CodeGenerique:        String;
end;

  TListTalent = Specialize TList<StructureTalent>;

Var
  ListTalent:     TListTalent;
  // specialisations de talent propres au personnage en cours : jamais dans la liste des livres (CONTEXT.md 2.116)
  ListTalentPerso: TListTalent;
  NbTalent:       Integer;
  NbTalentUnique: Integer;
  TestTal:        string;
  DescTal:        string;
  AttTal:         string;
  MaxTal:         string;
  CompPdfTal:     String;
  CourtTal:       String;
  CompAjoute:     String;

function ChercheTalent(CodeTalent :String): StructureTalent;
function ListeTalent(CodeTalent :String): TStringList;
function LibelleTalent(CodeTalent :String): String;
function CodeTalentGenerique(PTalent: StructureTalent): String;
function CodeFamilleTalent(const Code: String): String;
// Version Momentum (WFRP5) ou normale (WFRP4) d'un code de talent : bascule MOMENTUM-xxx <-> RULES-xxx
// si le talent existe dans l'autre livre, sinon renvoie le code tel quel.
function CodeTalentVersion(const Code: String; Momentum: Boolean): String;
// Vrai si le livre Momentum est charge (au moins un de ses talents est dans ListTalent).
function LivreMomentumCharge: Boolean;
function RadicalTalent(const Code: String): String;
procedure OublieFamillesTalent;

implementation

// Famille (code generique '..._*') dont ce code est une specialisation, '' si ce n'en est pas une.
// Le nom d'un talent contient lui-meme des '_' (RULES-T_BLESS_SIGMAR) : on ne peut plus couper au
// premier. On essaie chaque '_' de gauche a droite et on retient le premier prefixe dont le code
// generique est DECLARE (RULES-T, puis RULES-T_BLESS -> RULES-T_BLESS_*). Chantier codes a nom,
// 24/10/2026.
var
  // Codes generiques ('..._*') declares, tries : CodeFamilleTalent est appelee par ChercheTalent, donc tres
  // souvent. Reconstruit quand le nombre de talents change, ou apres OublieFamillesTalent (rechargement).
  Generiques:       TStringList;
  GeneriquesCompte: Integer = -1;

procedure OublieFamillesTalent;
Begin
  GeneriquesCompte := -1;
End;

function CodeFamilleTalent(const Code: String): String;
var
  P:       Integer;
  Cand:    String;
  PTalent: StructureTalent;
Begin
  Result := '';
  if (Code = '') or (Pos(ValeurGenerique, Code) > 0) or (Pos(SeparateurMulti, Code) > 0) then
    Exit;
  // Format actuel (V4, V5) : la specialisation est reconnue a son '__', la famille est ce qui precede.
  P := Pos(SeparateurSpecialisationTalent, Code);
  if P > 0 then
    Exit(Copy(Code, 1, P - 1) + ValeurGeneriqueTalent);
  // Ancien format (V2) : '_' simple, la famille est cherchee parmi les generiques declares.
  if GeneriquesCompte <> ListTalent.Count then
    begin
      Generiques.Clear;
      for PTalent in ListTalent do
        if (Pos(ValeurGenerique, PTalent.CodeTalent) > 0) and (Pos(SeparateurMulti, PTalent.CodeTalent) = 0) then
          Generiques.Add(PTalent.CodeTalent);
      GeneriquesCompte := ListTalent.Count;
    end;
  for P := 1 to Length(Code) do
    if Code[P] = ValeurSousCompetence then
      begin
        Cand := Copy(Code, 1, P - 1) + ValeurGenerique;
        if Generiques.IndexOf(Cand) >= 0 then
          Exit(Cand);
      end;
End;

function LivreMomentumCharge: Boolean;
var
  PTalent: StructureTalent;
Begin
  for PTalent in ListTalent do
    if Copy(PTalent.CodeTalent, 1, Length(ConstCodeLivreMomentum) + 1) = ConstCodeLivreMomentum + '-' then
      Exit(True);
  Result := False;
End;

function CodeTalentVersion(const Code: String; Momentum: Boolean): String;
var
  Cle, Cible, Source: String;
  PTalent:            StructureTalent;
Begin
  Result := Code;
  if (Code = '') or (Pos(SeparateurMulti, Code) > 0) or (Pos(ValeurGenerique, Code) > 0) then
    Exit;
  Cle := CodeSansLivre(Code);
  if Cle = Code then
    Exit;
  if Momentum then
    begin
      Source := 'RULES-';
      Cible  := ConstCodeLivreMomentum + '-' + Cle;
    end
  else
    begin
      Source := ConstCodeLivreMomentum + '-';
      Cible  := 'RULES-' + Cle;
    end;
  if Copy(Code, 1, Length(Source)) <> Source then
    Exit;
  // Le code d'arrivee doit exister, sinon (livre non charge, talent sans equivalent) on ne touche a rien.
  for PTalent in ListTalent do
    if PTalent.CodeTalent = Cible then
      Exit(Cible);
End;

// Radical : le code de la famille sans son '_*' (RULES-T_BLESS_SIGMAR et RULES-T_BLESS_* donnent
// RULES-T_BLESS) ; un talent sans famille est son propre radical.
function RadicalTalent(const Code: String): String;
var
  Fam: String;
Begin
  if Pos(ValeurGenerique, Code) > 0 then
    Fam := Code
  else
    Fam := CodeFamilleTalent(Code);
  if Fam = '' then
    Result := Code
  else if Copy(Fam, Length(Fam) - 2, 3) = ValeurGeneriqueTalent then
    Result := Copy(Fam, 1, Length(Fam) - 3)
  else if Copy(Fam, Length(Fam) - 1, 2) = ValeurGenerique then
    Result := Copy(Fam, 1, Length(Fam) - 2)
  else
    Result := Fam;
End;

function ChercheTalent(CodeTalent :String): StructureTalent;
var
  PTalent:        StructureTalent;
  code:           String;
Begin
  // Sans cette ligne, Result garde le contenu du PRECEDENT appel quand rien n'est trouve
  // (une fonction Pascal renvoyant un record ne l'initialise pas). Symptomes vus le
  // 22/08/2026 : un libelle de talent recopie d'une ligne a l'autre, une competence
  // affichee deux fois. CONTEXT.md 2.17.
  Result := Default(StructureTalent);
  For PTalent in ListTalent do
    if CompareRechercheValeur(PTalent.CodeTalent, CodeTalent) then
      begin
       Result := PTalent;
       break;
      end;
  if Result.CodeTalent = '' then
    for PTalent in ListTalentPerso do
      if CompareRechercheValeur(PTalent.CodeTalent, CodeTalent) then
        begin
          Result := PTalent;
          break;
        end;
  // Codes a nom (24/10/2026) : l'identite d'un talent est ce qui suit le premier '-' (T_WILL_OF_IRON), le
  // prefixe n'est que le livre. Repli seulement si la recherche exacte n'a rien donne : un talent cree dans
  // un livre non charge est retrouve par sa cle dans un autre livre.
  if (Result.CodeTalent = '') and (CodeTalent <> '') then
    begin
      code := CodeSansLivre(CodeTalent);
      for PTalent in ListTalent do
        if CodeSansLivre(PTalent.CodeTalent) = code then
          begin
            Result := PTalent;
            break;
          end;
      if Result.CodeTalent = '' then
        for PTalent in ListTalentPerso do
          if CodeSansLivre(PTalent.CodeTalent) = code then
            begin
              Result := PTalent;
              break;
            end;
    end;
  // Corrige le 15/09/2026 (A FAIRE.txt) : testait PTalent.Resume, la variable de BOUCLE, qui
  // garde le DERNIER element de ListTalent si rien ne matche (pas de break) - le repli vers
  // le generique ne se declenchait alors que par hasard (dernier talent de la liste a Resume
  // vide). Result reste bien vide (Default ligne 78) dans ce cas, donc Result.Resume est le
  // test correct, y compris pour une specialisation NON trouvee.
  code := '';
  if (Result.Resume = '') and (Pos(ValeurGenerique, CodeTalent) = 0) then
    begin
      // Lien explicite (CONTEXT.md 2.67) prioritaire sur la deduction par radical - seul
      // repli quand <Generique> n'est pas renseigne (donnee pas encore migree, ou
      // specialisation sans generique '_*' identifiee).
      if Result.CodeGenerique <> '' then
        code := Result.CodeGenerique
      else
        code := CodeFamilleTalent(CodeTalent);
    end;
  if code <> '' then
        begin
          PTalent       := ChercheTalent(Code);
          Result.Resume := PTalent.Resume;
          // L'acces aux sorts est declare sur l'entree generique (T0012_*, T0080_*, T0088_*) :
          // une specialisation comme T0012_SIGMAR n'a qu'une Description, elle herite donc du
          // reste. Meme principe que Resume juste au-dessus. CONTEXT.md 2.18.
          if Result.Magie = 0 then
            Result.Magie    := PTalent.Magie;
          if Result.ModeSort = '' then
            Result.ModeSort := PTalent.ModeSort;
          if Result.TypesSort = '' then
            Result.TypesSort := PTalent.TypesSort;
          // Le tarif suit le meme chemin : il est declare une fois sur la generique, et
          // toutes ses specialisations en heritent. Le multiplicateur sert de temoin -
          // une specialisation ne le renseigne jamais, donc 0 veut dire "pas declare ici"
          // et non "gratuit". Les cinq champs se reprennent ENSEMBLE : les melanger entre
          // deux entrees donnerait un tarif qui n'existe nulle part.
          if Result.XpMultiplicateur = 0 then
            begin
              Result.XpMultiplicateur := PTalent.XpMultiplicateur;
              Result.XpPlancher       := PTalent.XpPlancher;
              Result.XpDiviseur       := PTalent.XpDiviseur;
              Result.XpOfferts        := PTalent.XpOfferts;
              Result.XpGroupe         := PTalent.XpGroupe;
            end;
        end;
end;

function ListeTalent(CodeTalent :String): TStringList;
  var
    Liste:      TStringList;
    Branches:   TStringList;
    SousListe:  TStringList;
    Ind:        Integer;
    PTalent:    StructureTalent;
    Deb:        String;
  begin
    Liste := TStringList.Create;
    if Pos(SeparateurMulti, CodeTalent) > 0 then
      // choix entre plusieurs options : on aplatit chaque branche
      begin
        Branches                 := TStringList.Create;
        Branches.StrictDelimiter := True;
        Branches.Delimiter       := SeparateurMulti;
        Branches.DelimitedText   := CodeTalent;
        for Ind := 0 to Branches.Count - 1 do
          if Pos(ValeurGenerique, Branches[Ind]) > 0 then
            begin
              SousListe := ListeTalent(Branches[Ind]);
              Liste.AddStrings(SousListe);
              SousListe.Free;
            end
          else
            Liste.Add(Branches[Ind]);
        Branches.Free;
      end
    else if Pos(ValeurGenerique, CodeTalent) > 0 then
      begin
        // talent avec des spécialités
        // Les branches sont cherchees PREFIXE DE LIVRE INCLUS, et c'est voulu (arbitre
        // par Nono le 05/09/2026) : une specialite ne peut venir que du livre qui porte
        // le code generique. Ne pas "corriger" en decoupant le prefixe.
        Deb := Copy(CodeTalent, 1, Pos(ValeurGenerique, CodeTalent));
        For PTalent in ListTalent do
          if (pos(Deb, PTalent.CodeTalent) = 1) and (pos(SeparateurMulti, PTalent.codeTalent) < 1) and (PTalent.CodeTalent <> CodeTalent) then
            Liste.Add(PTalent.CodeTalent);
      end;
    Result := Liste;
  end;

function LibelleTalent(CodeTalent :String): String;
  var
    PTalent:        StructureTalent;
    strings:        TStringList;
    Libelles:       String = '';
    Ind:            Integer;
  begin
    strings            := TStringList.Create;
    ExtractStrings([SeparateurMulti], [], PChar(CodeTalent), Strings);
    For Ind := 0 to Strings.Count - 1 do
      begin
        PTalent    := ChercheTalent(Strings[Ind]);
        if Libelles <> '' then
          Libelles := Libelles + SeparateurMulti;
        Libelles   := Libelles + PTalent.Libelle;
      end;
    strings.Free;

    Result := Libelles;
  end;

// Entree GENERIQUE dont ce talent depend : RULES-T0012_SIGMAR -> RULES-T0012_*. Un code qui
// n'est pas une specialisation se renvoie lui-meme (RULES-T0089, HELFG-T0190).
//
// La decoupe est ECRITE EXACTEMENT COMME DANS ChercheTalent ci-dessus, et ce n'est pas un
// hasard : les deux doivent designer la meme entree, sinon un talent heriterait d'un tarif
// et serait compte dans un autre groupe.
//
// Sert a identifier le GROUPE DE COMPTAGE des sorts : deux sorts dont les talents remontent
// a la meme generique se comptent ensemble. C'est ce qui fait que l'arcanique et le domaine
// partagent leur compteur sans qu'aucune donnee ne le declare - ils citent le meme talent.
function CodeTalentGenerique(PTalent: StructureTalent): String;
Begin
  Result := PTalent.CodeTalent;
  if Pos(ValeurGenerique, PTalent.CodeTalent) > 0 then
    Exit;
  // Lien explicite (CONTEXT.md 2.67) prioritaire sur la deduction par radical - seul repli
  // quand <Generique> n'est pas renseigne.
  if PTalent.CodeGenerique <> '' then
    Result := PTalent.CodeGenerique
  else if CodeFamilleTalent(PTalent.CodeTalent) <> '' then
    Result := CodeFamilleTalent(PTalent.CodeTalent);
end;

initialization
  ListTalentPerso := TListTalent.Create;
  Generiques := TStringList.Create;
  Generiques.Sorted := True;
  Generiques.Duplicates := dupIgnore;

end.


unit XmlExportImport;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}

interface

uses
  Classes, SysUtils, StrUtils, XMLWrite, ChargeConstantes, ChargeCompetence, ChargeTalent, ChargeRace,
  ChargeEspece, ChargeNation, ChargeRegle,
  ChargeRaceAttribut, ChargeRacePhysique, ChargeSigneAstral, ChargeRaceCompetence, ChargeRaceTalent, ChargeRaceMetier,
  ChargeMetier, ChargeMetierAttribut, ChargeMetierCompetence, ChargeMetierTalent,
  ChargeMetierEquipement, chargeMetierNiveau, ChargeArme, ChargeArmure, ChargeTrapping, ChargeOptionRegle,
  ChargeTalentCreation, ChargeRaceCreation, ChargeArmeBonus, ChargeArmureBonus,
  ChargeFabrication, ChargeSort, ChargeMetierRaceChoixMetier, ChargeAttribut,
  ChargeAttributAugmentation, ChargeCompetenceAugmentation, ChargeTexte,
  ChargeMetierSousMetier, ChargeTraduction, ChargeArmureSimplifie, ChargeLivre,
  ChargeRaceCorruptionCreation, ChargeCorruptionTable,
  ChargeTalentEffet, ChargeTalentCompetenceModif, ChargeRaceOpinion,
  ChargeCorruptionCompetenceModif,
  ChargeCorruptionTalent, ChargeCorruptionEquipement,
  ChargeArmureBonusTalent, ChargeArmeBonusTalent,
  ChargeModificateur, ChargeTalentModificateur, ChargeCareerBonusModificateur,
  ChargeArmeModificateur, ChargeArmureBonusModificateur, ChargeCorruptionModificateur,
  ChargeDisease, ChargeAffliction, ChargeClassEquipement,
  ChargeAfflictionModificateur, ChargeDiseaseModificateur, ChargeAfflictionCompetenceModif,
  XMLRead, DOM, Unitcalcul,  Dialogs, contnrs;

Procedure XmlExportBook(Livre: String; Langue: String);
Procedure XmlImport(FileName: String; OnlyPrimary: Boolean; CheminComplet: String = '');
Function XmlElement(Node: TDOMNode): TDOMNode;
// Page du livre source qui donne la fiche (balise <Page>, 12/10/2026). Cle = bloc DATA_* + id.
Function PageFiche(Const Bloc, Id: String): String;
Procedure PageFicheDefinit(Const Bloc, Id, Page: String);
// Description a afficher : la description de la fiche, ou "Page N" (page du livre anglais source)
// quand elle est vide ou quand DEFAULTLICENSELESS=1 la masque. Affichage seulement : rien n'est
// ecrit dans les structures ni dans l'export. Livre = libelle du livre de la fiche, Code = code.
Function TexteOuPage(Const Description, Bloc, Livre, Code: String): String;
Function DescriptionTalentOuPage(Const CodeTalent, CodeRace: String): String;
// Lecteur commun des modificateurs numeriques (CONTEXT.md 2.105, e2a) : lit un noeud XML, au
// format historique (<ModifyCarac name="Cible">N</ModifyCarac>, filtre par if= ou skill=) ou
// generique (<Modificateur Type= Cible= Facteur= Filtre=/>), selon la table TypesEffet.
// Rend Faux quand le noeud n'est pas un modificateur numerique (autre balise, ou contenu non
// entier comme le <ModifySkill>"Bonus"</ModifySkill> des talents) : l'appelant le traite alors
// comme avant.
Function LitModificateurNoeud(Node: TDOMNode; Const CodeSource: String; out Modif: StructureModificateur): Boolean;
Function XmlDebut(TypeDonnee: string): String;
Function XmlFin(TypeDonnee: string): String;
Function XmlLigne(TypeDonnee: string; Valeur: String): String;
Function XmlCommentaire(Valeur: String): String;
Function XmlLigneDonnee(TypeDonnee: String; Name: String; Valeur: String; Attribut: String = ''): String;
Function XmlLigneLangue(TypeDonnee: String; Name: String; Valeur: String): String;
Function xmlDataBase(): String;
Function XmlDebutCode(TypeDonnee: string; Valeur: String): String;
Function XmlFinCode(TypeDonnee: String): String;
Function XmlReplace(Source: String): String;
Function XmlDebutLangue(TypeDonnee: String; Name: String): String;
Function XmlLivre(FileName: String): string;
Function XmlLivreBalise(CheminFichier: String; Balise: String): String;
// Retire des listes globales tout ce qui porte ce libelle de livre (champ Livre = <BOOK> de l'en-tete),
// hors ListLivre et ListLivreTraduit, et ajuste les compteurs Nb*. A faire suivre d'un XmlImport
// (OnlyPrimary vrai puis faux) de chaque fichier du livre. A FAIRE.txt, ENREGISTREMENT PAR L EXPORT.
// Journal des anomalies XML (XML_ERREURS.txt a la racine) : une ligne horodatee par appel.
Procedure XmlSignale(Const Message: String);
Procedure XmlRetireLivre(Libelle: String);
// Injecte les objets propres d'une fiche (contenu de <CUSTOM_ITEMS>), apres avoir retire les precedents.
Procedure InjecteObjetsPropres(const Xml: String);
// Bouton Update de WinLivre : remplace dans les listes globales le livre CodePrincipal (nom de fichier
// sans extension, dans DATABASE) par l'ebauche CheminEbauche. Retire le livre, importe l'ebauche puis
// les autres fichiers du livre (traductions). Si l'import echoue, le livre est retire de nouveau et
// recharge depuis CheminRestauration (dernier etat connu bon ; vide = fichier de DATABASE).
// Renvoie '' si tout va bien, sinon le message d'erreur (l'etat precedent est alors restaure).
Function XmlMajLivre(CodePrincipal, CheminEbauche, CheminRestauration: String): String;
Function XmlCodeLivre(Livre: String): String;
Function XmlCreeCodeLivre(Livre: String; Code: String): String;

implementation

// Renvoie Node s'il est un ELEMENT XML, sinon le premier frere suivant qui en est un.
//
// Un commentaire XML et un noeud texte sont des enfants comme les autres : les boucles de
// lecture ci-dessous parcourent TOUS les enfants d'un bloc, donc sans ce filtre elles les
// traitent comme des donnees. Deux consequences, rencontrees toutes les deux pour de vrai :
//   - la boucle lit Node.Attributes, qui vaut nil sur un commentaire -> ACCESS VIOLATION au
//     chargement (DATA_LABEL, 21/08/2026, plantage au lancement) ;
//   - la boucle ne lit pas d'attribut mais reutilise l'enregistrement du tour precedent, qui
//     n'est pas remis a zero -> DOUBLON SILENCIEUX (DATA_CAREER_ROLL, 20/08/2026, un metier
//     affiche deux fois).
//
// Poser la garde ici plutot que dans chacune des 31 boucles evite d'en oublier une, et rend
// inoffensif le fait de commenter un fichier de donnees - ce qui etait devenu un piege a
// chaque saisie. Voir CONTEXT.md 2.16.
Function XmlElement(Node: TDOMNode): TDOMNode;
begin
  While Assigned(Node) and (Node.NodeType <> ELEMENT_NODE) do
    Node := Node.NextSibling;
  Result := Node;
end;

// Journal des anomalies de lecture et d ecriture XML : fichier XML_ERREURS.txt a la racine,
// une ligne par anomalie. Dans une application graphique un WriteLn ne va nulle part : sans
// ce journal, un export ou un import en erreur ne laissait aucune trace.
Procedure XmlSignale(Const Message: String);
var
  F:      TextFile;
  Chemin: String;
begin
  Chemin := GetCurrentDir + DirectorySeparator + 'XML_ERREURS.txt';
  try
    AssignFile(F, Chemin);
    if FileExists(Chemin) then
      Append(F)
    else
      Rewrite(F);
    try
      WriteLn(F, FormatDateTime('dd/mm/yyyy hh:nn:ss', Now) + ' ' + Message);
    finally
      CloseFile(F);
    end;
  except
    // le journal ne doit jamais faire echouer la lecture ou l ecriture
  end;
end;

// Valeur d un attribut (Brut : telle quelle ; sans suffixe : sans guillemets), ou '' si le noeud ou l attribut manque (signale au
// journal au lieu de provoquer une violation d acces sur une fiche mal formee).
Function XmlAttributBrut(Node: TDOMNode; Const Nom: String): String;
var
  Attr: TDOMNode;
begin
  Result := '';
  if (Node = nil) or (Node.Attributes = nil) then
    Exit;
  Attr := Node.Attributes.GetNamedItem(Nom);
  if Attr = nil then
    begin
      XmlSignale('Attribut "' + Nom + '" absent sur <' + Node.NodeName + '> (livre ' + LivreImportEnCours + ')');
      Exit;
    end;
  Result := UTF8Encode(Attr.NodeValue);
end;

Function XmlAttribut(Node: TDOMNode; Const Nom: String): String;
begin
  Result := RemoveQuotes(XmlAttributBrut(Node, Nom));
end;

// Texte d un sous-element, sans guillemets, ou '' si le sous-element manque (signale).
Function XmlTexte(Node: TDOMNode; Const Nom: String): String;
var
  Fils: TDOMNode;
begin
  Result := '';
  if Node = nil then
    Exit;
  Fils := Node.FindNode(Nom);
  if Fils = nil then
    begin
      XmlSignale('Element <' + Nom + '> absent sous <' + Node.NodeName + '> (livre ' + LivreImportEnCours + ')');
      Exit;
    end;
  Result := RemoveQuotes(UTF8Encode(Fils.TextContent));
end;

// Les pages ne vivent pas dans les enregistrements de chaque type : une table unique,
// lue sur toute fiche portant un <Page>, rejouee a l'export (XmlInserePages). Cle =
// bloc DATA_* + id, car un meme id sert dans DATA_SPELL et DATA_SPELL_TALENT.
var
  PagesFiches: TFPStringHashTable = nil;

Function PageFiche(Const Bloc, Id: String): String;
begin
  Result := '';
  if Assigned(PagesFiches) then
    Result := PagesFiches[Bloc + '|' + Id];
end;

Procedure PageFicheDefinit(Const Bloc, Id, Page: String);
begin
  if PagesFiches = nil then
    PagesFiches := TFPStringHashTable.Create;
  PagesFiches[Bloc + '|' + Id] := Page;
end;

Procedure LitPagesFiches(BookNode: TDOMNode);
  var
    Bloc, Fiche, NodePage: TDOMNode;
    Id: String;
  begin
    Bloc := BookNode.FirstChild;
    While Assigned(Bloc) do
      begin
        if Bloc.NodeType = ELEMENT_NODE then
          begin
            Fiche := Bloc.FirstChild;
            While Assigned(Fiche) do
              begin
                if (Fiche.NodeType = ELEMENT_NODE) and (Fiche is TDOMElement) then
                  begin
                    Id := UTF8Encode(TDOMElement(Fiche).GetAttribute('id'));
                    if Id = '' then
                      Id := UTF8Encode(TDOMElement(Fiche).GetAttribute('name'));
                    NodePage := Fiche.FindNode('Page');
                    if (Id <> '') and Assigned(NodePage) and (Trim(NodePage.TextContent) <> '') then
                      PageFicheDefinit(UTF8Encode(Bloc.NodeName), Id,
                                       Trim(RemoveQuotes(UTF8Encode(NodePage.TextContent))));
                  end;
                Fiche := Fiche.NextSibling;
              end;
          end;
        Bloc := Bloc.NextSibling;
      end;
  end;

// Reinsere <Page> en fin de fiche dans le contenu exporte (juste avant la balise fermante).
Procedure XmlInserePages(Contenu: TStringList);
  var
    I, P: Integer;
    L, Bloc, Tag, Id, Page, TagOuvert, PageOuverte: String;
  begin
    if (PagesFiches = nil) then Exit;
    Bloc := ''; TagOuvert := ''; PageOuverte := '';
    I := 0;
    While I < Contenu.Count do
      begin
        L := Trim(Contenu[I]);
        if (TagOuvert <> '') and (L = '</' + TagOuvert + '>') then
          begin
            Contenu.Insert(I, '<Page>' + XmlReplace(PageOuverte) + '</Page>');
            Inc(I);
            TagOuvert := ''; PageOuverte := '';
          end
        else if (Copy(L, 1, 6) = '<DATA_') and (Pos(' ', L) = 0) and (L[Length(L)] = '>') then
          Bloc := Copy(L, 2, Length(L) - 2)
        else if (Copy(L, 1, 1) = '<') and (Copy(L, 1, 2) <> '</') and (TagOuvert = '') then
          begin
            P := Pos(' id="', L);
            if P = 0 then
              P := Pos(' name="', L);   // maladies et afflictions : cle = name
            if (P > 0) and (L[Length(L)] = '>') and (L[Length(L) - 1] <> '/') then
              begin
                Tag := Copy(L, 2, P - 2);
                Id  := Copy(L, Pos('="', L) + 2, Length(L));
                Id  := Copy(Id, 1, Pos('"', Id) - 1);
                Page := PageFiche(Bloc, Id);
                if Page <> '' then
                  begin
                    TagOuvert := Tag; PageOuverte := Page;
                  end;
              end;
          end;
        Inc(I);
      end;
  end;

Function LitModificateurNoeud(Node: TDOMNode; Const CodeSource: String; out Modif: StructureModificateur): Boolean;
  Function Attribut(Const Nom: String): String;
  begin
    Result := '';
    if Assigned(Node.Attributes) and Assigned(Node.Attributes.GetNamedItem(Nom)) then
      Result := XmlAttribut(Node, Nom);
  end;
var
  Texte: String;
  Valeur: Integer;
begin
  Result := False;
  if (Node = nil) or (IndiceTypeEffet(Node.NodeName) < 0) then Exit;
  Modif.Forme      := ConstFormeEffetAdditif;
  Modif.CodeSource := CodeSource;
  Modif.Niveau     := 0;
  Modif.Aleatoire  := False;
  Modif.TypeSource := '';
  if Node.NodeName = ConstXmlModificateur then
    begin
      Modif.TypeModif := Attribut(ConstXmlType);
      Modif.Cible     := Attribut(ConstXmlEffetCible);
      Modif.Filtre    := Attribut(ConstXmlModificateurFiltre);
      Modif.Facteur   := StrToIntDef(Attribut(ConstXmlEffetFacteur), 0);
    end
  else
    begin
      Texte := Trim(RemoveQuotes(UTF8Encode(Node.TextContent)));
      if not TryStrToInt(Texte, Valeur) then Exit;
      Modif.TypeModif := Node.NodeName;
      Modif.Aleatoire := (Node.NodeName = ConstXmlModifieAttributAleatoire);
      if Modif.Aleatoire then Modif.TypeModif := ConstXmlModifieAttribut;
      Modif.Cible     := Attribut(ConstXmlData);
      Modif.Filtre    := Attribut(ConstXmlModifieArmeCompetence);
      if Modif.Filtre = '' then Modif.Filtre := Attribut('if');
      Modif.Facteur   := Valeur;
    end;
  Result := True;
end;

Function XmlReplace(Source: String): String;
begin
  result := ReplaceText(Source, '&', '&amp;');
end;

Function xmlDataBase(): String;
begin
  Result := XmlReplace('<?xml version="1.0" encoding="UTF-8"?>');
end;

Function XmlLigne(TypeDonnee: string; Valeur: String): String;
  begin
    Result := XmlReplace(XmlDebut(TypeDonnee) + '"' + Valeur + '"' + XmlFin(TypeDonnee));
  end;

Function XmlCommentaire(Valeur: String): String;
  begin
    Result := XmlReplace('  <!-- ' + Valeur + ' -->');
  end;

Function XmlLigneDonnee(TypeDonnee: String; Name: String; Valeur: String; Attribut: String): String;
  begin
    Result := XmlReplace(XmlDebut(TypeDonnee+' name="'+Name+'"'+Attribut) + '"' + Valeur + '"' + XmlFin(TypeDonnee));
  end;

Function XmlLigneLangue(TypeDonnee: String; Name: String; Valeur: String): String;
  begin
    Result := XmlReplace(XmlDebut(TypeDonnee+' language="'+Name+'"') + '"' + Valeur + '"' + XmlFin(TypeDonnee));
  end;

Function XmlDebut(TypeDonnee: string): String;
  begin
    Result := XmlReplace('<'+TypeDonnee+'>');
  end;

Function XmlFin(TypeDonnee: string): String;
  begin
    Result := XmlReplace('</'+TypeDonnee+'>');
  end;

Function XmlDebutCode(TypeDonnee: string; Valeur: String): String;
  begin
    Result := XmlReplace('<'+TypeDonnee+' id='+ '"' + Valeur + '"' +'>');
  end;

Function XmlFinCode(TypeDonnee: String): String;
  begin
    Result := XmlReplace('</'+TypeDonnee+'>');
  end;

Function XmlDebutLangue(TypeDonnee: String; Name: String): String;
  begin
    Result := XmlReplace(XmlDebut(TypeDonnee+' language="'+Name+'"'));
  end;

Function XmlCodeLivre(Livre: String): String;
Var
  CodeLivre: String = '';
begin
  // Le code lu dans CODE_BOOK au chargement fait foi ; les 31 livres de la base en portent un ; vide si le livre est inconnu.
  CodeLivre := ChercheLivreLibelle(Livre).CodeLivre;
  if CodeLivre <> '' then
    begin
      Result := CodeLivre;
      Exit;
    end;
  Result := CodeLivre;
end;

Function XmlCreeCodeLivre(Livre: String; Code: String): String;
Var
  CodeLivre: String = '';
  Res:       String = '';
begin
    if Code <> '' then
      begin
        if Pos(SeparateurLivre, Code) < 1 then
          begin
            CodeLivre := XmlCodeLivre(Livre);
            Res       := CodeLivre+SeparateurLivre+Code;
          end
        else
          Res       := Code;
      end;
    Result := Res;
end;

Function TexteOuPage(Const Description, Bloc, Livre, Code: String): String;
  var
    Page: String;
  begin
    Result := Description;
    if (not ImagesDefautSeul) and (Trim(Description) <> '') then Exit;
    Page := PageFiche(Bloc, XmlCreeCodeLivre(Livre, Code));
    if Page = '' then
      Page := PageFiche(Bloc, Code);
    if Page <> '' then
      begin
        if (Pos('-', Page) > 0) or (Pos(',', Page) > 0) then
          Result := 'Pages ' + Page
        else
          Result := 'Page ' + Page;
      end
    else if ImagesDefautSeul then
      Result := '';
  end;

// DescriptionTalent (avec sa table de tirage) ou "Page N" : meme regle que TexteOuPage.
Function DescriptionTalentOuPage(Const CodeTalent, CodeRace: String): String;
  var
    PTalent: StructureTalent;
  begin
    PTalent := ChercheTalent(CodeTalent);
    if ImagesDefautSeul or (Trim(PTalent.Description) = '') then
      Result := TexteOuPage(PTalent.Description, ConstXmlDataTalent, PTalent.Livre, PTalent.CodeTalent)
    else
      Result := DescriptionTalent(CodeTalent, CodeRace);
  end;

// Ecrivain commun des modificateurs numeriques (CONTEXT.md 2.105, e2b) : ecrit dans Contenu tous
// les modificateurs de ListModificateur portes par (TypeSource, CodeSource), dans le format que
// LitModificateurNoeud relit. Format historique (<ModifyCarac name="Cible">"N"</ModifyCarac>,
// skill= pour ModifyWeapon) tant que le Filtre est vide ou propre a ModifyWeapon, sinon format
// generique <Modificateur Type= Cible= Facteur= Filtre=/>. Niveau >= 0 restreint aux entrees de
// ce palier (CareerBonus). Ecrit seulement dans le fichier anglais, comme le chargement.
Procedure XmlAjouteModificateurs(Contenu: TStringList; Const TypeSource, CodeSource: String; Const Langue: String; Niveau: Integer = -1);
var
  Modif: StructureModificateur;
  Balise, Ligne: String;
begin
  if Langue <> ConstAnglais then Exit;
  for Modif in ListModificateur do
    begin
      if (Modif.TypeSource <> TypeSource) or (Modif.CodeSource <> CodeSource) then Continue;
      if (Niveau >= 0) and (Modif.Niveau <> Niveau) then Continue;
      Balise := Modif.TypeModif;
      if Modif.Aleatoire and (Balise = ConstXmlModifieAttribut) then
        Balise := ConstXmlModifieAttributAleatoire;
      if not EcritureGenerique(Modif.TypeModif, Modif.Filtre) then
        begin
          Ligne := '';
          if Modif.Filtre <> '' then
            Ligne := ' ' + ConstXmlModifieArmeCompetence + '="' + Modif.Filtre + '"';
          Contenu.Add(XmlLigneDonnee(Balise, Modif.Cible, IntToStr(Modif.Facteur), Ligne));
        end
      else
        begin
          Ligne := '<' + ConstXmlModificateur + ' ' + ConstXmlType + '="' + Modif.TypeModif + '" ' +
                   ConstXmlEffetCible + '="' + Modif.Cible + '" ' + ConstXmlEffetFacteur + '="' +
                   IntToStr(Modif.Facteur) + '" ' + ConstXmlModificateurFiltre + '="' + Modif.Filtre + '"/>';
          Contenu.Add(XmlReplace(Ligne));
        end;
    end;
end;

Procedure EcritAttribut(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PAttribut:  StructureAttribut;
    Fist:       Boolean;
  begin
    Fist := true;
    for PAttribut in ListeAttribut do
      if (PAttribut.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataAttribut));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlAttribut, XmlCreeCodeLivre(PAttribut.Livre, PAttribut.CodeAttribut)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PAttribut.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PAttribut.Description));
          XmlContent.Add(XmlLigneLangue(ConstXmlShort, Langue, PAttribut.Resume));
          XmlContent.Add(XmlLigne(ConstXmlOrder, IntToStr(PAttribut.OrdreAttribut)));
          XmlContent.Add(XmlFinCode(ConstXmlAttribut));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataAttribut));
  end;

Procedure EcritAttributCost(XMLContent: TStringList; Livre: String);
  var
    PAttributAugmentation:  StructureAttributAugmentation;
    Fist:                   Boolean;
  begin
    Fist := true;
    for PAttributAugmentation in ListeAttributAugmentation do
      if (PAttributAugmentation.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataAttributCost));
              Fist := false;
            end;
          XmlContent.Add(XmlLigneDonnee(ConstXmlCout, PAttributAugmentation.MinMax, IntToStr(PAttributAugmentation.Cout)));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataAttributCost));
  end;

Procedure EcritSkillCost(XMLContent: TStringList; Livre: String);
  var
    PCompetenceAugmentation:  StructureCompetenceAugmentation;
    Fist:                     Boolean;
  begin
    Fist := true;
    for PCompetenceAugmentation in ListeCompetenceAugmentation do
      if (PCompetenceAugmentation.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSkillCost));
              Fist := false;
            end;
          XmlContent.Add(XmlLigneDonnee(ConstXmlCout, PCompetenceAugmentation.MinMax, IntToStr(PCompetenceAugmentation.Cout)));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSkillCost));
  end;

Procedure EcritLabel(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PTexte:  StructureTexte;
    Fist:    Boolean;
  begin
    Fist := true;
    for PTexte in ListTexte do
      if PTexte.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataLabel));
              XmlContent.Add(XmlDebutLangue(ConstXmlLabel, Langue));
              Fist := false;
            end;
          XmlContent.Add(XmlLigneDonnee(ConstXmlTexte, XmlCreeCodeLivre(Livre, PTexte.Code), PTexte.Libelle));
        end;
    if Fist = false then
      begin
        XmlContent.Add(XmlFin(ConstXmlLabel));
        XmlContent.Add(XmlFin(ConstXmlDataLabel));
      end;
  end;

Procedure EcritSkill(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PCompetence:  StructureCompetence;
    Fist:         Boolean;
  begin
    Fist := true;
    for PCompetence in ListCompetence do
      if (PCompetence.Livre = Livre) and (PCompetence.SousCompetence = false) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSkill));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlCompetence, XmlCreeCodeLivre(PCompetence.Livre, PCompetence.CodeCompetence)));
          XmlContent.Add(XmlLigne(ConstXmlCarac, XmlCreeCodeLivre(ConstRulesBook, PCompetence.CodeAttribut)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PCompetence.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PCompetence.Description));
          if PCompetence.DeBase then
            XmlContent.Add(XmlLigne(ConstXmlDeBase, ConstVrai));
          XmlContent.Add(XmlFinCode(ConstXmlCompetence));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSkill));
  end;

Procedure EcritSkillSpe(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PCompetence:  StructureCompetence;
    Fist:         Boolean;
  begin
    Fist := true;
    for PCompetence in ListCompetence do
      if (PCompetence.Livre = Livre) and (PCompetence.SousCompetence = true) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSkillSpe));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlCompetence, XmlCreeCodeLivre(PCompetence.Livre, PCompetence.CodeCompetence)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PCompetence.Libelle));
          if PCompetence.CodeGenerique <> '' then
            XmlContent.Add(XmlLigne(ConstXmlGenerique, PCompetence.CodeGenerique));
          if PCompetence.DeBase then
            XmlContent.Add(XmlLigne(ConstXmlDeBase, ConstVrai));
          XmlContent.Add(XmlFinCode(ConstXmlCompetence));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSkillSpe));
  end;

Procedure EcritTalent(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PTalent:                 StructureTalent;
    PTalentEffet:            StructureTalentEffet;
    PTalentCompetenceModif:  StructureTalentCompetenceModif;
    LigneEffet:              String;
    Fist:                    Boolean;
  begin
    Fist := true;
    for PTalent in ListTalent do
      if (PTalent.Livre = Livre) and (PTalent.SousTalent = false) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataTalent));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlTalent, XmlCreeCodeLivre(PTalent.Livre, PTalent.CodeTalent)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PTalent.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlShort, Langue, PTalent.Resume));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PTalent.Description));
          XmlContent.Add(XmlLigne(ConstXmlMax, PTalent.MaxiTalent));
          XmlContent.Add(XmlLigne(ConstXmlForPdf, PTalent.TalentPdf));
          if PTalent.OctroiCarriere <> '' then
            XmlContent.Add(XmlLigne(ConstXmlOctroiCarriere, PTalent.OctroiCarriere));
          if PTalent.RetraitCarriere <> '' then
            XmlContent.Add(XmlLigne(ConstXmlRetraitCarriere, PTalent.RetraitCarriere));
          // ecrite seulement si vraie : les ~700 talents ordinaires ne portent pas la balise
          if PTalent.Trait then
            XmlContent.Add(XmlLigne(ConstXmlTrait, ConstVrai));
          if PTalent.Magie > 0 then
            XmlContent.Add(XmlLigne(ConstXmlMagie, IntToStr(PTalent.Magie)));
          if PTalent.ModeSort <> '' then
            XmlContent.Add(XmlLigne(ConstXmlModeSort, PTalent.ModeSort));
          if PTalent.TypesSort <> '' then
            XmlContent.Add(XmlLigne(ConstXmlTypesSort, PTalent.TypesSort));
          // Tarif des sorts. Le bloc n'est ecrit QUE si au moins un des cinq champs a ete
          // renseigne : un talent magique sans tarification n'en gagne donc pas a l'export.
          // C'est voulu - l'absence de tarif EST le tarif des Blessings (multiplicateur 0,
          // donc sorts gratuits), et ecrire un <XpMultiplier>0</XpMultiplier> partout
          // reviendrait a declarer gratuits tous les talents qu'on n'a pas encore traites.
          // A l'interieur du bloc, les deux entiers sont ecrits meme a 0 : 0 y est une
          // valeur (plancher nul), pas une absence.
          if (PTalent.XpMultiplicateur <> 0) or (PTalent.XpPlancher <> 0) or
             (PTalent.XpDiviseur <> '') or (PTalent.XpOfferts <> '') or (PTalent.XpGroupe <> '') then
            begin
              XmlContent.Add(XmlLigne(ConstXmlXpMultiplicateur, IntToStr(PTalent.XpMultiplicateur)));
              XmlContent.Add(XmlLigne(ConstXmlXpPlancher, IntToStr(PTalent.XpPlancher)));
              if PTalent.XpDiviseur <> '' then
                XmlContent.Add(XmlLigne(ConstXmlXpDiviseur, PTalent.XpDiviseur));
              if PTalent.XpOfferts <> '' then
                XmlContent.Add(XmlLigne(ConstXmlXpOfferts, PTalent.XpOfferts));
              if PTalent.XpGroupe <> '' then
                XmlContent.Add(XmlLigne(ConstXmlXpGroupe, PTalent.XpGroupe));
            end;
          XmlContent.Add(XmlLigneLangue(ConstXmlTest, Langue, PTalent.Tests));
          XmlAjouteModificateurs(XmlContent, SourceModifTalent, PTalent.CodeTalent, Langue);
          // <ModifySkill name="X">"Bonus"|"ChooseDice"</ModifySkill> : drapeau de competence du talent,
          // pas un modificateur chiffre (lu par ChargeTalentCompetenceModif)
          for PTalentCompetenceModif in ListTalentCompetenceModif do
            if (PTalentCompetenceModif.Livre = Livre) and (PTalentCompetenceModif.CodeTalent = PTalent.CodeTalent) then
              XmlContent.Add(XmlLigneDonnee(ConstXmlModifieCompetence, PTalentCompetenceModif.CodeCompetence, PTalentCompetenceModif.TypeModif));
          // <Effet Cible= Forme= Facteur= [Carac=]/> : drapeaux de calcul du moteur
          for PTalentEffet in ListTalentEffet do
            if (PTalentEffet.Livre = Livre) and (PTalentEffet.CodeTalent = PTalent.CodeTalent) then
              begin
                LigneEffet := '<' + ConstXmlEffet + ' ' + ConstXmlEffetCible + '="' + PTalentEffet.Cible + '" ' +
                         ConstXmlEffetForme + '="' + PTalentEffet.Forme + '" ' +
                         ConstXmlEffetFacteur + '="' + IntToStr(PTalentEffet.Facteur) + '"';
                if PTalentEffet.Carac <> '' then
                  LigneEffet := LigneEffet + ' ' + ConstXmlEffetCarac + '="' + PTalentEffet.Carac + '"';
                XmlContent.Add(XmlReplace(LigneEffet + '/>'));
              end;

          XmlContent.Add(XmlFinCode(ConstXmlTalent));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataTalent));
  end;

Procedure EcritCorruption(XMLContent: TStringList; Livre: String; Langue: String);
  var
    IndCorr:                             Integer;
    TypeCorr:                            String;
    PRaceCorruptionCreation:             StructureRaceCorruptionCreation;
    PCorruptionTable:                    StructureCorruptionTable;
    PCorruptionChance:                   StructureCorruptionChance;
    PCorruptionCompetenceAttributModif:  StructureCorruptionCompetenceAttributModif;
    PCorruptionTalent:                   StructureCorruptionTalent;
    PCorruptionEquipement:               StructureCorruptionEquipement;
    Fist:                                Boolean;
  begin
    for IndCorr := 0 to 1 do
      begin
        if IndCorr = 0 then TypeCorr := CorruptionPhysique else TypeCorr := CorruptionMentale;
        Fist := true;
        for PRaceCorruptionCreation in ListRaceCorruptionCreation do
          if (PRaceCorruptionCreation.Livre = Livre) and (PRaceCorruptionCreation.TypeCorruption = TypeCorr) then
            begin
              if Fist then
                begin
                  if IndCorr = 0 then XmlContent.Add(XmlDebut(ConstXmlDataPhysicalCorruption))
                  else XmlContent.Add(XmlDebut(ConstXmlDataMentalCorruption));
                  Fist := false;
                end;
              XmlContent.Add(XmlLigneDonnee(ConstXmlRace, PRaceCorruptionCreation.CodeRace, PRaceCorruptionCreation.Chance));
            end;
        if not Fist then
          begin
            if IndCorr = 0 then XmlContent.Add(XmlFin(ConstXmlDataPhysicalCorruption))
            else XmlContent.Add(XmlFin(ConstXmlDataMentalCorruption));
          end;

        Fist := true;
        for PCorruptionTable in ListCorruptionTable do
          if (PCorruptionTable.Livre = Livre) and (PCorruptionTable.TypeCorruption = TypeCorr) then
            begin
              if Fist then
                begin
                  if IndCorr = 0 then XmlContent.Add(XmlDebut(ConstXmlDataCorruptionTablePhys))
                  else XmlContent.Add(XmlDebut(ConstXmlDataCorruptionTableMent));
                  Fist := false;
                end;
              XmlContent.Add(XmlDebut('Corruption name="' + PCorruptionTable.Code + '"'));
              XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PCorruptionTable.Libelle));
              XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PCorruptionTable.Effet));
              XmlAjouteModificateurs(XmlContent, SourceModifMutation, PCorruptionTable.Code, Langue);
              if Langue = ConstAnglais then
                begin
                  for PCorruptionCompetenceAttributModif in ListCorruptionCompetenceAttributModif do
                    if (PCorruptionCompetenceAttributModif.Livre = Livre) and (PCorruptionCompetenceAttributModif.CodeCorruption = PCorruptionTable.Code) then
                      XmlContent.Add(XmlLigneDonnee(ConstXmlModifieCompetenceAttribut, PCorruptionCompetenceAttributModif.CodeAttribut, IntToStr(PCorruptionCompetenceAttributModif.Valeur)));
                  for PCorruptionTalent in ListCorruptionTalent do
                    if (PCorruptionTalent.Livre = Livre) and (PCorruptionTalent.CodeCorruption = PCorruptionTable.Code) then
                      XmlContent.Add(XmlLigne(ConstXmlTalent, PCorruptionTalent.CodeTalent));
                  for PCorruptionEquipement in ListCorruptionEquipement do
                    if (PCorruptionEquipement.Livre = Livre) and (PCorruptionEquipement.CodeCorruption = PCorruptionTable.Code) then
                      begin
                        if PCorruptionEquipement.EstArme then
                          XmlContent.Add(XmlLigne(ConstXmlArme, PCorruptionEquipement.CodeEquipement))
                        else
                          XmlContent.Add(XmlLigne(ConstXmlArmure, PCorruptionEquipement.CodeEquipement));
                      end;
                end;
              XmlContent.Add(XmlFin('Corruption'));
            end;
        if not Fist then
          begin
            if IndCorr = 0 then XmlContent.Add(XmlFin(ConstXmlDataCorruptionTablePhys))
            else XmlContent.Add(XmlFin(ConstXmlDataCorruptionTableMent));
          end;

        Fist := true;
        for PCorruptionChance in ListCorruptionChance do
          if (PCorruptionChance.Livre = Livre) and (PCorruptionChance.TypeCorruption = TypeCorr) then
            begin
              if Fist then
                begin
                  if IndCorr = 0 then XmlContent.Add(XmlDebut(ConstXmlDataCorruptionPhysChance))
                  else XmlContent.Add(XmlDebut(ConstXmlDataCorruptionMentChance));
                  Fist := false;
                end;
              XmlContent.Add(XmlLigneDonnee(ConstXmlChance, PCorruptionChance.Chance, PCorruptionChance.Code));
            end;
        if not Fist then
          begin
            if IndCorr = 0 then XmlContent.Add(XmlFin(ConstXmlDataCorruptionPhysChance))
            else XmlContent.Add(XmlFin(ConstXmlDataCorruptionMentChance));
          end;
      end;
  end;

Procedure EcritTalentSpe(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PTalent:  StructureTalent;
    Fist:     Boolean;
  begin
    Fist := true;
    for PTalent in ListTalent do
      if (PTalent.Livre = Livre) and (PTalent.SousTalent = true) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataTalentSpe));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlTalent, XmlCreeCodeLivre(PTalent.Livre, PTalent.CodeTalent)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PTalent.Libelle));
          if PTalent.CodeGenerique <> '' then
            XmlContent.Add(XmlLigne(ConstXmlGenerique, PTalent.CodeGenerique));
          if PTalent.Trait then
            XmlContent.Add(XmlLigne(ConstXmlTrait, ConstVrai));
          XmlContent.Add(XmlFinCode(ConstXmlTalent));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataTalentSpe));
  end;

Procedure EcritRandomTalent(XMLContent: TStringList; Livre: String);
  var
    PTalent:          StructureTalent;
    PRace:            StructureRace;
    PTalentCreation:  StructureTalentCreation;
    Fist:             Boolean;
  begin
    Fist := true;
    for PTalentCreation in ListTalentCreation do
      if (PTalentCreation.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataRandomTalent));
              Fist := false;
            end;
          PTalent := ChercheTalent(PTalentCreation.CodeTalent);
          XmlContent.Add(XmlDebutCode(ConstXmlDataRandomTalent, XmlCreeCodeLivre(PTalent.Livre, PTalent.CodeTalent)));
          PRace := ChercheRace(PTalentCreation.CodeRace);
          XmlContent.Add(XmlLigne(ConstXmlRace, XmlCreeCodeLivre(PRace.Livre, PTalentCreation.CodeRace)));
          XmlContent.Add(XmlLigneDonnee(ConstXmlTalent, XmlCreeCodeLivre(PTalent.Livre, PTalent.CodeTalent), PTalentCreation.Chance));
          XmlContent.Add(XmlCommentaire(LibelleTalent(PTalentCreation.CodeTalent)));
          XmlContent.Add(XmlFinCode(ConstXmlDataRandomTalent));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataRandomTalent));
  end;

Procedure EcritEspece(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PEspece:        StructureEspece;
    PRacePhysique:  StructureRacePhysique;
    PRaceCouleur:   StructureRaceCouleur;
    Fist2:          Boolean;
    PRaceOpinion:   StructureRaceOpinion;
    Fist:           Boolean;
  begin
    Fist := true;
    for PEspece in ListEspece do
      if PEspece.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataEspece));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlEspece, XmlCreeCodeLivre(PEspece.Livre, PEspece.CodeEspece)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PEspece.Libelle));
          // ecrit seulement si la race designe son propre dossier d'icones de niveau
          if PEspece.DossierNiveau <> '' then
            XmlContent.Add(XmlLigne(ConstXmlPictureLevel, PEspece.DossierNiveau));
          // Opinions de cette race sur les autres (texte brut, sans guillemets, comme a la lecture)
          Fist2 := true;
          for PRaceOpinion in ListRaceOpinion do
            if (PRaceOpinion.CodeRace = PEspece.CodeEspece) and (PRaceOpinion.Livre = Livre) then
              begin
                if Fist2 then
                  begin
                    XmlContent.Add(XmlDebut(ConstXmlOpinions));
                    Fist2 := false;
                  end;
                XmlContent.Add(XmlReplace('<'+ConstXmlOpinion+' '+ConstXmlTarget+'="'+PRaceOpinion.TargetRace+'" '
                               +ConstXmlSource+'="'+PRaceOpinion.Source+'">'+PRaceOpinion.Citation+'</'+ConstXmlOpinion+'>'));
              end;
          if not Fist2 then
            XmlContent.Add(XmlFin(ConstXmlOpinions));
          // Details physiques de la RACE (age, taille, yeux, cheveux)
          PRacePhysique := ChercheRacePhysique(PEspece.CodeEspece);
          if PRacePhysique.CodeRace <> '' then
            begin
              XmlContent.Add(XmlDebut(ConstXmlSousChapitrePhysique));
              XmlContent.Add(XmlLigne(ConstXmlAge, PRacePhysique.FormuleAge));
              XmlContent.Add(XmlLigne(ConstXmlHeight, PRacePhysique.FormuleTaille));
              if PRacePhysique.TailleExplose then
                XmlContent.Add(XmlLigne(ConstXmlPhysTailleExplose, ConstVrai));
              // 1 est la valeur par defaut a la lecture : ecrit seulement si elle differe
              if PRacePhysique.NbTirageYeux <> 1 then
                XmlContent.Add(XmlLigne(ConstXmlPhysNbTirageYeux, IntToStr(PRacePhysique.NbTirageYeux)));
              for PRaceCouleur in ListRaceCouleur do
                if (PRaceCouleur.CodeRace = PEspece.CodeEspece) and PRaceCouleur.EstYeux then
                  XmlContent.Add(XmlLigneDonnee(ConstXmlPhysYeux, PRaceCouleur.Libelle, PRaceCouleur.Plage));
              for PRaceCouleur in ListRaceCouleur do
                if (PRaceCouleur.CodeRace = PEspece.CodeEspece) and not PRaceCouleur.EstYeux then
                  XmlContent.Add(XmlLigneDonnee(ConstXmlPhysCheveux, PRaceCouleur.Libelle, PRaceCouleur.Plage));
              XmlContent.Add(Xmlfin(ConstXmlSousChapitrePhysique));
            end;
          XmlContent.Add(XmlFinCode(ConstXmlEspece));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataEspece));
  end;

Procedure EcritNation(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PNation:  StructureNation;
    Fist:     Boolean;
  begin
    Fist := true;
    for PNation in ListNation do
      if PNation.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataNation));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlNation, XmlCreeCodeLivre(PNation.Livre, PNation.CodeNation)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PNation.Libelle));
          XmlContent.Add(XmlFinCode(ConstXmlNation));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataNation));
  end;

Procedure EcritSpecie(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PCompetence:        StructureCompetence;
    PTalent:            StructureTalent;
    PRace:              StructureRace;
    PRaceAttribut:      StructureRaceAttribut;
    PRaceNom:           StructureRaceNom;
    PRaceNomModele:     StructureRaceNomModele;
    PRaceNomRegle:      StructureRaceNomRegle;
    PRaceCompetence:    StructureRaceCompetence;
    PRaceTalent:        StructureRaceTalent;
    PRaceMetierSource:  StructureRaceMetierSource;
    XmlDebutMetier:     Integer;
    PMetier:            StructureMetier;
    PAttribut:          StructureAttribut;
    Fist:               Boolean;
  begin
    Fist := true;
    For PRace In ListRace do
      if PRace.Livre = Livre then
        begin
          if Fist = True then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSpecie));
              Fist := false;
            end;
          // données de base
          XmlContent.Add(XmlDebutCode(ConstXmlRace, XmlCreeCodeLivre(PRace.Livre, PRace.CodeRace)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PRace.Libelle));
          if PRace.Description <> '' then
            XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PRace.Description));
          XmlContent.Add(XmlLigne(ConstXmlEthnic, PRace.Espece));
          // ecrit seulement si l'ethnie appartient a une nation - la plupart n'en ont
          // aucune (Nains, Elfes, Norses...). CONTEXT.md 2.51.
          if Trim(PRace.Nation) <> '' then
            XmlContent.Add(XmlLigne(ConstXmlNationality, PRace.Nation));
          // ecrites seulement si elles s'ecartent du defaut, pour ne pas alourdir les
          // dizaines de races qui prennent 3 et 3
          if PRace.NbPoint5 <> 3 then
            XmlContent.Add(XmlLigne(ConstXmlNbSkill5, IntToStr(PRace.NbPoint5)));
          if PRace.NbPoint3 <> 3 then
            XmlContent.Add(XmlLigne(ConstXmlNbSkill3, IntToStr(PRace.NbPoint3)));
          // Idem : ecrit seulement si l'ethnie designe son propre dossier d'icones
          // de niveau, pour ne pas alourdir les dizaines d'ethnies qui prennent NIV.
          if PRace.DossierNiveau <> '' then
            XmlContent.Add(XmlLigne(ConstXmlPictureLevel, PRace.DossierNiveau));
          // Attribut de race
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreCarac));
          for PRaceAttribut in ListRaceAttribut do
            if PRaceAttribut.CodeRace = PRace.CodeRace then
              begin
                PAttribut := ChercheAttribut(PRaceAttribut.CodeAttribut);
                XmlContent.Add(XmlLigneDonnee(ConstXmlCarac, XmlCreeCodeLivre(PAttribut.Livre, PRaceAttribut.CodeAttribut), PRaceAttribut.CalculRace));
              end;
          XmlContent.Add(Xmlfin(ConstXmlSousChapitreCarac));
          // Details physiques (ecrits seulement si l'ethnie en porte)
          // Noms (ecrits seulement si l'ethnie en porte)
          if EthnieANoms(PRace.CodeRace) then
            begin
              XmlContent.Add(XmlDebut(ConstXmlSousChapitreNoms));
              for PRaceNomModele in ListRaceNomModele do
                if PRaceNomModele.CodeRace = PRace.CodeRace then
                  XmlContent.Add(XmlReplace(XmlDebut(ConstXmlNomModele + IfThen(PRaceNomModele.Sexe <> '', ' ' + ConstXmlNomSexe + '="' + PRaceNomModele.Sexe + '"', '')
                                                                     + IfThen(PRaceNomModele.Regle <> '', ' ' + ConstXmlNomRegle + '="' + PRaceNomModele.Regle + '"', ''))
                                 + '"' + PRaceNomModele.Modele + '"' + XmlFin(ConstXmlNomModele)));
              for PRaceNomRegle in ListRaceNomRegle do
                if PRaceNomRegle.CodeRace = PRace.CodeRace then
                  XmlContent.Add(XmlReplace(XmlDebut(ConstXmlNomRegleDecl + ' ' + ConstXmlNomRegleCode + '="' + PRaceNomRegle.Code + '"')
                                 + '"' + PRaceNomRegle.Libelle + '"' + XmlFin(ConstXmlNomRegleDecl)));
              for PRaceNom in ListRaceNom do
                if PRaceNom.CodeRace = PRace.CodeRace then
                  XmlContent.Add(XmlLigneDonnee(ConstXmlNom, PRaceNom.Libelle, PRaceNom.Plage,
                                 ' ' + ConstXmlNomPartie + '="' + PRaceNom.Partie + '"'
                                 + IfThen(PRaceNom.Sexe <> '', ' ' + ConstXmlNomSexe + '="' + PRaceNom.Sexe + '"', '')));
              XmlContent.Add(Xmlfin(ConstXmlSousChapitreNoms));
            end;
          // Compétence
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreCompetence));
          for PRaceCompetence in ListRaceCompetence do
            if PRaceCompetence.CodeRace = PRace.CodeRace then
              begin
                PCompetence := ChercheCompetence(PRaceCompetence.CodeCompetence);
                XmlContent.Add(XmlLigne(ConstXmlCompetence, XmlCreeCodeLivre(PCompetence.Livre, PRaceCompetence.CodeCompetence)));
                PCompetence := ChercheCompetence(PRaceCompetence.CodeCompetence);
                XmlContent.Add(XmlCommentaire(PCompetence.Libelle));
              end;
          XmlContent.Add(XmlFin(ConstXmlSousChapitreCompetence));
          // Talent
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreTalent));
          for PRaceTalent in ListRaceTalent do
            if PRaceTalent.CodeRace = PRace.CodeRace then
              begin
                PTalent := ChercheTalent(PRaceTalent.CodeTalent);
                XmlContent.Add(XmlLigne(ConstXmlTalent, XmlCreeCodeLivre(PTalent.Livre, PRaceTalent.CodeTalent)));
                XmlContent.Add(XmlCommentaire(LibelleTalent(PRaceTalent.CodeTalent)));
              end;
          XmlContent.Add(XmlFin(ConstXmlSousChapitreTalent));
          // Metier
          // Ecrit seulement s'il porte au moins un metier : un bloc vide n'est jamais declare
          // (les metiers d'une ethnie viennent alors de la fiche de carriere)
          XmlDebutMetier := XmlContent.Count;
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreMetier));
          for PRaceMetierSource in ListRaceMetierSource do
            if (PRaceMetierSource.Forme = FormeRaceMetierBlocEspece) and (PRaceMetierSource.Livre = Livre)
               and (PRaceMetierSource.CodeRace = PRace.CodeRace) then
              begin
                PMetier := ChercheMetier(PRaceMetierSource.CodeMetier);
                XmlContent.Add(XmlLigneDonnee(ConstXmlWork, XmlCreeCodeLivre(PMetier.Livre, PRaceMetierSource.CodeMetier), PRaceMetierSource.Chance));
                XmlContent.Add(XmlCommentaire(PMetier.Libelle));
              end;
          if XmlContent.Count = XmlDebutMetier + 1 then
            XmlContent.Delete(XmlDebutMetier)
          else
            XmlContent.Add(XmlFinCode(ConstXmlSousChapitreMetier));
          XmlContent.Add(XmlFinCode(ConstXmlRace));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSpecie));
  end;

Procedure EcritSpecieCreation(XMLContent: TStringList; Livre: String);
  var
    PRace:          StructureRace;
    PRaceCreation:  StructureRaceCreation;
    Fist:           Boolean;
  begin
    Fist := true;
    for PRaceCreation in ListRaceCreation do
      if (PRaceCreation.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSpecieCreation));
              Fist := false;
            end;
          PRace := ChercheRace(PRaceCreation.CodeRace);
          XmlContent.Add(XmlLigneDonnee(ConstXmlRace, XmlCreeCodeLivre(PRace.Livre, PRaceCreation.CodeRace), PRaceCreation.Chance));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSpecieCreation));
  end;

Procedure EcritCareer(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PCompetence:        StructureCompetence;
    PTalent:            StructureTalent;
    PRaceMetierSource:  StructureRaceMetierSource;
    PMetier:            StructureMetier;
    PMetierAttribut:    StructureMetierAttribut;
    PMetiercompetence:  StructureMetierCompetence;
    PMetierTalent:      StructureMetierTalent;
    PMetierEquipement:  StructureMetierEquipement;
    PMetierNiveau:      StructureMetierNiveau;
    PAttribut:          StructureAttribut;
    Fist:               Boolean;
    Ind:                Integer;
    LigneEquipement:    String;
    QuantiteAttr:       String;
  begin
    Fist := true;
    for PMetier in ListMetier do
      if PMetier.Livre = Livre then
        begin
          if Fist = True then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataCareer));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlWork, XmlCreeCodeLivre(PMetier.Livre, PMetier.CodeMetier)));
          // données de base
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PMetier.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PMetier.Description));
          PCompetence := ChercheCompetence(PMetier.CodeCompetence);
          XmlContent.Add(XmlLigne(ConstXmlCompetence, XmlCreeCodeLivre(PCompetence.Livre, PMetier.CodeCompetence)));
          XmlContent.Add(XmlLigne(ConstXmlClass, PMetier.LibelleGroupe));
          // Races declarees dans la fiche de la carriere (<Specie>), telles que lues : la
          // race peut venir d'un autre livre, elle n'apparait alors dans aucun bloc de celui-ci
          for PRaceMetierSource in ListRaceMetierSource do
            if (PRaceMetierSource.Forme = FormeRaceMetierFicheMetier) and (PRaceMetierSource.Livre = Livre)
               and (PRaceMetierSource.CodeMetier = PMetier.CodeMetier) then
              XmlContent.Add(XmlLigne(ConstXmlRace, PRaceMetierSource.CodeRace));
          // Ecrit seulement si le metier designe son propre dossier d'icones de niveau.
          if PMetier.DossierNiveau <> '' then
            XmlContent.Add(XmlLigne(ConstXmlPictureLevel, PMetier.DossierNiveau));
          // Idem pour la carriere parente. Reecrit TEL QUEL, sans passer par
          // XmlCreeCodeLivre : ce champ peut contenir plusieurs codes separes par
          // SeparateurMulti, et XmlCreeCodeLivre prefixerait la chaine entiere comme un
          // code unique. Les codes parents sont de toute facon toujours declares
          // complets, donc XmlCreeCodeLivre les laisserait intacts.
          if PMetier.MetierParent <> '' then
            XmlContent.Add(XmlLigne(ConstXmlMetierParent, PMetier.MetierParent));

          // Niveau
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreNiveau));
          for PMetierNiveau in ListMetierNiveau do
            For Ind := 1 to ChercheMaxMetierNiveau(PMEtier.CodeMetier) do
              begin
                if (PMetierNiveau.CodeMetier = PMetier.CodeMetier) and (PMetierNiveau.NiveauMetier = Ind) then
                   begin
                     XmlContent.Add(XmlDebutCode(ConstXmlNiveau, IntToStr(PMetierNiveau.NiveauMetier)));
                     XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PMetierNiveau.Libelle));
                     XmlContent.Add(XmlLigne(ConstXmlSalaire, PMetierNiveau.SalaireMetier));
                     XmlContent.Add(XmlFinCode(ConstXmlNiveau));
                   end;
              end;
          XmlContent.Add(XmlFin(ConstXmlSousChapitreNiveau));

          // Attribut
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreCarac));
          for PMetierAttribut in ListMetierAttribut do
            if (PMetierAttribut.CodeMetier = PMetier.CodeMetier) then
              begin
                PAttribut := ChercheAttribut(PMetierAttribut.CodeAttribut);
               XmlContent.Add(XmlLigneDonnee(ConstXmlCarac, XmlCreeCodeLivre(PAttribut.Livre, PMetierAttribut.CodeAttribut), IntToStr(PMetierAttribut.NiveauMetier)));
              end;
          XmlContent.Add(XmlFin(ConstXmlSousChapitreCarac));

          // Competence
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreCompetence));
          for PMetierCompetence in ListMetierCompetence do
            if (PMetierCompetence.CodeMetier = PMetier.CodeMetier) then
              begin
                PCompetence := ChercheCompetence(PMetierCompetence.CodeCompetence);
                XmlContent.Add(XmlLigneDonnee(ConstXmlCompetence, XmlCreeCodeLivre(PCompetence.Livre, PMetierCompetence.CodeCompetence), IntToStr(PMetierCompetence.NiveauMetier)));
                XmlContent.Add(XmlCommentaire(PCompetence.Libelle));
              end;
          XmlContent.Add(XmlFin(ConstXmlSousChapitreCompetence));

          // Talent
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreTalent));
          for PMetierTalent in ListMetierTalent do
            if (PMetierTalent.CodeMetier = PMetier.CodeMetier) then
              begin
                PTalent := ChercheTalent(PMetierTalent.CodeTalent);
                XmlContent.Add(XmlLigneDonnee(ConstXmlTalent, XmlCreeCodeLivre(PTalent.Livre,  PMetierTalent.CodeTalent), IntToStr(PMetierTalent.NiveauMetier)));
                XmlContent.Add(XmlCommentaire(PTalent.Libelle));
              end;
          XmlContent.Add(XmlFin(ConstXmlSousChapitreTalent));

          // Equipement
          XmlContent.Add(XmlDebut(ConstXmlSousChapitreEquipement));
          for PMetierEquipement in ListMetierEquipement do
            if (PMetierEquipement.CodeMetier = PMetier.CodeMetier) then
              begin

                // Chaine du livre telle que lue (choix "A/B", combinaisons "A+B", qualite " (Q)") :
                // la reconstruire par type d'objet perdait les codes composes et l'espace de la qualite.
                LigneEquipement := PMetierEquipement.Equipement;
                  // Meme principe que Porte/Quantite cote personnage (chargepersonnage.pas
                  // XmlAttributEquipementQuantite) : attribut absent si Quantite=1, pour que
                  // les livres deja exportes sans le champ restent lisibles comme "1 exemplaire".
                  if PMetierEquipement.QuantiteListe <> '' then
                    QuantiteAttr := ' '+ConstXmlEquipementQuantite+'="'+PMetierEquipement.QuantiteListe+'"'
                  else if PMetierEquipement.Quantite <> 1 then
                    QuantiteAttr := ' '+ConstXmlEquipementQuantite+'="'+IntToStr(PMetierEquipement.Quantite)+'"'
                  else
                    QuantiteAttr := '';
                  XmlContent.Add(XmlLigneDonnee(ConstXmlEquipement, LigneEquipement, IntToStr(PMetierEquipement.NiveauMetier), QuantiteAttr));
                  LigneEquipement  := '';
                end;


          XmlContent.Add(XmlFin(ConstXmlSousChapitreEquipement));

          XmlContent.Add(XmlFinCode(ConstXmlWork));
        end;


    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataCareer));
  end;

Procedure EcritWeapon(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PArme:        StructureArme;
    Fist:         Boolean;
  begin
    Fist := true;
    for PArme in ListArme do
      if (PArme.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataWeapon));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlArme, XmlCreeCodeLivre(PArme.Livre, PArme.CodeArme)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PArme.Libelle));
          XmlContent.Add(XmlLigne(ConstXmlCompetence, XmlCreeCodeLivre(PArme.Livre, PArme.CodeCompetence)));
          XmlContent.Add(XmlLigne(ConstXmlDamage, PArme.CalculDegat));
          if PArme.Disponibilite <> '' then
            XmlContent.Add(XmlLigne(ConstXmlDisponibilite, PArme.Disponibilite));
          XmlContent.Add(XmlLigne(ConstXmlPorteeArme, PArme.Portee));
          if PArme.Prix <> '' then
            XmlContent.Add(XmlLigne(ConstXmlPrix, PArme.Prix));
          XmlContent.Add(XmlLigne(ConstXmlEncombrement, IntToStr(PArme.Encombrement)));
          XmlContent.Add(XmlLigne(ConstXmlQualite, PArme.ListeBonus));
          XmlContent.Add(XmlLigne(ConstXmlMains, IntToStr(PArme.Mains)));
          XmlContent.Add(XmlLigne(ConstXmlMunition, IntToStr(PArme.Munition)));
          if PArme.TypeArme <> '' then
            XmlContent.Add(XmlLigne(ConstXmlType, PArme.TypeArme));
          if PArme.Fabrication <> '' then
            XmlContent.Add(XmlLigne(ConstXmlFabIntegree, PArme.Fabrication));
          XmlAjouteModificateurs(XmlContent, SourceModifArme, PArme.CodeArme, Langue);

          XmlContent.Add(XmlFinCode(ConstXmlArme));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataWeapon));
  end;

Procedure EcritWeaponBonus(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PArmeBonus:  StructureArmeBonus;
    Fist:        Boolean;
  begin
    Fist := true;
    for PArmeBonus in ListArmeBonus do
      if (PArmeBonus.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataWeaponBonus));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlBonus, XmlCreeCodeLivre(PArmeBonus.Livre, PArmeBonus.CodeArmeBonus)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PArmeBonus.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PArmeBonus.Description));
          XmlContent.Add(XmlLigneLangue(ConstXmlShort, Langue, PArmeBonus.Resume));
          XmlAjouteModificateurs(XmlContent, SourceModifQualiteArme, PArmeBonus.CodeArmeBonus, Langue);
          XmlContent.Add(XmlLigne(ConstXmlPositifNegatif, PArmeBonus.PlusMoins));
          if PArmeBonus.NeedsValue <> '' then
            XmlContent.Add(XmlLigne('NeedsValue', PArmeBonus.NeedsValue));

          XmlContent.Add(XmlFinCode(ConstXmlBonus));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataWeaponBonus));
  end;

Procedure EcritArmor(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PArmure:  StructureArmure;
    Fist:     Boolean;
  begin
    Fist := true;
    for PArmure in ListArmure do
      if (PArmure.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataArmor));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlArmure, XmlCreeCodeLivre(PArmure.Livre, PArmure.CodeArmure)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PArmure.Libelle));
          if PArmure.Disponibilite <> '' then
            XmlContent.Add(XmlLigne(ConstXmlDisponibilite, PArmure.Disponibilite));
          if PArmure.Prix <> '' then
            XmlContent.Add(XmlLigne(ConstXmlPrix, PArmure.Prix));
          XmlContent.Add(XmlLigne(ConstXmlEncombrement, IntToStr(PArmure.Encombrement)));
          XmlContent.Add(XmlLigne(ConstXmlQualite, PArmure.ListeBonus));
          XmlContent.Add(XmlLigne(ConstXmlEmplacement, PArmure.Emplacement));
          XmlContent.Add(XmlLigne(ConstXmlProtection, IntToStr(PArmure.Protection)));
          XmlContent.Add(XmlLigne(ConstXmlType, PArmure.TypeMateriel));
          if PArmure.Fabrication <> '' then
            XmlContent.Add(XmlLigne(ConstXmlFabIntegree, PArmure.Fabrication));

          XmlContent.Add(XmlFinCode(ConstXmlArmure));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataArmor));
  end;

Procedure EcritTrapping(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PTrapping:  StructureTrapping;
    Fist:       Boolean;
  begin
    Fist := true;
    for PTrapping in ListTrapping do
      if (PTrapping.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataTrapping));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlTrapping, XmlCreeCodeLivre(PTrapping.Livre, PTrapping.CodeTrapping)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PTrapping.Libelle));
          if PTrapping.Disponibilite <> '' then
            XmlContent.Add(XmlLigne(ConstXmlDisponibilite, PTrapping.Disponibilite));
          if PTrapping.Prix <> '' then
            XmlContent.Add(XmlLigne(ConstXmlPrix, PTrapping.Prix));
          XmlContent.Add(XmlLigne(ConstXmlEncombrement, IntToStr(PTrapping.Encombrement)));
          if (PTrapping.Capacite <> 0) or PTrapping.CapaciteDeclaree then
            XmlContent.Add(XmlLigne(ConstXmlCapacite, IntToStr(PTrapping.Capacite)));
          if PTrapping.ProfilAnimal <> '' then
            XmlContent.Add(XmlLigne(ConstXmlProfilAnimal, PTrapping.ProfilAnimal));
          if PTrapping.TraitsAnimal <> '' then
            XmlContent.Add(XmlLigne(ConstXmlTraitsAnimal, PTrapping.TraitsAnimal));
          if PTrapping.ProfilBateau <> '' then
            XmlContent.Add(XmlLigne(ConstXmlProfilBateau, PTrapping.ProfilBateau));
          if PTrapping.ProfilVehicule <> '' then
            XmlContent.Add(XmlLigne(ConstXmlProfilVehicule, PTrapping.ProfilVehicule));
          if PTrapping.Theme <> '' then
            XmlContent.Add(XmlLigne(ConstXmlTheme, PTrapping.Theme));
          if PTrapping.Acheteur <> '' then
            XmlContent.Add(XmlLigne(ConstXmlAcheteur, PTrapping.Acheteur));
          if PTrapping.Localite <> '' then
            XmlContent.Add(XmlLigne(ConstXmlLocalite, PTrapping.Localite));
          if PTrapping.Saison <> '' then
            XmlContent.Add(XmlLigne(ConstXmlSaison, PTrapping.Saison));
          if PTrapping.Fabrication <> '' then
            XmlContent.Add(XmlLigne(ConstXmlFabIntegree, PTrapping.Fabrication));
          XmlAjouteModificateurs(XmlContent, SourceModifTrapping, PTrapping.CodeTrapping, Langue);

          XmlContent.Add(XmlFinCode(ConstXmlTrapping));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataTrapping));
  end;

Procedure EcritArmorSimplified(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PArmureSimplifiee:  StructureArmureSimplifiee;
    Fist:               Boolean;
  begin
    Fist := true;
    for PArmureSimplifiee in ListArmureSimplifieeSource  do
      if (PArmureSimplifiee.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataArmorSimplified));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlArmureSimplifiee, XmlCreeCodeLivre(PArmureSimplifiee.Livre, PArmureSimplifiee.CodeArmure)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PArmureSimplifiee.Libelle));
          XmlContent.Add(XmlLigne(ConstXmlDisponibilite, PArmureSimplifiee.Disponibilite));
          XmlContent.Add(XmlLigne(ConstXmlPrix, PArmureSimplifiee.Prix));
          XmlContent.Add(XmlLigne(ConstXmlEncombrement, IntToStr(PArmureSimplifiee.Encombrement)));
          XmlContent.Add(XmlLigne(ConstXmlQualite, PArmureSimplifiee.ListeBonus));
          XmlContent.Add(XmlLigne(ConstXmlProtection, IntToStr(PArmureSimplifiee.Protection)));

          XmlContent.Add(XmlFinCode(ConstXmlArmureSimplifiee));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataArmorSimplified));
  end;

Procedure EcritArmorBonus(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PArmureBonusTalent:  StructureArmureBonusTalent;
    PArmureBonus:        StructureArmureBonus;
    Fist:                Boolean;
  begin
    Fist := true;
    for PArmureBonus in ListArmureBonus do
      if (PArmureBonus.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataArmorBonus));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlBonus, XmlCreeCodeLivre(PArmureBonus.livre, PArmureBonus.CodeArmureBonus)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PArmureBonus.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PArmureBonus.Description));
          if PArmureBonus.Malus <> '' then
            XmlContent.Add(XmlLigne(ConstXmlPositifNegatif, PArmureBonus.Malus));
          if PArmureBonus.NeedsValue <> '' then
            XmlContent.Add(XmlLigne('NeedsValue', PArmureBonus.NeedsValue));
          for PArmureBonusTalent in ListArmureBonusTalent do
            if PArmureBonusTalent.CodeArmureBonus = PArmureBonus.CodeArmureBonus then
              XmlContent.Add(XmlLigne(ConstXmlTalent, PArmureBonusTalent.CodeTalent));
          XmlAjouteModificateurs(XmlContent, SourceModifArmureBonus, PArmureBonus.CodeArmureBonus, Langue);

          XmlContent.Add(XmlFinCode(ConstXmlBonus));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataArmorBonus));
  end;

Procedure EcritSpell(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PTalent:       StructureTalent;
    PSort:         StructureSort;
    Fist:          Boolean;
    StringTalent:  TStringList;
    LigneTalent:   String;
    ListeTalent:   String;
  begin
    Fist := true;
    for PSort in ListSort do
      if (PSort.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSpell));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlSort, XmlCreeCodeLivre(PSort.Livre, PSort.CodeSort)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PSort.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PSort.Description));
          XmlContent.Add(XmlLigne(ConstXmlCible, PSort.Cible));
          XmlContent.Add(XmlLigne(ConstXmlDuree, PSort.Duree));
          XmlContent.Add(XmlLigne(ConstXmlPorteeSort, PSort.Portee));
          StringTalent := TStringList.Create;
          ExtractStrings([','], [], PChar(PSort.ListeTalent), StringTalent);
          ListeTalent := '';
          For LigneTalent in StringTalent do
            begin
              if ListeTalent <> '' then
                ListeTalent := ListeTalent + ',';
              PTalent := ChercheTalent(LigneTalent);
              ListeTalent := ListeTalent + XmlCreeCodeLivre(PTalent.Livre, PTalent.CodeTalent);
            end;
          StringTalent.free;
          XmlContent.Add(XmlLigne(ConstXmlTalent, ListeTalent));
          XmlContent.Add(XmlLigne(ConstXmlNiveau, PSort.Niveau));
          XmlContent.Add(XmlLigne(ConstXmlTypeSort, PSort.TypeSort));
          if PSort.XpFixe <> '' then
            XmlContent.Add(XmlLigne(ConstXmlXpFixe, PSort.XpFixe));

          XmlContent.Add(XmlFinCode(ConstXmlSort));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSpell));
  end;

Procedure EcritSpellTalent(XMLContent: TStringList; Livre: String);
  var
    PSortTalent:  StructureSortTalent;
    Fist:         Boolean;
  begin
    Fist := true;
    for PSortTalent in ListSortTalent do
      if (PSortTalent.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSpellTalent));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlSort, PSortTalent.CodeSort));
          XmlContent.Add(XmlLigne(ConstXmlTalent, PSortTalent.ListeTalent));
          XmlContent.Add(XmlFinCode(ConstXmlSort));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSpellTalent));
  end;

Procedure EcritSpecieTrait(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PTrait:        StructureTrait;
    PTraitOption:  StructureTraitOption;
    Fist:          Boolean;
  begin
    Fist := true;
    for PTrait in ListTrait do
      if (PTrait.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSpecieTrait));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlSpecieTrait, PTrait.CodeTrait));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PTrait.Libelle));
          for PTraitOption in ListTraitOption do
            if CompareRechercheValeur(PTraitOption.CodeTrait, PTrait.CodeTrait) then
              begin
                XmlContent.Add(XmlDebutCode(ConstXmlTraitOption, PTraitOption.CodeOption));
                XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PTraitOption.Libelle));
                XmlContent.Add(XmlLigne(ConstXmlTalent, PTraitOption.ListeTalent));
                XmlContent.Add(XmlFinCode(ConstXmlTraitOption));
              end;
          XmlContent.Add(XmlFinCode(ConstXmlSpecieTrait));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSpecieTrait));
  end;

Procedure EcritCareerBonus(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PCareerBonusSpecialRule:  StructureCareerBonusSpecialRule;
    PCareerBonus:             StructureCareerBonus;
    PCareerBonusNiveau:       StructureCareerBonusNiveau;
    Fist:                     Boolean;
  begin
    Fist := true;
    for PCareerBonus in ListCareerBonus do
      if (PCareerBonus.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataCareerBonus));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlCareerBonus, PCareerBonus.CodeBonus));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PCareerBonus.Libelle));
          XmlContent.Add(XmlLigne(ConstXmlWork, PCareerBonus.CodeMetier));
          XmlContent.Add(XmlLigne(ConstXmlRace, PCareerBonus.CodeRace));
          for PCareerBonusNiveau in ListCareerBonusNiveau do
            if CompareRechercheValeur(PCareerBonusNiveau.CodeBonus, PCareerBonus.CodeBonus) then
              begin
                XmlContent.Add(XmlDebutCode(ConstXmlNiveau, PCareerBonusNiveau.CodeNiveau));
                XmlContent.Add(XmlLigne(ConstXmlOrder, IntToStr(PCareerBonusNiveau.Niveau)));
                XmlContent.Add(XmlLigne(ConstXmlCompetence, PCareerBonusNiveau.ListeCompetence));
                XmlContent.Add(XmlLigne(ConstXmlTalent, PCareerBonusNiveau.ListeTalent));
                XmlAjouteModificateurs(XmlContent, SourceModifCareerBonus, PCareerBonus.CodeBonus, Langue, PCareerBonusNiveau.Niveau);
                if PCareerBonusNiveau.NbChoixCompetence > 0 then
                  XmlContent.Add('<' + ConstXmlSkillChoice + ' ' + ConstXmlSkillChoiceCount + '="' + IntToStr(PCareerBonusNiveau.NbChoixCompetence)
                                 + '" ' + ConstXmlSkillChoiceValue + '="' + IntToStr(PCareerBonusNiveau.ValeurChoixCompetence) + '"/>');
                for PCareerBonusSpecialRule in ListCareerBonusSpecialRule do
                  if (PCareerBonusSpecialRule.CodeBonus = PCareerBonus.CodeBonus) and (PCareerBonusSpecialRule.Niveau = PCareerBonusNiveau.Niveau) then
                    XmlContent.Add(XmlLigneDonnee(ConstXmlSpecialRule, PCareerBonusSpecialRule.Libelle, PCareerBonusSpecialRule.Texte));
                XmlContent.Add(XmlFinCode(ConstXmlNiveau));
              end;
          XmlContent.Add(XmlFinCode(ConstXmlCareerBonus));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataCareerBonus));
  end;

Procedure EcritCondition(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PConditionDonnee:  StructureConditionDonnee;
    Fist:              Boolean;
  begin
    Fist := true;
    if Langue = ConstAnglais then
      for PConditionDonnee in ListConditionDonnee do
        if PConditionDonnee.Livre = Livre then
          begin
            if Fist then
              begin
                XmlContent.Add(XmlDebut(ConstXmlDataCondition));
                Fist := false;
              end;
            XmlContent.Add(XmlDebutCode(ConstXmlCondition, PConditionDonnee.Code));
            XmlContent.Add(XmlLigne(ConstXmlConditionKind, PConditionDonnee.Genre));
            XmlContent.Add(XmlFinCode(ConstXmlCondition));
          end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataCondition));
  end;

Procedure EcritCareerAdaptation(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PCareerAdaptation:       StructureCareerAdaptation;
    PCareerAdaptationLigne:  StructureCareerAdaptationLigne;
    NivAdaptEx:              Integer;
    TrouveNivAdapt:          Boolean;
    Fist:                    Boolean;
  begin
    Fist := true;
    for PCareerAdaptation in ListCareerAdaptation do
      if PCareerAdaptation.Livre = Livre then
        begin
          if Fist then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataCareerAdaptation));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlCareerAdaptation, PCareerAdaptation.CodeAdaptation));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PCareerAdaptation.Libelle));
          XmlContent.Add(XmlLigne(ConstXmlWork, PCareerAdaptation.CodeMetier));
          XmlContent.Add(XmlLigne(ConstXmlRace, PCareerAdaptation.CodeRace));
          if PCareerAdaptation.Facultative then
            XmlContent.Add(XmlLigne(ConstXmlOptional, '1'));
          if PCareerAdaptation.Standing <> 0 then
            XmlContent.Add(XmlLigne(ConstXmlStanding, IntToStr(PCareerAdaptation.Standing)));
          if Langue = ConstAnglais then
            for NivAdaptEx := 0 to 20 do
              begin
                TrouveNivAdapt := false;
                for PCareerAdaptationLigne in ListCareerAdaptationLigne do
                  if (PCareerAdaptationLigne.Livre = Livre) and
                     (PCareerAdaptationLigne.CodeAdaptation = PCareerAdaptation.CodeAdaptation) and
                     (PCareerAdaptationLigne.Niveau = NivAdaptEx) then
                    begin
                      if not TrouveNivAdapt then
                        begin
                          XmlContent.Add(XmlDebut(ConstXmlNiveau + ' ' + ConstXmlId + '="' + IntToStr(NivAdaptEx) + '"'));
                          XmlContent.Add(XmlLigne(ConstXmlOrder, IntToStr(NivAdaptEx)));
                          TrouveNivAdapt := true;
                        end;
                      XmlContent.Add(XmlDebut(PCareerAdaptationLigne.Nature));
                      if PCareerAdaptationLigne.Retire <> '' then
                        XmlContent.Add(XmlLigne(ConstXmlRemove, PCareerAdaptationLigne.Retire));
                      if PCareerAdaptationLigne.Ajoute <> '' then
                        XmlContent.Add(XmlLigne(ConstXmlAdd, PCareerAdaptationLigne.Ajoute));
                      XmlContent.Add(XmlFin(PCareerAdaptationLigne.Nature));
                    end;
                if TrouveNivAdapt then
                  XmlContent.Add(XmlFin(ConstXmlNiveau));
              end;
          XmlContent.Add(XmlFinCode(ConstXmlCareerAdaptation));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataCareerAdaptation));
  end;

Procedure EcritCraftsmanship(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PArmureBonusTalent:  StructureArmureBonusTalent;
    PFabrication:        StructureFabrication;
    Fist:                Boolean;
  begin
    Fist := true;
    for PFabrication in ListFabrication do
      if (PFabrication.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataCraftsmanship));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlFabrication, XmlCreeCodeLivre(PFabrication.Livre, PFabrication.CodeFabrication)));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PFabrication.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PFabrication.Description));
          XmlContent.Add(XmlLigneLangue(ConstXmlShort, Langue, PFabrication.Resume));
          XmlContent.Add(XmlLigne(ConstXmlMax, PFabrication.Maximum));
          if PFabrication.Encombrement <> 0 then
            XmlContent.Add(XmlLigne(ConstXmlEncombrement, IntToStr(PFabrication.Encombrement)));
          if PFabrication.PorteeBonus <> 0 then
            XmlContent.Add(XmlLigne(ConstXmlFabPortee, IntToStr(PFabrication.PorteeBonus)));
          if PFabrication.QualitesArme <> '' then
            XmlContent.Add(XmlLigne(ConstXmlFabQualiteArme, PFabrication.QualitesArme));
          if PFabrication.ArmeAlternative <> '' then
            XmlContent.Add(XmlLigne(ConstXmlFabArmeAlternative, PFabrication.ArmeAlternative));
          if PFabrication.Applique <> '' then
            XmlContent.Add(XmlLigne(ConstXmlFabApplique, PFabrication.Applique));
          XmlContent.Add(XmlLigne(ConstXmlPositifNegatif, PFabrication.TypeQualite));
          // Talent accorde : lu dans ListArmureBonusTalent (la meme entree alimente aussi
          // ListArmeBonusTalent, donc une seule des deux listes suffit a l'ecrire)
          for PArmureBonusTalent in ListArmureBonusTalent do
            if (PArmureBonusTalent.Livre = Livre) and (PArmureBonusTalent.CodeArmureBonus = PFabrication.CodeFabrication) then
              XmlContent.Add(XmlLigne(ConstXmlTalent, PArmureBonusTalent.CodeTalent));
          XmlAjouteModificateurs(XmlContent, SourceModifFabrication, PFabrication.CodeFabrication, Langue);

          XmlContent.Add(XmlFinCode(ConstXmlFabrication));
        end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataCraftsmanship));
  end;

Procedure EcritSigneAstral(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PSigneAstral:     StructureSigneAstral;
    PSigneEffet:      StructureSigneEffet;
    Fist:             Boolean;
    VarianteEnCours:  String;
  begin
    if Langue = ConstAnglais then
      begin
        Fist := true;
        for PSigneAstral in ListSigneAstralSource do
          if (PSigneAstral.Livre = Livre) then
            begin
              if Fist = true then
                begin
                  XmlContent.Add(XmlDebut(ConstXmlDataSigneAstral));
                  Fist := false;
                end;
              XmlContent.Add(XmlDebutCode(ConstXmlSigneAstral, XmlCreeCodeLivre(PSigneAstral.Livre, PSigneAstral.CodeSigne)));
              XmlContent.Add(XmlLigne(ConstXmlSignePlage, PSigneAstral.Plage));
              XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PSigneAstral.Libelle));
              XmlContent.Add(XmlLigneLangue(ConstXmlSigneTitre, Langue, PSigneAstral.Titre));
              XmlContent.Add(XmlLigne(ConstXmlSigneClassique, PSigneAstral.NomClassique));
              XmlContent.Add(XmlLigne(ConstXmlSigneAscendant, PSigneAstral.Ascendant));
              XmlContent.Add(XmlLigne(ConstXmlSigneDates, PSigneAstral.Dates));
              XmlContent.Add(XmlLigne(ConstXmlSigneDieu, PSigneAstral.Dieu));
              XmlContent.Add(XmlLigneLangue(ConstXmlSigneApparence, Langue, PSigneAstral.Apparence));
              XmlContent.Add(XmlLigneLangue(ConstXmlSignePersonnalite, Langue, PSigneAstral.Personnalite));
              VarianteEnCours := '';
              for PSigneEffet in ListSigneEffet do
                if (PSigneEffet.CodeSigne = PSigneAstral.CodeSigne) and (PSigneEffet.Livre = PSigneAstral.Livre) then
                  begin
                    if PSigneEffet.Variante <> VarianteEnCours then
                      begin
                        if VarianteEnCours <> '' then
                          XmlContent.Add(XmlFin(ConstXmlSigneVariante));
                        VarianteEnCours := PSigneEffet.Variante;
                        if VarianteEnCours <> '' then
                          XmlContent.Add(XmlDebut(ConstXmlSigneVariante + ' range="' + VarianteEnCours + '"'));
                      end;
                    if PSigneEffet.CodeAttribut <> '' then
                      XmlContent.Add(XmlLigneDonnee(ConstXmlSigneModificateur, PSigneEffet.CodeAttribut, IntToStr(PSigneEffet.Valeur)))
                    else
                      XmlContent.Add(XmlLigne(ConstXmlTalent, PSigneEffet.CodeTalent));
                  end;
              if VarianteEnCours <> '' then
                XmlContent.Add(XmlFin(ConstXmlSigneVariante));
              XmlContent.Add(XmlFinCode(ConstXmlSigneAstral));
            end;
        if Fist = false then
          XmlContent.Add(XmlFin(ConstXmlDataSigneAstral));
      end;
  end;

Procedure EcritCareerSpecie(XMLContent: TStringList; Livre: String);
  var
    PRace:              StructureRace;
    PRaceMetierSource:  StructureRaceMetierSource;
    PMetier:            StructureMetier;
    Fist:               Boolean;
  begin
    Fist := true;
    for PRaceMetierSource in ListRaceMetierSource do
      if (PRaceMetierSource.Forme = FormeRaceMetierData) and (PRaceMetierSource.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataCareerSpecie));
              Fist := false;
            end;
          XmlContent.Add(XmlDebut(ConstXmlEntry));
          PRace := chercheRace(PRaceMetierSource.CodeRace);
          XmlContent.Add(XmlLigne(ConstXmlRace, XmlCreeCodeLivre(PRace.Livre, PRaceMetierSource.CodeRace)));
          PMetier := ChercheMetier(PRaceMetierSource.CodeMetier);
          XmlContent.Add(XmlLigneDonnee(ConstXmlWork, XmlCreeCodeLivre(PMetier.Livre, PRaceMetierSource.CodeMetier), PRaceMetierSource.Chance));
          XmlContent.Add(XmlFin(ConstXmlEntry));
        end;
    if Fist = false then
      XmlContent.Add(XmlFin(ConstXmlDataCareerSpecie));
  end;

Procedure EcritClassItem(XMLContent: TStringList; Livre: String);
  var
    PClassEquipement:  StructureClassEquipement;
    ClasseCourante:    String;
    ItemsOuverts:      Boolean;
    Fist:              Boolean;
    QuantiteAttr:      String;
  begin
    Fist           := true;
    ClasseCourante := '';
    ItemsOuverts   := false;
    for PClassEquipement in ListClassEquipement do
      if PClassEquipement.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataClassItem));
              Fist := false;
            end;
          if PClassEquipement.CodeClasse <> ClasseCourante then
            begin
              if ClasseCourante <> '' then
                begin
                  if ItemsOuverts then XmlContent.Add(XmlFin(ConstXmlSousChapitreEquipement));
                  XmlContent.Add(XmlFin(ConstXmlClass));
                end;
              ClasseCourante := PClassEquipement.CodeClasse;
              XmlContent.Add(XmlReplace('<'+ConstXmlClass+' name="'+ClasseCourante+'">'));
              ItemsOuverts := false;
            end;
          if PClassEquipement.Action <> '' then
            begin
              // Les actions suivent les ajouts : on referme SUBCHAPTER_ITEM avant la premiere.
              if ItemsOuverts then
                begin
                  XmlContent.Add(XmlFin(ConstXmlSousChapitreEquipement));
                  ItemsOuverts := false;
                end;
              if PClassEquipement.Action = 'REMOVE' then
                XmlContent.Add(XmlLigne(ConstXmlRemove, PClassEquipement.Cible))
              else
                begin
                  QuantiteAttr := ' '+ConstXmlFrom+'="'+PClassEquipement.Cible+'"';
                  if PClassEquipement.QuantiteListe <> '' then
                    QuantiteAttr := QuantiteAttr+' '+ConstXmlEquipementQuantite+'="'+PClassEquipement.QuantiteListe+'"'
                  else if PClassEquipement.Quantite > 0 then
                    QuantiteAttr := QuantiteAttr+' '+ConstXmlEquipementQuantite+'="'+IntToStr(PClassEquipement.Quantite)+'"';
                  XmlContent.Add(XmlReplace(XmlDebut(ConstXmlReplace+QuantiteAttr) + '"' + PClassEquipement.Equipement + '"' + XmlFin(ConstXmlReplace)));
                end;
              Continue;
            end;
          if not ItemsOuverts then
            begin
              XmlContent.Add(XmlDebut(ConstXmlSousChapitreEquipement));
              ItemsOuverts := true;
            end;
          if PClassEquipement.QuantiteListe <> '' then
            QuantiteAttr := ' '+ConstXmlEquipementQuantite+'="'+PClassEquipement.QuantiteListe+'"'
          else if PClassEquipement.Quantite <> 1 then
            QuantiteAttr := ' '+ConstXmlEquipementQuantite+'="'+IntToStr(PClassEquipement.Quantite)+'"'
          else
            QuantiteAttr := '';
          XmlContent.Add(XmlLigneDonnee(ConstXmlEquipement, PClassEquipement.Equipement, '1', QuantiteAttr));
        end;
    if Fist = false then
      begin
        if ItemsOuverts then XmlContent.Add(XmlFin(ConstXmlSousChapitreEquipement));
        XmlContent.Add(XmlFin(ConstXmlClass));
        XmlContent.Add(XmlFin(ConstXmlDataClassItem));
      end;
  end;

Procedure EcritDisease(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PDisease:  StructureDisease;
    Fist:      Boolean;
  begin
    Fist := true;
    for PDisease in ListDisease do
      if PDisease.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataDisease));
              Fist := false;
            end;
          XmlContent.Add(XmlReplace('<Disease name="'+PDisease.Code+'">'));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PDisease.Libelle));
          if PDisease.Contraction <> '' then
            XmlContent.Add(XmlLigneLangue(ConstXmlContraction, Langue, PDisease.Contraction));
          if PDisease.Incubation <> '' then
            XmlContent.Add(XmlLigneLangue(ConstXmlIncubation, Langue, PDisease.Incubation));
          if PDisease.Duration <> '' then
            XmlContent.Add(XmlLigneLangue(ConstXmlDuration, Langue, PDisease.Duration));
          if PDisease.Symptoms <> '' then
            XmlContent.Add(XmlLigneLangue(ConstXmlSymptoms, Langue, PDisease.Symptoms));
          XmlAjouteModificateurs(XmlContent, SourceModifMaladie, PDisease.Code, Langue);
          XmlContent.Add(XmlFin('Disease'));
        end;
    if Fist = false then
      XmlContent.Add(XmlFin(ConstXmlDataDisease));
  end;

Procedure EcritAffliction(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PAffliction:  StructureAffliction;
    Fist:         Boolean;
  begin
    Fist := true;
    for PAffliction in ListAffliction do
      if PAffliction.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataAffliction));
              Fist := false;
            end;
          XmlContent.Add(XmlReplace('<Affliction name="'+PAffliction.Code+'">'));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PAffliction.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, PAffliction.Effet));
          XmlAjouteModificateurs(XmlContent, SourceModifAffliction, PAffliction.Code, Langue);
          XmlContent.Add(XmlFin('Affliction'));
        end;
    if Fist = false then
      XmlContent.Add(XmlFin(ConstXmlDataAffliction));
  end;

Procedure EcritOptionRule(XMLContent: TStringList; Livre: String; Langue: String);
  var
    POptionRegle:  StructureOptionRegle;
    Fist:          Boolean;
  begin
    Fist := true;
    for POptionRegle in ListOptionRegle do
      if POptionRegle.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataOptionRule));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlOptionRule, POptionRegle.CodeId));
          XmlContent.Add(XmlLigne(ConstXmlCode, POptionRegle.CodeOption));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, POptionRegle.Libelle));
          XmlContent.Add(XmlLigneLangue(ConstXmlExplanation, Langue, POptionRegle.Explication));
          XmlContent.Add(XmlFinCode(ConstXmlOptionRule));
        end;
    if Fist = false then
      XmlContent.Add(XmlFin(ConstXmlDataOptionRule));
  end;

Procedure EcritRegle(XMLContent: TStringList; Livre: String; Langue: String);
  var
    PRegleExport:  StructureRegle;
    Fist:          Boolean;
  begin
    Fist := true;
    for PRegleExport in ListRegleSource do
      if PRegleExport.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataRegle));
              Fist := false;
            end;
          XmlContent.Add(XmlDebutCode(ConstXmlRegleJeu, PRegleExport.CodeRegle));
          XmlContent.Add(XmlLigneLangue(ConstXmlDescription, Langue, PRegleExport.Libelle));
          if PRegleExport.ClasseRemplacee <> '' then
            XmlContent.Add(XmlLigne(ConstXmlClass, PRegleExport.ClasseRemplacee));
          XmlContent.Add(XmlFinCode(ConstXmlRegleJeu));
        end;
    if Fist = false then
      XmlContent.Add(XmlFin(ConstXmlDataRegle));
  end;

Procedure EcritRegleMetier(XMLContent: TStringList; Livre: String);
  var
    PRegleMetier:  StructureRegleMetier;
    Fist:          Boolean;
  begin
    Fist := true;
    for PRegleMetier in ListRegleMetier do
      if PRegleMetier.Livre = Livre then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataRegleMetier));
              Fist := false;
            end;
          XmlContent.Add(XmlDebut(ConstXmlEntry));
          XmlContent.Add(XmlLigne(ConstXmlRegleJeu, PRegleMetier.CodeRegle));
          XmlContent.Add(XmlLigne(ConstXmlRace, PRegleMetier.CodeRace));
          XmlContent.Add(XmlLigneDonnee(ConstXmlWork, PRegleMetier.CodeMetier, PRegleMetier.Chance));
          XmlContent.Add(XmlFin(ConstXmlEntry));
        end;
    if Fist = false then
      XmlContent.Add(XmlFin(ConstXmlDataRegleMetier));
  end;

Procedure EcritSpecieCareerChoix(XMLContent: TStringList; Livre: String);
  var
    PRace:                   StructureRace;
    PMetier:                 StructureMetier;
    PMetierRaceChoixMetier:  StructureMetierRaceChoixMetier;
    Fist:                    Boolean;
  begin
    Fist := true;
    for PMetierRaceChoixMetier in ListMetierRaceChoixMetier do
      if (PMetierRaceChoixMetier.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataSpecieCareerChoix));
              Fist := false;
            end;
          XmlContent.Add(XmlDebut(ConstXmlChoix));
          PRace := chercheRace(PMetierRaceChoixMetier.CodeRace);
          XmlContent.Add(XmlLigne(ConstXmlRace, XmlCreeCodeLivre(PRace.Livre, PMetierRaceChoixMetier.CodeRace)));
          PMetier := chercheMetier(PMetierRaceChoixMetier.CodeMetier);
          XmlContent.Add(XmlLigne(ConstXmlWork, XmlCreeCodeLivre(PMetier.Livre, PMetierRaceChoixMetier.CodeMetier)));
          PMetier := chercheMetier(PMetierRaceChoixMetier.CodeSousMetier);
          XmlContent.Add(XmlLigne(ConstXmlAlternative, XmlCreeCodeLivre(PMetier.Livre, PMetierRaceChoixMetier.CodeSousMetier)));
          XmlContent.Add(XmlFin(ConstXmlChoix));
       end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataSpecieCareerChoix));
  end;

Procedure EcritCareerSubChoice(XMLContent: TStringList; Livre: String);
  var
    PMetier:            StructureMetier;
    PMetierSousMetier:  StructureMetierSousMetier;
    Fist:               Boolean;
  begin
    Fist := true;
    for PMetierSousMetier in ListMetierSousMetier do
      if (PMetierSousMetier.Livre = Livre) then
        begin
          if Fist = true then
            begin
              XmlContent.Add(XmlDebut(ConstXmlDataCareerSubChoice));
              Fist := false;
            end;
          XmlContent.Add(XmlDebut(ConstXmlChoix));
          PMetier := ChercheMetier(PMetierSousMetier.CodeMetier);
          XmlContent.Add(XmlLigne(ConstXmlWork, XmlCreeCodeLivre(PMetier.Livre, PMetierSousMetier.CodeMetier)));
          PMetier := ChercheMetier(PMetierSousMetier.CodeSousMetier);
          XmlContent.Add(XmlLigneDonnee(ConstXmlAlternative, XmlCreeCodeLivre(PMetier.Livre, PMetierSousMetier.CodeSousMetier), PMetierSousMetier.Chance));
          XmlContent.Add(XmlFin(ConstXmlChoix));
       end;
    if Fist = false then
       XmlContent.Add(XmlFin(ConstXmlDataCareerSubChoice));
  end;

Procedure XmlExportBook(Livre: String; Langue: String);
  var
    XMLContent:               TStringList;
    FileName:                 String;
    PLivre:                   StructureLivre;

  begin
    if Langue = ConstAnglais then
      FileName   := GetCurrentDir+ConstCheminLivreExport+Livre+'.Xml'
    else
      FileName   := GetCurrentDir+ConstCheminLivreExport+Livre+'_'+Langue+'.Xml';
    XMLContent := TStringList.Create;
    try
      try
        // Construire le contenu XML
        XMLContent.Add(XmlDataBase());

        XMLContent.Add(XmlDebut(ConstXmlDataBook));

        XmlContent.Add(XmlLigne(ConstXmlCodeLivre, XmlCodeLivre(Livre)));
        XmlContent.Add(XmlLigne(ConstXmlLibelleLivre, Livre));
        XmlContent.Add(XmlLigne(ConstXmlLanguage, Langue));

        // Livres
        PLivre.Version := '';
        PLivre := ChercheLivreLibelle(Livre);
        if PLivre.Version <> '' then
          XmlContent.Add(XmlLigne(ConstXmlVersionLivre, PLivre.Version))
        else
          XmlContent.Add(XmlLigne(ConstXmlVersionLivre, FormatDateTime('YYYYMMDD',Now)));
        // valeurs lues au chargement quand le livre est connu ; sinon regle d origine
        if PLivre.Version = '' then
          begin
            PLivre.Officiel := StrToInt(LivreOrdre(PLivre.Libelle));
            PLivre.Complet  := 1;
          end;
        XmlContent.Add(XmlLigne(ConstXmlOfficielLivre, IntToStr(PLivre.Officiel)));
        XmlContent.Add(XmlLigne(ConstXmlCompletLivre, IntToStr(PLivre.Complet)));
        if PLivre.Disclaimer <> '' then
          XmlContent.Add(XmlLigne(ConstXmlDisclaimerLivre, PLivre.Disclaimer));

        // Attribut
        EcritAttribut(XMLContent, Livre, Langue);

        // Attribut Augmentation
        EcritAttributCost(XMLContent, Livre);

        // Competence Augmentation
        EcritSkillCost(XMLContent, Livre);

        // Texte
        EcritLabel(XMLContent, Livre, Langue);

        // compétence
        EcritSkill(XMLContent, Livre, Langue);

        // compétence spécialisation
        EcritSkillSpe(XMLContent, Livre, Langue);

        // Talent
        EcritTalent(XMLContent, Livre, Langue);

        // Corruption : liens espece/chance (DATA_CORRUPTION_PHYSICAL/MENTAL), catalogue des mutations
        // (DATA_CORRUPTION_TABLE_*) et tirage D100 (DATA_CORRUPTION_*_CHANCE), meme forme que le chargement.
        EcritCorruption(XMLContent, Livre, Langue);

        // Talent spécialisation
        EcritTalentSpe(XMLContent, Livre, Langue);

        // Talent au hasard
        EcritRandomTalent(XMLContent, Livre);

        // Espece (bloc DATA_RACE : la RACE generique qui regroupe les ethnies -
        // voir ChargeEspece.pas pour le vocabulaire. Etait lue et jamais ecrite.)
        EcritEspece(XMLContent, Livre, Langue);

        // Nation (bloc DATA_NATION : regroupement POLITIQUE des ethnies, distinct de
        // DATA_RACE qui est biologique - voir ChargeNation.pas. CONTEXT.md 2.51.)
        EcritNation(XMLContent, Livre, Langue);

        // race
        EcritSpecie(XMLContent, Livre, Langue);

        // Race au hasard
        EcritSpecieCreation(XMLContent, Livre);

        // Métier
        EcritCareer(XMLContent, Livre, Langue);

        // Arme
        EcritWeapon(XMLContent, Livre, Langue);

        // ArmeBonus
        EcritWeaponBonus(XMLContent, Livre, Langue);

        // Armure
        EcritArmor(XMLContent, Livre, Langue);

        // Trapping (equipement divers, hors armes/armures)
        EcritTrapping(XMLContent, Livre, Langue);

        // Armure Simplifiée
        EcritArmorSimplified(XMLContent, Livre, Langue);

        // ArmureBonus
        EcritArmorBonus(XMLContent, Livre, Langue);

        // Sort
        EcritSpell(XMLContent, Livre, Langue);

        // Acces aux sorts par talent - voir CONTEXT.md 2.39.
        // Le sort cite ici peut appartenir a un AUTRE livre que celui qu'on exporte :
        // c'est PSortTalent.Livre, et non le livre du sort, qui decide ou la ligne part.
        // On n'appelle donc PAS ChercheSort pour reconstruire son prefixe - le code est
        // deja complet, tel qu'il a ete lu.
        EcritSpellTalent(XMLContent, Livre);

        // Traits d'ethnie - voir CONTEXT.md 2.41. Bloc ECRIT des maintenant, meme si
        // aucun ecran ne le saisit : l'export reconstruit le fichier depuis les listes
        // en memoire, donc un bloc lu mais non ecrit disparait a la premiere sauvegarde
        // depuis WinLivre (lecon du 03/09/2026, CONTEXT.md 2.39).
        EcritSpecieTrait(XMLContent, Livre, Langue);

        // Appartenances greffees sur une carriere - voir CONTEXT.md 2.44. Bloc ECRIT
        // des maintenant, meme si aucun ecran ne le saisit : l'export reconstruit le
        // fichier depuis les listes en memoire, donc un bloc lu mais non ecrit
        // disparait a la premiere sauvegarde depuis WinLivre (lecon du 03/09/2026,
        // CONTEXT.md 2.39), et un bloc lu mais jamais exporte est exactement le bug
        // DATA_RACE du 04/09 (CONTEXT.md 2.42).
        // Le metier et l'ethnie cites appartiennent le plus souvent a un AUTRE livre
        // (Soldier et les Reiklander viennent du Rulebook) : c'est PCareerBonus.Livre,
        // et non le livre du metier, qui decide ou la ligne part. Les codes sont deja
        // complets, on ne reconstruit donc aucun prefixe.
        EcritCareerBonus(XMLContent, Livre, Langue);

        // Conditions declarees
        EcritCondition(XMLContent, Livre, Langue);

        // Adaptations de carriere : une substitution par palier et par nature (Skill/Talent/Trapping)
        EcritCareerAdaptation(XMLContent, Livre, Langue);

        // Fabrication
        EcritCraftsmanship(XMLContent, Livre, Langue);

        // Signes astraux (Archives of the Empire II) : ecrits seulement dans le fichier anglais
        EcritSigneAstral(XMLContent, Livre, Langue);

        // Liens espece/carriere declares dans DATA_CAREER_SPECIE (liste des declarations, pas
        // ListRaceMetier : celle-ci est developpee par ethnie apres le chargement)
        EcritCareerSpecie(XMLContent, Livre);

        // Equipement de depart par classe (DATA_CLASS_ITEM). Les entrees d'une classe se suivent
        // dans la liste (ordre du chargement) ; le texte de <Item> vaut "1" dans tous les livres.
        EcritClassItem(XMLContent, Livre);

        // Maladies (DATA_DISEASE) : la balise porte name=, comme au chargement
        EcritDisease(XMLContent, Livre, Langue);

        // Afflictions (DATA_AFFLICTION) : name=, modificateurs par le tableau unique
        EcritAffliction(XMLContent, Livre, Langue);

        // Regles optionnelles (DATA_OPTION_RULE)
        EcritOptionRule(XMLContent, Livre, Langue);

        // Regles de jeu apportees par le livre (DATA_RULE)
        EcritRegle(XMLContent, Livre, Langue);

        // Table de tirage des metiers propre a une regle (DATA_CAREER_ROLL)
        EcritRegleMetier(XMLContent, Livre);

        // Metier choix race
        EcritSpecieCareerChoix(XMLContent, Livre);

        // Sous Metier
        EcritCareerSubChoice(XMLContent, Livre);

        // fin de livre
        XMLContent.Add(XmlFin(ConstXmlDataBook));

        // Enregistrer le contenu XML dans un fichier (dossier d'export cree s'il manque)
        ForceDirectories(ExtractFilePath(fileName));
        XmlInserePages(XMLContent);
        XMLContent.SaveToFile(fileName);

      except
        on E: Exception do
          XmlSignale('Erreur lors de la creation du fichier XML ' + FileName + ' : ' + E.Message);
      end;
    finally
      XMLContent.Free;
    end;
  end;

// Lit un effet de signe astral : <Modifier name="RULES-ATTR_WP">"-3"</Modifier> ou <Talent>"CODE"</Talent>.
// Variante = plage du sous-tirage (Witchling Star), vide sinon.
Procedure AjouteEffetSigneAstral(Livre, CodeSigne, Variante: String; Node: TDOMNode);
  var
    PEffet: StructureSigneEffet;
  begin
    PEffet           := Default(StructureSigneEffet);
    PEffet.Livre     := Livre;
    PEffet.CodeSigne := CodeSigne;
    PEffet.Variante  := Variante;
    if Node.NodeName = ConstXmlSigneModificateur then
      begin
        PEffet.CodeAttribut := XmlAttribut(Node, ConstXmlData);
        PEffet.Valeur       := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)), 0);
      end
    else
      PEffet.CodeTalent     := RemoveQuotes(UTF8Encode(Node.TextContent));
    ListSigneEffet.Add(PEffet);
    Inc(NbSigneEffet);
  end;

// Lit les qualites <BonusMalus> d un noeud DATA_WEAPON_BONUS (livre ou qualites propres d un personnage).
Procedure LitArmesBonusNoeud(NodeNv1: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    PArmeBonus:               StructureArmeBonus;
    PFabricationModificateur: StructureModificateur;
    PTraduction:              StructureTraduction;
    NodeNv2:                  TDOMNode;
    Node:                     TDOMNode;
  begin
    NodeNv2 := XmlElement(NodeNv1.FirstChild);
    While Assigned(NodeNv2) do
      begin
        PArmeBonus.Livre         := Livre;
        PArmeBonus.PlusMoins     := '';
        PArmeBonus.NeedsValue    := '';
        PArmeBonus.CodeArmeBonus := XmlAttribut(NodeNv2, ConstXmlId);
        PTraduction              := InitTrad(ConstPArmeBonus, PArmeBonus.CodeArmeBonus, '', PArmeBonus.livre);

        Node := XmlElement(NodeNv2.FirstChild);
        while Assigned(Node) do
          begin
            // Modificateurs numeriques : lecteur commun, tous formats (e2a).
            if LitModificateurNoeud(Node, PArmeBonus.CodeArmeBonus, PFabricationModificateur) then
              begin
                if LangueDef = ConstAnglais then
                  begin
                    AjouteModificateurUnique(SourceModifQualiteArme, PFabricationModificateur);
                    inc(NbFabricationModificateur);
                  end;
              end
            else
            case Node.NodeName of
              ConstXmlExplanation:
                begin
                  PArmeBonus.Description     := RemoveQuotes(UTF8Encode(Node.TextContent));
                  Langue                     := XmlAttribut(Node, ConstXmlLanguage);
                  PTraduction.Description    := PArmeBonus.Description;
                end;
              ConstXmlDescription:
                begin
                  PArmeBonus.Libelle         := RemoveQuotes(UTF8Encode(Node.TextContent));
                  Langue                     := XmlAttribut(Node, ConstXmlLanguage);
                  PTraduction.Libelle        := PArmeBonus.Libelle;
                end;
              ConstXmlPositifNegatif:
                PArmeBonus.PlusMoins         := RemoveQuotes(UTF8Encode(Node.TextContent));
              'NeedsValue':
                PArmeBonus.NeedsValue        := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlShort:
                begin
                  PArmeBonus.Resume          := RemoveQuotes(UTF8Encode(Node.TextContent));
                  Langue                     := XmlAttribut(Node, ConstXmlLanguage);
                  PTraduction.Resume         := PArmeBonus.Resume;
                end;
            end;

            Node := XmlElement(Node.NextSibling);
          end;
        if LangueDef = ConstAnglais then
          begin
            ListArmeBonus.add(PArmeBonus);
            inc(NbArmeBonus);
          end;

        AddTrad(PTraduction, Langue);

        NodeNv2 := XmlElement(NodeNv2.NextSibling);
      end;
  end;

// Lit les qualites <BonusMalus> d un noeud DATA_ARMOR_BONUS (livre ou qualites propres d un personnage).
Procedure LitArmuresBonusNoeud(NodeNv1: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    PArmureBonus:             StructureArmureBonus;
    PArmureBonusModificateur: StructureModificateur;
    PArmureBonusTalent:       StructureArmureBonusTalent;
    PTraduction:              StructureTraduction;
    NodeNv2:                  TDOMNode;
    Node:                     TDOMNode;
  begin
    NodeNv2 := XmlElement(NodeNv1.FirstChild);
    While Assigned(NodeNv2) do
      begin
        PArmureBonus.Livre           := Livre;
        PArmureBonus.CodeArmureBonus := XmlAttribut(NodeNv2, ConstXmlId);
        // remis à vide à chaque entrée (corrige le 15/08/2026) : PArmureBonus est
        // réutilisée d'un tour de boucle à l'autre, et depuis l'ajout du Modifier
        // structuré (name="..."), .Malus n'est plus toujours réécrit par le
        // <Modifier> - sans ce reset, une entrée structurée garde le Malus de
        // l'entrée précédente lue dans le même livre.
        PArmureBonus.Malus            := '';
        PArmureBonus.NeedsValue       := '';
        PTraduction                  := InitTrad(ConstPArmureBonus, PArmureBonus.CodeArmureBonus, '', PArmureBonus.Livre);

        Node := XmlElement(NodeNv2.FirstChild);
        while Assigned(Node) do
          begin
            // Modificateurs numeriques : lecteur commun, tous formats (e2a).
            if LitModificateurNoeud(Node, PArmureBonus.CodeArmureBonus, PArmureBonusModificateur) then
              begin
                if LangueDef = ConstAnglais then
                  begin
                    AjouteModificateurUnique(SourceModifArmureBonus, PArmureBonusModificateur);
                    inc(NbArmureBonusModificateur);
                  end;
              end
            else
            case Node.NodeName of
              ConstXmlExplanation:
                begin
                  PArmureBonus.Description   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  Langue                     := XmlAttribut(Node, ConstXmlLanguage);
                  PTraduction.Description    := PArmureBonus.Description;
                end;
              ConstXmlDescription:
                begin
                  PArmureBonus.Libelle       := RemoveQuotes(UTF8Encode(Node.TextContent));
                  Langue                     := XmlAttribut(Node, ConstXmlLanguage);
                  PTraduction.Libelle        := PArmureBonus.Libelle;
                end;
              ConstXmlPositifNegatif:
                begin
                  if Assigned(Node.Attributes) and Assigned(Node.Attributes.GetNamedItem(ConstXmlData)) then
                    begin
                      // Modifier structuré, lié à une compétence : <Modifier name="CodeCompetence">Valeur</Modifier>
                      // (même convention que <ModifySkill name="..."> pour les talents, voir ConstXmlModifieCompetence)
                      // Range dans la liste unique sous le type ModifySkillGear (colonne
                      // "avec equipement" du PDF, pas le Total) - 04/10/2026.
                      PArmureBonusModificateur.TypeModif  := ConstXmlModifieCompetenceEquip;
                      PArmureBonusModificateur.Cible      := XmlAttribut(Node, ConstXmlData);
                      PArmureBonusModificateur.Filtre     := '';
                      PArmureBonusModificateur.Forme      := ConstFormeEffetAdditif;
                      PArmureBonusModificateur.Facteur    := StrToInt(RemoveQuotes(UTF8Encode(Node.TextContent)));
                      PArmureBonusModificateur.CodeSource := PArmureBonus.CodeArmureBonus;
                      PArmureBonusModificateur.Niveau     := 0;
                      PArmureBonusModificateur.Aleatoire  := False;
                      PArmureBonusModificateur.TypeSource := '';
                      if LangueDef = ConstAnglais then
                         begin
                          AjouteModificateurUnique(SourceModifArmureBonus, PArmureBonusModificateur);
                          inc(NbArmureBonusModificateur);
                         end;
                    end
                  else
                    // Modifier texte libre, sans compétence liée (note mécanique type "combinable with Plate") : comportement inchangé
                    PArmureBonus.Malus := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;
              'NeedsValue':
                PArmureBonus.NeedsValue := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlTalent:
                begin
                  // Talent accorde par une qualite d'objet (ex. NATIO-ARMOB_16 "Fear"
                  // -> RULES-T0049 "Frightening", Skull Trophies), cas par cas dans le
                  // XML - meme chantier "traits de creature" que ConstXmlTalent sous
                  // <Corruption> plus haut.
                  PArmureBonusTalent.Livre           := Livre;
                  PArmureBonusTalent.CodeArmureBonus := PArmureBonus.CodeArmureBonus;
                  PArmureBonusTalent.CodeTalent      := RemoveQuotes(UTF8Encode(Node.TextContent));
                  if LangueDef = ConstAnglais then
                     begin
                      ListArmureBonusTalent.add(PArmureBonusTalent);
                      inc(NbArmureBonusTalent);
                     end;
                end;
            end;

            Node := XmlElement(Node.NextSibling);
          end;
        if LangueDef = ConstAnglais then
          begin
            ListArmureBonus.add(PArmureBonus);
            inc(NbArmureBonus);
          end;

        AddTrad(PTraduction, Langue);

        NodeNv2 := XmlElement(NodeNv2.NextSibling);
      end;
  end;

// Lit les <Weapon> d un noeud DATA_WEAPON (livre ou objets propres d un personnage).
Procedure LitArmesNoeud(NodeNv1: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    PArme:                    StructureArme;
    PArmeModificateur:        StructureModificateur;
    PTraduction:              StructureTraduction;
    NodeNv2:                  TDOMNode;
    Node:                     TDOMNode;
  begin
    NodeNv2 := XmlElement(NodeNv1.FirstChild);
    While Assigned(NodeNv2) do
      begin
        PArme.Livre    := Livre;
        // Remis a vide a chaque entree : <BuiltInCraftsmanship> n'existe que sur
        // de rares armes (Jade Longsword...), PArme etant reutilise d'un tour de
        // boucle a l'autre sans cela la valeur de l'entree precedente resterait
        // collee - meme piege que PTrapping.Capacite (CONTEXT.md 2.17).
        PArme.Fabrication := '';
        // Tous les champs facultatifs aussi : sans cela une arme sans <Type> ou sans
        // <Price> gardait celui de l'arme precedente (Gantelets avec le Type d'une
        // lance, constate au controle d'aller-retour de l'export, 05/10/2026).
        PArme.CodeCompetence := '';
        PArme.Libelle        := '';
        PArme.Mains          := 0;
        PArme.Prix           := '';
        PArme.Encombrement   := 0;
        PArme.Disponibilite  := '';
        PArme.Portee         := '';
        PArme.CalculDegat    := '';
        PArme.ListeBonus     := '';
        PArme.Munition       := 0;
        PArme.TypeArme       := '';
        PArme.CodeArme := XmlAttribut(NodeNv2, ConstXmlId);
        PTraduction    := InitTrad(ConstPArme, PArme.CodeArme, '', PArme.Livre);

        Node := XmlElement(NodeNv2.FirstChild);
        while Assigned(Node) do
          begin
            // Modificateurs numeriques : lecteur commun, tous formats (e2a).
            if LitModificateurNoeud(Node, PArme.CodeArme, PArmeModificateur) then
              begin
                if LangueDef = ConstAnglais then
                  begin
                    AjouteModificateurUnique(SourceModifArme, PArmeModificateur);
                    inc(NbArmeModificateur);
                  end;
              end
            else
            case Node.NodeName of
              ConstXmlCompetence:
                PArme.CodeCompetence  := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlDescription:
                begin
                  PArme.Libelle       := RemoveQuotes(UTF8Encode(Node.TextContent));
                  Langue              := XmlAttribut(Node, ConstXmlLanguage);
                  PTraduction.Libelle := PArme.Libelle;
                end;
              ConstXmlDisponibilite:
                PArme.Disponibilite   := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlDamage:
                PArme.CalculDegat     := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlEncombrement:
                PArme.Encombrement    := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
              ConstXmlQualite:
                PArme.ListeBonus      := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlMains:
                PArme.Mains           := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
              ConstXmlMunition:
                PArme.Munition        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
              ConstXmlPorteeArme:
                PArme.Portee          := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlPrix:
                PArme.Prix            := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlType:
                PArme.TypeArme        := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlFabIntegree:
                PArme.Fabrication     := RemoveQuotes(UTF8Encode(Node.TextContent));
            end;

            Node := XmlElement(Node.NextSibling);
          end;
        if LangueDef = ConstAnglais then
          begin
            ListArme.add(PArme);
            inc(NbArme);
            Inc(LivreNbArme);
            inc(NbArmeUnique);
          end;

        AddTrad(PTraduction, Langue);

        NodeNv2 := XmlElement(NodeNv2.NextSibling);
      end;
  end;

// Lit les <Armor> d un noeud DATA_ARMOR (livre ou objets propres d un personnage).
Procedure LitArmuresNoeud(NodeNv1: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    PArmure:                  StructureArmure;
    PTraduction:              StructureTraduction;
    NodeNv2:                  TDOMNode;
    Node:                     TDOMNode;
  begin
    NodeNv2 := XmlElement(NodeNv1.FirstChild);
    While Assigned(NodeNv2) do
      begin
        PArmure.Livre      := Livre;
        // Remis a vide a chaque entree, meme raison que PArme.Fabrication ci-dessus.
        PArmure.Fabrication := '';
        // facultatifs, remis a vide a chaque entree (comme PArme et PTrapping) : sans
        // cela une armure sans <Price> gardait celui de la precedente
        PArmure.Disponibilite := '';
        PArmure.Prix          := '';
        PArmure.CodeArmure := XmlAttribut(NodeNv2, ConstXmlId);
        PTraduction        := InitTrad(ConstPArmure, PArmure.CodeArmure, '', PArmure.Livre);

        Node := XmlElement(NodeNv2.FirstChild);
        while Assigned(Node) do
          begin
            case Node.NodeName of
              ConstXmlProtection:
                PArmure.Protection      := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
              ConstXmlDescription:
                begin
                  PArmure.Libelle       := RemoveQuotes(UTF8Encode(Node.TextContent));
                  Langue                := XmlAttribut(Node, ConstXmlLanguage);
                  PTraduction.Libelle   := PArmure.Libelle;
                end;
              ConstXmlDisponibilite:
                PArmure.Disponibilite   := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlType:
                PArmure.TypeMateriel    := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlEncombrement:
                PArmure.Encombrement    := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
              ConstXmlPrix:
                PArmure.Prix            := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlEmplacement:
                PArmure.Emplacement     := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlQualite:
                PArmure.ListeBonus      := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlFabIntegree:
                PArmure.Fabrication     := RemoveQuotes(UTF8Encode(Node.TextContent));
            end;

            Node := XmlElement(Node.NextSibling);
          end;
        if LangueDef = ConstAnglais then
          begin
            ListArmure.add(PArmure);
            inc(NbArmure);
            Inc(LivreNbArmure);
          end;

        AddTrad(PTraduction, Langue);

        NodeNv2 := XmlElement(NodeNv2.NextSibling);
      end;
  end;

// Lit les <Trapping> d un noeud DATA_TRAPPING (livre ou, plus tard, objets propres d un personnage).
Procedure LitTrappingsNoeud(NodeNv1: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    PTrapping:                StructureTrapping;
    PFabricationModificateur: StructureModificateur;
    PTraduction:              StructureTraduction;
    NodeNv2:                  TDOMNode;
    Node:                     TDOMNode;
  begin
    NodeNv2 := XmlElement(NodeNv1.FirstChild);
    While Assigned(NodeNv2) do
      begin
        PTrapping.Livre         := Livre;
        PTrapping.CodeTrapping  := XmlAttribut(NodeNv2, ConstXmlId);
        // remis a zero a chaque entree : le tag <Carries> n'existe que sur les
        // conteneurs/montures, PTrapping etant reutilise d'un tour de boucle a
        // l'autre sans lui la valeur de l'entree precedente resterait collee
        PTrapping.Capacite      := 0;
        PTrapping.CapaciteDeclaree := False;
        PTrapping.Encombrement  := 0;
        PTrapping.Prix          := '';
        PTrapping.Disponibilite := '';
        PTrapping.ProfilAnimal  := '';
        PTrapping.TraitsAnimal  := '';
        PTrapping.ProfilBateau  := '';
        PTrapping.ProfilVehicule := '';
        PTrapping.Theme         := '';
        PTrapping.Acheteur      := '';
        PTrapping.Localite      := '';
        PTrapping.Saison        := '';
        // remis a vide a chaque entree, meme piege que PTrapping.Capacite ci-dessus
        // et que PArme.Fabrication/PArmure.Fabrication (brique b, 28/09/2026).
        PTrapping.Fabrication   := '';
        PTraduction             := InitTrad(ConstPTrapping, PTrapping.CodeTrapping, '', PTrapping.Livre);

        Node := XmlElement(NodeNv2.FirstChild);
        while Assigned(Node) do
          begin
            // Modificateurs numeriques : lecteur commun, tous formats (e2a).
            if LitModificateurNoeud(Node, PTrapping.CodeTrapping, PFabricationModificateur) then
              begin
                if LangueDef = ConstAnglais then
                  begin
                    AjouteModificateurUnique(SourceModifTrapping, PFabricationModificateur);
                    inc(NbFabricationModificateur);
                  end;
              end
            else
            case Node.NodeName of
              ConstXmlDescription:
                begin
                  PTrapping.Libelle     := RemoveQuotes(UTF8Encode(Node.TextContent));
                  Langue                := XmlAttribut(Node, ConstXmlLanguage);
                  PTraduction.Libelle   := PTrapping.Libelle;
                end;
              ConstXmlDisponibilite:
                PTrapping.Disponibilite := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlEncombrement:
                PTrapping.Encombrement  := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
              ConstXmlCapacite:
                begin
                  PTrapping.Capacite         := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                  PTrapping.CapaciteDeclaree := True;
                end;
              ConstXmlProfilAnimal:
                PTrapping.ProfilAnimal  := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlTraitsAnimal:
                PTrapping.TraitsAnimal  := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlProfilBateau:
                PTrapping.ProfilBateau  := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlProfilVehicule:
                PTrapping.ProfilVehicule := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlPrix:
                PTrapping.Prix          := RemoveQuotes(UTF8Encode(Node.TextContent));
                ConstXmlTheme:
                  PTrapping.Theme         := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlAcheteur:
                PTrapping.Acheteur      := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlLocalite:
                PTrapping.Localite      := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlSaison:
                PTrapping.Saison        := RemoveQuotes(UTF8Encode(Node.TextContent));
              ConstXmlFabIntegree:
                PTrapping.Fabrication   := RemoveQuotes(UTF8Encode(Node.TextContent));
            end;

            Node := XmlElement(Node.NextSibling);
          end;
        if LangueDef = ConstAnglais then
          begin
            ListTrapping.add(PTrapping);
            inc(NbTrapping);
            Inc(LivreNbTrapping);
          end;

        AddTrad(PTraduction, Langue);

        NodeNv2 := XmlElement(NodeNv2.NextSibling);
      end;
  end;

Procedure LitDataAttribut(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    Node:         TDOMNode;
    PAttribut:    StructureAttribut;
    PTraduction:  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataAttribut);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PAttribut.Livre          := Livre;
            PAttribut.CodeAttribut   := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction              := InitTrad(ConstPAttribut, PAttribut.CodeAttribut, '', PAttribut.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                      PAttribut.Libelle       := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PTraduction.Libelle     := PAttribut.Libelle;
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage)
                    end;
                  ConstXmlExplanation:
                    begin
                      PAttribut.Description   := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PTraduction.Description := PAttribut.Description;
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage)
                    end;
                  ConstXmlShort:
                    begin
                      PAttribut.Resume        := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PTraduction.Resume      := PAttribut.Resume;
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage)
                    end;
                  ConstXmlOrder:
                    PAttribut.OrdreAttribut   := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                end;

                Node := XmlElement(Node.NextSibling);
              end;
              if LangueDef = ConstAnglais then
                begin
                  ListeAttribut.add(PAttribut);
                  inc(NbAttribut);
                end;

              AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataAttributCost(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:                TDOMNode;
    NodeNv2:                TDOMNode;
    PAttributAugmentation:  StructureAttributAugmentation;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataAttributCost);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PAttributAugmentation.Livre  := Livre;
            PAttributAugmentation.MinMax := XmlAttribut(NodeNv2, ConstXmlData);
            PAttributAugmentation.Cout   := StrToIntDef(RemoveQuotes(UTF8Encode(NodeNv2.TextContent)),0);

              if LangueDef = ConstAnglais then
                begin
                  ListeAttributAugmentation.add(PAttributAugmentation);
                  inc(NbAttributAugmentation);
                end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSkillCost(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:                  TDOMNode;
    NodeNv2:                  TDOMNode;
    PCompetenceAugmentation:  StructureCompetenceAugmentation;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSkillCost);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PCompetenceAugmentation.Livre          := Livre;
            PCompetenceAugmentation.MinMax := XmlAttribut(NodeNv2, ConstXmlData);
            PCompetenceAugmentation.Cout   := StrToIntDef(RemoveQuotes(UTF8Encode(NodeNv2.TextContent)),0);

              if LangueDef = ConstAnglais then
                begin
                  ListeCompetenceAugmentation.add(PCompetenceAugmentation);
                  inc(NbCompetenceAugmentation);
                end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataLabel(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    NodeNv3:      TDOMNode;
    PTexte:       StructureTexte;
    PTraduction:  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataLabel);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            Langue                    := XmlAttribut(NodeNv2, ConstXmlLanguage);
            NodeNv3 := XmlElement(NodeNv2.FirstChild);
            While Assigned(NodeNv3) do
              begin
                PTexte.Code           := XmlAttribut(NodeNv3, ConstXmlData);
                PTexte.Livre          := Livre;
                PTraduction           := InitTrad(ConstPTexte, PTexte.Code, '', PTexte.Livre);
                PTexte.Libelle        := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                PTraduction.Libelle   := PTexte.Libelle;

                  // un seul bloc de langue par code : le bloc francais d un fichier anglais
                  // ne doit pas doubler les entrees (traduction ajoutee plus bas par AddTrad)
                  if (LangueDef = ConstAnglais) and (Langue = ConstAnglais) then
                    begin
                      ListTexte.add(PTexte);
                      inc(NbTexte);
                    end;

                AddTrad(PTraduction, Langue);

                NodeNv3 := XmlElement(NodeNv3.NextSibling);
              end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSkill(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    Node:         TDOMNode;
    PCompetence:  StructureCompetence;
    PTraduction:  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSkill);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PCompetence.Livre          := Livre;
            PCompetence.SousCompetence := False;
            PCompetence.DeBase         := False;
            PCompetence.CodeCompetence := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction                := InitTrad(ConstPCompetence, PCompetence.CodeCompetence, '', PCompetence.Livre);
            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlCarac:
                    PCompetence.CodeAttribut  := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlDescription:
                    begin
                      PCompetence.Libelle     := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle     := PCompetence.Libelle;
                    end;
                  ConstXmlDeBase:
                    PCompetence.DeBase      := (RemoveQuotes(UTF8Encode(Node.TextContent)) = ConstVrai);
                  ConstXmlExplanation:
                    begin
                      PCompetence.Description := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Description := PCompetence.Description;
                    end;
                end;

                Node := XmlElement(Node.NextSibling);
              end;
           if LangueDef = ConstAnglais then
             begin
                ListCompetence.add(PCompetence);
                inc(NbCompetence);
                Inc(LivreNbCompetence);
                inc(NbCompetenceUnique);
             end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSkillSpe(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:          TDOMNode;
    NodeNv2:          TDOMNode;
    Node:             TDOMNode;
    PCompetence:      StructureCompetence;
    PCompetenceMere:  StructureCompetence;
    PTraduction:      StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSkillSpe);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PCompetence.Livre          := Livre;
            PCompetence.SousCompetence := True;
            PCompetence.DeBase         := False;
            PCompetence.Description := '';
            PCompetence.CodeAttribut   := '';
            PCompetence.CodeGenerique  := '';
            PCompetence.CodeCompetence := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction                := InitTrad(ConstPCompetence, PCompetence.CodeCompetence, '', PCompetence.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                      PCompetence.Libelle     := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle     := PCompetence.Libelle;
                    end;
                  ConstXmlGenerique:
                    PCompetence.CodeGenerique := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlDeBase:
                    PCompetence.DeBase        := (RemoveQuotes(UTF8Encode(Node.TextContent)) = ConstVrai);
                end;

                Node := XmlElement(Node.NextSibling);
              end;
            // Lien explicite (CONTEXT.md 2.67) prioritaire sur la deduction par radical -
            // seul repli quand le champ <Generique> n'est pas renseigne (donnee pas encore
            // migree, ou specialisation sans generique '_*' identifiee, ex. ids combines).
            if PCompetence.CodeGenerique <> '' then
              PCompetenceMere := ChercheCompetence(PCompetence.CodeGenerique)
            else
              PCompetenceMere := ChercheCompetence(ExtractStringBefore(PCompetence.CodeCompetence,ValeurSousCompetence)+ValeurGenerique);
            PCompetence.CodeAttribut := PCompetenceMere.CodeAttribut;
             if LangueDef = ConstAnglais then
               begin
                ListCompetence.add(PCompetence);
                inc(NbCompetence);
                Inc(LivreNbCompetence);
               end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataTalent(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:                 TDOMNode;
    NodeNv2:                 TDOMNode;
    Node:                    TDOMNode;
    PTalent:                 StructureTalent;
    PTraduction:             StructureTraduction;
    PTalentEffet:            StructureTalentEffet;
    PTalentCompetenceModif:  StructureTalentCompetenceModif;
    PTalentModificateur:     StructureModificateur;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataTalent);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PTalent.Livre          := Livre;
            PTalent.SousTalent     := false;
            PTalent.Trait          := false;
            // Champs de texte remis a vide : la structure est reutilisee d'un talent au suivant
            PTalent.Resume         := '';
            PTalent.Description    := '';
            PTalent.MaxiTalent     := '';
            PTalent.TalentPdf      := '';
            PTalent.Tests          := '';
            PTalent.CodeGenerique  := '';
            PTalent.Magie          := 0;
            PTalent.ModeSort       := '';
            PTalent.TypesSort      := '';
            // Tarif des sorts : remis a zero comme tout le reste de la structure, qui est
            // REUTILISEE d'un talent au suivant. Sans cela un talent de magie transmettrait
            // sa tarification a tous les talents ordinaires declares apres lui.
            PTalent.XpMultiplicateur := 0;
            PTalent.XpPlancher       := 0;
            PTalent.XpDiviseur       := '';
            PTalent.XpOfferts        := '';
            PTalent.XpGroupe         := '';
            PTalent.OctroiCarriere   := '';
            PTalent.RetraitCarriere  := '';
            PTalent.CodeTalent     := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction            := InitTrad(ConstPTalent, PTalent.CodeTalent, '', PTalent.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                // Modificateurs numeriques : lecteur commun, tous formats (e2a).
                if LitModificateurNoeud(Node, PTalent.CodeTalent, PTalentModificateur) then
                  begin
                    if LangueDef = ConstAnglais then
                      begin
                        AjouteModificateurUnique(SourceModifTalent, PTalentModificateur);
                        inc(NbTalentModificateur);
                      end;
                  end
                else
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                      PTalent.Libelle         := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle     := PTalent.Libelle;
                    end;
                  ConstXmlExplanation:
                    begin
                      PTalent.Description     := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Description := PTalent.Description;
                    end;
                  ConstXmlShort:
                    begin
                      PTalent.Resume          := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Resume      := PTalent.Resume;
                    end;
                  ConstXmlMax:
                    PTalent.MaxiTalent        := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlForPdf:
                    PTalent.TalentPdf         := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlOctroiCarriere:
                    PTalent.OctroiCarriere    := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlRetraitCarriere:
                    PTalent.RetraitCarriere   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlTrait:
                    PTalent.Trait             := (RemoveQuotes(UTF8Encode(Node.TextContent)) = ConstVrai);
                  ConstXmlMagie:
                    PTalent.Magie             := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)), 0);
                  ConstXmlModeSort:
                    PTalent.ModeSort          := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlTypesSort:
                    PTalent.TypesSort         := RemoveQuotes(UTF8Encode(Node.TextContent));
                  // Tarif des sorts ouverts par ce talent. Lu seulement sur les talents
                  // GENERIQUES : les specialisations n'en portent pas et le recuperent par
                  // l'heritage de ChercheTalent, exactement comme Magie et ModeSort.
                  ConstXmlXpMultiplicateur:
                    PTalent.XpMultiplicateur  := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)), 0);
                  ConstXmlXpPlancher:
                    PTalent.XpPlancher        := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)), 0);
                  ConstXmlXpDiviseur:
                    PTalent.XpDiviseur        := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlXpOfferts:
                    PTalent.XpOfferts         := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlXpGroupe:
                    PTalent.XpGroupe          := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlTest:
                    begin
                      PTalent.Tests           := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                  := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Tests       := PTalent.Tests;
                    end;
                  ConstXmlEffetTalent:
                    begin
                      PTalentEffet.Livre      := Livre;
                      PTalentEffet.CodeTalent := PTalent.CodeTalent;
                      PTalentEffet.Cible      := XmlAttribut(Node, ConstXmlEffetCible);
                      PTalentEffet.Forme      := XmlAttribut(Node, ConstXmlEffetForme);
                      PTalentEffet.Facteur    := StrToIntDef(XmlAttribut(Node, ConstXmlEffetFacteur), 0);
                      if Assigned(Node.Attributes) and Assigned(Node.Attributes.GetNamedItem(ConstXmlEffetCarac)) then
                        PTalentEffet.Carac    := XmlAttribut(Node, ConstXmlEffetCarac)
                      else
                        PTalentEffet.Carac    := '';
                      if LangueDef = ConstAnglais then
                         begin
                          ListTalentEffet.add(PTalentEffet);
                          inc(NbTalentEffet);
                         end;
                    end;
                  ConstXmlModifieCompetence:
                    begin
                      PTalentCompetenceModif.Livre          := Livre;
                      PTalentCompetenceModif.CodeTalent     := PTalent.CodeTalent;
                      PTalentCompetenceModif.CodeCompetence := XmlAttribut(Node, ConstXmlData);
                      PTalentCompetenceModif.TypeModif      := RemoveQuotes(UTF8Encode(Node.TextContent));
                      if LangueDef = ConstAnglais then
                         begin
                          ListTalentCompetenceModif.add(PTalentCompetenceModif);
                          inc(NbTalentCompetenceModif);
                         end;
                    end;
                end;

                Node := XmlElement(Node.NextSibling);
              end;
             if LangueDef = ConstAnglais then
               begin
                ListTalent.add(PTalent);
                inc(NbTalent);
                Inc(LivreNbTalent);
                inc(NbTalentUnique);
               end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataTalentSpe(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    Node:         TDOMNode;
    PTalent:      StructureTalent;
    PTraduction:  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataTalentSpe);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PTalent.Livre             := Livre;
            PTalent.SousTalent        := True;
            PTalent.Trait             := false;
            PTalent.Magie             := 0;
            PTalent.ModeSort          := '';
            PTalent.TypesSort         := '';
            // Une specialisation ne porte jamais de tarif : elle le recupere de sa
            // famille generique via ChercheTalent. Remise a zero pour la meme raison
            // que Magie et ModeSort juste au-dessus - la structure est reutilisee.
            PTalent.XpMultiplicateur  := 0;
            PTalent.XpPlancher        := 0;
            PTalent.XpDiviseur        := '';
            PTalent.XpOfferts         := '';
            PTalent.XpGroupe          := '';
            PTalent.OctroiCarriere    := '';
            PTalent.RetraitCarriere   := '';
            PTalent.Description       := '';

            PTalent.Description       := '';
            PTalent.Resume            := '';
            PTalent.MaxiTalent        := '';
            PTalent.TalentPdf         := '';
            PTalent.Tests             := '';
            PTalent.CodeGenerique     := '';
            PTalent.CodeTalent        := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction               := InitTrad(ConstPTalent, PTalent.CodeTalent, '', PTalent.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                    PTalent.Libelle     := RemoveQuotes(UTF8Encode(Node.TextContent));
                    Langue              := XmlAttribut(Node, ConstXmlLanguage);
                    PTraduction.Libelle := PTalent.Libelle;
                    end;
                  // une specialisation de trait reste un trait (ex. Immunity (Poison))
                  ConstXmlTrait:
                    PTalent.Trait       := (RemoveQuotes(UTF8Encode(Node.TextContent)) = ConstVrai);
                  ConstXmlGenerique:
                    PTalent.CodeGenerique := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;

                Node := XmlElement(Node.NextSibling);
              end;
             if LangueDef = ConstAnglais then
               begin
                ListTalent.add(PTalent);
                inc(NbTalent);
                Inc(LivreNbTalent);
               end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataRandomTalent(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:          TDOMNode;
    NodeNv2:          TDOMNode;
    Node:             TDOMNode;
    PTalentCreation:  StructureTalentCreation;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataRandomTalent);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PTalentCreation.Livre      := Livre;
            PTalentCreation.CodeTalent := XmlAttribut(NodeNv2, ConstXmlId);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlRace:
                    PTalentCreation.CodeRace   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlTalent:
                    PTalentCreation.Chance     := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;

                Node := XmlElement(Node.NextSibling);
              end;
             if LangueDef = ConstAnglais then
               begin
                ListTalentCreation.add(PTalentCreation);
                inc(NbTalentCreation);
               end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataEspece(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:             TDOMNode;
    NodeNv2:             TDOMNode;
    NodeNv4:             TDOMNode;
    Node:                TDOMNode;
    PEspece:             StructureEspece;
    PRacePhysique:       StructureRacePhysique;
    PRaceCouleur:        StructureRaceCouleur;
    PTraduction:         StructureTraduction;
    PTraductionCouleur:  StructureTraduction;
    PRaceOpinion:        StructureRaceOpinion;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataEspece);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            if NodeNv2.NodeName = ConstXmlEspece then
             begin
            PEspece.Livre      := Livre;
            PEspece.Libelle    := '';
            // Record local reutilise d'une race a l'autre : sans remise a zero,
            // une race sans balise heriterait du dossier de la precedente.
            PEspece.DossierNiveau := '';
            PEspece.CodeEspece := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction        := InitTrad(ConstPEspece, PEspece.CodeEspece, '', PEspece.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                      PEspece.Libelle     := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue              := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle := PEspece.Libelle;
                    end;
                  ConstXmlPictureLevel:
                    PEspece.DossierNiveau := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlOpinions:  // opinions de cette RACE sur les autres races
                    begin
                      NodeNv4 := XmlElement(Node.FirstChild);
                      while Assigned(NodeNv4) do
                        begin
                          if NodeNv4.NodeName = ConstXmlOpinion then
                            begin
                              PRaceOpinion.Livre      := Livre;
                              PRaceOpinion.CodeRace   := PEspece.CodeEspece;
                              PRaceOpinion.TargetRace := XmlAttribut(NodeNv4, ConstXmlTarget);
                              PRaceOpinion.Source     := XmlAttribut(NodeNv4, ConstXmlSource);
                              PRaceOpinion.Citation   := RemoveQuotes(UTF8Encode(NodeNv4.TextContent));
                              if LangueDef = ConstAnglais then
                                begin
                                  ListRaceOpinion.add(PRaceOpinion);
                                  inc(NbRaceOpinion);
                                end;
                            end;
                          NodeNv4 := XmlElement(NodeNv4.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitrePhysique:  // details physiques de cette RACE
                    begin
                      PRacePhysique                := Default(StructureRacePhysique);
                      PRacePhysique.Livre          := Livre;
                      PRacePhysique.CodeRace       := PEspece.CodeEspece;
                      PRacePhysique.NbTirageYeux   := 1;
                      NodeNv4 := XmlElement(Node.FirstChild);
                      while Assigned(NodeNv4) do
                        begin
                          case NodeNv4.NodeName of
                            ConstXmlAge:
                              PRacePhysique.FormuleAge     := RemoveQuotes(UTF8Encode(NodeNv4.TextContent));
                            ConstXmlHeight:
                              PRacePhysique.FormuleTaille  := RemoveQuotes(UTF8Encode(NodeNv4.TextContent));
                            ConstXmlPhysTailleExplose:
                              PRacePhysique.TailleExplose  := RemoveQuotes(UTF8Encode(NodeNv4.TextContent)) = ConstVrai;
                            ConstXmlPhysNbTirageYeux:
                              PRacePhysique.NbTirageYeux   := StrToIntDef(RemoveQuotes(UTF8Encode(NodeNv4.TextContent)), 1);
                            ConstXmlPhysYeux, ConstXmlPhysCheveux:
                              begin
                                PRaceCouleur.Livre    := Livre;
                                PRaceCouleur.CodeRace := PEspece.CodeEspece;
                                PRaceCouleur.EstYeux  := NodeNv4.NodeName = ConstXmlPhysYeux;
                                PRaceCouleur.Libelle  := XmlAttribut(NodeNv4, ConstXmlData);
                                PRaceCouleur.Plage    := RemoveQuotes(UTF8Encode(NodeNv4.TextContent));
                                if LangueDef = ConstAnglais then
                                  begin
                                    ListRaceCouleur.Add(PRaceCouleur);
                                    Inc(NbRaceCouleur);
                                  end;
                                // La couleur n'a pas de code : la plage 2d10 l'identifie dans
                                // sa race (voir Traduit, ConstPRaceCouleur).
                                PTraductionCouleur         := InitTrad(ConstPRaceCouleur, PEspece.CodeEspece,
                                  IfThen(PRaceCouleur.EstYeux, 'Y', 'H') + '|' + PRaceCouleur.Plage, Livre);
                                PTraductionCouleur.Libelle := PRaceCouleur.Libelle;
                                AddTrad(PTraductionCouleur, LangueDef);
                              end;
                          end;
                          NodeNv4 := XmlElement(NodeNv4.NextSibling);
                        end;
                      if LangueDef = ConstAnglais then
                        begin
                          ListRacePhysique.Add(PRacePhysique);
                          Inc(NbRacePhysique);
                        end;
                    end;
                end;

                Node := XmlElement(Node.NextSibling);
              end;

            if LangueDef = ConstAnglais then
              begin
                ListEspece.add(PEspece);
                inc(NbEspece);
              end;

            AddTrad(PTraduction, Langue);
             end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataNation(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    Node:         TDOMNode;
    PNation:      StructureNation;
    PTraduction:  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataNation);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            if NodeNv2.NodeName = ConstXmlNation then
             begin
            PNation.Livre      := Livre;
            PNation.Libelle    := '';
            PNation.CodeNation := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction        := InitTrad(ConstPNation, PNation.CodeNation, '', PNation.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                      PNation.Libelle     := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue              := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle := PNation.Libelle;
                    end;
                end;

                Node := XmlElement(Node.NextSibling);
              end;

            if LangueDef = ConstAnglais then
              begin
                ListNation.add(PNation);
                inc(NbNation);
              end;

            AddTrad(PTraduction, Langue);
             end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSpecie(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:           TDOMNode;
    NodeNv2:           TDOMNode;
    NodeNv3:           TDOMNode;
    Node:              TDOMNode;
    PRace:             StructureRace;
    IndRaceExistante:  Integer;
    IndBoucleRace:     Integer;
    PRaceAttribut:     StructureRaceAttribut;
    PRaceNom:          StructureRaceNom;
    PRaceNomModele:    StructureRaceNomModele;
    PRaceNomRegle:     StructureRaceNomRegle;
    PRaceCompetence:   StructureRaceCompetence;
    PRaceTalent:       StructureRaceTalent;
    PRaceMetier:       StructureRaceMetier;
    PTraduction:       StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSpecie);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PRace.Livre    := Livre;
            PRace.CodeRace := XmlAttribut(NodeNv2, ConstXmlId);
            PRace.Point3   := 3;
            PRace.Point5   := 5;
            PRace.NbPoint3 := 3;
            PRace.NbPoint5 := 3;
            // Record local reutilise d'une ethnie a l'autre : sans cette remise
            // a zero, une ethnie sans balise <PictureLevel> heriterait du dossier
            // de la precedente (meme piege que les fonctions Cherche*, cf 2.17).
            PRace.DossierNiveau := '';
            // Meme remise a zero pour Nation : balise FACULTATIVE, la plupart des
            // ethnies n'en portent aucune. CONTEXT.md 2.51.
            PRace.Nation := '';
            PTraduction    := InitTrad(ConstPRace, PRace.CodeRace, '', PRace.Livre);

            NodeNv3 := XmlElement(NodeNv2.FirstChild);
            while Assigned(NodeNv3) do
              begin
                case NodeNv3.NodeName of
                  ConstXmlDescription:
                    begin
                      PRace.Libelle          := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                      Langue                 := XmlAttribut(NodeNv3, ConstXmlLanguage);
                      PTraduction.Libelle    := PRace.Libelle;
                    end;
                  ConstXmlExplanation:
                    begin
                      PRace.Description       := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                      Langue                  := XmlAttribut(NodeNv3, ConstXmlLanguage);
                      PTraduction.Description := PRace.Description;
                    end;
                  ConstXmlNbSkill5:
                    PRace.NbPoint5 := StrToIntDef(RemoveQuotes(UTF8Encode(NodeNv3.TextContent)), 3);
                  ConstXmlNbSkill3:
                    PRace.NbPoint3 := StrToIntDef(RemoveQuotes(UTF8Encode(NodeNv3.TextContent)), 3);
                  ConstXmlPictureLevel:
                    PRace.DossierNiveau       := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                  ConstXmlEthnic:
                    PRace.Espece              := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                  ConstXmlNationality:
                    PRace.Nation              := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                  ConstXmlSousChapitreCarac:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlCarac:
                               begin
                                 PRaceAttribut.Livre        := Livre;
                                 PRaceAttribut.CodeRace     := PRace.CodeRace;
                                 PRaceAttribut.CodeAttribut := XmlAttribut(Node, ConstXmlData);
                                 PRaceAttribut.CalculRace   := RemoveQuotes(UTF8Encode(Node.TextContent));
                                  if LangueDef = ConstAnglais then
                                    begin
                                     ListRaceAttribut.add(PRaceAttribut);
                                     inc(NbRaceAttribut);
                                    end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreNoms:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                            ConstXmlNom:
                              begin
                                PRaceNom := Default(StructureRaceNom);
                                PRaceNom.Livre    := Livre;
                                PRaceNom.CodeRace := PRace.CodeRace;
                                PRaceNom.Libelle  := XmlAttribut(Node, ConstXmlData);
                                PRaceNom.Plage    := RemoveQuotes(UTF8Encode(Node.TextContent));
                                if Assigned(Node.Attributes.GetNamedItem(ConstXmlNomPartie)) then
                                  PRaceNom.Partie := XmlAttributBrut(Node, ConstXmlNomPartie);
                                if Assigned(Node.Attributes.GetNamedItem(ConstXmlNomSexe)) then
                                  PRaceNom.Sexe := XmlAttributBrut(Node, ConstXmlNomSexe);
                                if LangueDef = ConstAnglais then
                                  begin
                                    ListRaceNom.Add(PRaceNom);
                                    Inc(NbRaceNom);
                                  end;
                              end;
                            ConstXmlNomModele:
                              begin
                                PRaceNomModele := Default(StructureRaceNomModele);
                                PRaceNomModele.Livre    := Livre;
                                PRaceNomModele.CodeRace := PRace.CodeRace;
                                PRaceNomModele.Modele   := RemoveQuotes(UTF8Encode(Node.TextContent));
                                if Assigned(Node.Attributes.GetNamedItem(ConstXmlNomSexe)) then
                                  PRaceNomModele.Sexe := XmlAttributBrut(Node, ConstXmlNomSexe);
                                if Assigned(Node.Attributes.GetNamedItem(ConstXmlNomRegle)) then
                                  PRaceNomModele.Regle := XmlAttributBrut(Node, ConstXmlNomRegle);
                                if LangueDef = ConstAnglais then
                                  begin
                                    ListRaceNomModele.Add(PRaceNomModele);
                                    Inc(NbRaceNomModele);
                                  end;
                              end;
                            ConstXmlNomRegleDecl:
                              begin
                                PRaceNomRegle := Default(StructureRaceNomRegle);
                                PRaceNomRegle.Livre    := Livre;
                                PRaceNomRegle.CodeRace := PRace.CodeRace;
                                PRaceNomRegle.Libelle  := RemoveQuotes(UTF8Encode(Node.TextContent));
                                if Assigned(Node.Attributes.GetNamedItem(ConstXmlNomRegleCode)) then
                                  PRaceNomRegle.Code := XmlAttributBrut(Node, ConstXmlNomRegleCode);
                                if (LangueDef = ConstAnglais) and (PRaceNomRegle.Code <> '') then
                                  ListRaceNomRegle.Add(PRaceNomRegle);
                              end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreCompetence:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlCompetence:
                               begin
                                 PRaceCompetence.Livre          := Livre;
                                 PRaceCompetence.CodeRace       := PRace.CodeRace;
                                 PRaceCompetence.CodeCompetence := RemoveQuotes(UTF8Encode(Node.TextContent));
                                  if LangueDef = ConstAnglais then
                                    begin
                                     ListRaceCompetence.add(PRaceCompetence);
                                     inc(NbRaceCompetence);
                                    end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreTalent:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlTalent:
                               begin
                                 PRaceTalent.Livre          := Livre;
                                 PRaceTalent.CodeRace       := PRace.CodeRace;
                                 PRaceTalent.CodeTalent     := RemoveQuotes(UTF8Encode(Node.TextContent));
                                  if LangueDef = ConstAnglais then
                                    begin
                                     ListRaceTalent.add(PRaceTalent);
                                     inc(NbRaceTalent);
                                    end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreMetier:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlWork:
                               begin
                                 PRaceMetier.Livre        := Livre;
                                 PRaceMetier.CodeRace     := PRace.CodeRace;
                                 PRaceMetier.CodeMetier   := XmlAttribut(Node, ConstXmlData);
                                 PRaceMetier.Chance       := RemoveQuotes(UTF8Encode(Node.TextContent));
                                  if LangueDef = ConstAnglais then
                                    begin
                                     AjouteRaceMetierSource(FormeRaceMetierBlocEspece, Livre, PRaceMetier.CodeRace, PRaceMetier.CodeMetier, PRaceMetier.Chance);
                                     ListRaceMetier.add(PRaceMetier);
                                     inc(NbRaceMetier);
                                    end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                end;

                NodeNv3 := XmlElement(NodeNv3.NextSibling);
              end;
             if LangueDef = ConstAnglais then
               begin
                // Ne pas recréer une ligne de race si ce CodeRace existe déjà ET
                // porte déjà un libellé (cas d'un livre qui ne fait qu'ajouter des
                // données - ex. SUBCHAPTER_CAREER - sur une race définie ailleurs,
                // sans redéclarer Description/SUBCHAPTER_ATTR/etc.)
                //
                // L'ordre de chargement des livres n'est PAS garanti (CONTEXT.md
                // §2.9) : si le livre qui pose un stub minimal (juste l'id +
                // SUBCHAPTER_CAREER, cas ci-dessus) se charge AVANT celui qui
                // définit vraiment la race, ChercheRace() trouverait ce stub et la
                // vraie définition (Libelle/Description/etc.) serait perdue pour
                // toujours si on se contentait de sauter l'ajout. On remplace donc
                // un stub (Libelle vide) par la définition complète dès qu'elle
                // arrive, quel que soit l'ordre - releve le 14/09/2026 en ajoutant
                // le rattachement Norsca/Tilee des carrieres Nations of Mankind.
                IndRaceExistante := -1;
                For IndBoucleRace := 0 to ListRace.Count - 1 do
                  if ListRace[IndBoucleRace].CodeRace = PRace.CodeRace then
                    begin
                      IndRaceExistante := IndBoucleRace;
                      break;
                    end;
                if IndRaceExistante < 0 then
                  begin
                   ListRace.add(PRace);
                   inc(NbRace);
                   Inc(LivreNbrace);
                  end
                else if (ListRace[IndRaceExistante].Libelle = '') and (PRace.Libelle <> '') then
                  ListRace[IndRaceExistante] := PRace;
               end;

            // Un stub (juste l'id + SUBCHAPTER_CAREER, race definie dans un
            // autre livre) n'a pas de Libelle a traduire : l'enregistrer ici
            // ecrirait une entree ListTraduction avec un Libelle vide qui,
            // rappliquee au prochain Traduit(ConstAnglais, ...) (ex. retour a
            // l'anglais apres un changement de langue), effacerait le vrai
            // libelle/description de la race chargee par son livre d'origine -
            // CompareRechercheValeur matche sur le seul CodeRace, sans notion
            // d'ordre de chargement. Releve le 14/09/2026 avec le rattachement
            // Norsca/Tilee des carrieres Nations of Mankind.
            if PRace.Libelle <> '' then
              AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSpecieCreation(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:        TDOMNode;
    NodeNv2:        TDOMNode;
    PRaceCreation:  StructureRaceCreation;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSpecieCreation);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PRaceCreation.Livre    := Livre;
            PRaceCreation.CodeRace := XmlAttribut(NodeNv2, ConstXmlData);
            PRaceCreation.Chance   := RemoveQuotes(UTF8Encode(NodeNv2.TextContent));

             if LangueDef = ConstAnglais then
               begin
                ListRaceCreation.add(PRaceCreation);
                inc(NbRaceCreation);
               end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCareer(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    QuantiteAttr:       String;
    NodeNv1:            TDOMNode;
    NodeNv2:            TDOMNode;
    NodeNv3:            TDOMNode;
    NodeNv4:            TDOMNode;
    Node:               TDOMNode;
    PRaceMetier:        StructureRaceMetier;
    PMetier:            StructureMetier;
    PMetierNiveau:      StructureMetierNiveau;
    PMetierAttribut:    StructureMetierAttribut;
    PMetierTalent:      StructureMetierTalent;
    PMetiercompetence:  StructureMetierCompetence;
    PMetierEquipement:  StructureMetierEquipement;
    PTraduction:        StructureTraduction;
    PTraductionNv2:     StructureTraduction;
    LangueNv2:          String;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCareer);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PMetier.Livre      := Livre;
            // Meme precaution que pour les ethnies et les races.
            PMetier.DossierNiveau := '';
            PMetier.MetierParent  := '';
            PMetier.CodeMetier := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction        := InitTrad(ConstPMetier, PMetier.CodeMetier, '', PMetier.Livre);

            NodeNv3 := XmlElement(NodeNv2.FirstChild);
            while Assigned(NodeNv3) do
              begin
                case NodeNv3.NodeName of
                  ConstXmlDescription:
                    begin
                      PMetier.Libelle         := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                      Langue                  := XmlAttribut(NodeNv3, ConstXmlLanguage);
                      PTraduction.Libelle     := PMetier.Libelle;
                    end;
                  ConstXmlExplanation:
                    begin
                      PMetier.Description     := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                      Langue                  := XmlAttribut(NodeNv3, ConstXmlLanguage);
                      PTraduction.Description := PMetier.Description;
                    end;
                  ConstXmlClass:
                    PMetier.LibelleGroupe := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                  ConstXmlCompetence:
                    PMetier.CodeCompetence:= RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                  ConstXmlPictureLevel:
                    PMetier.DossierNiveau := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                  ConstXmlMetierParent:
                    PMetier.MetierParent  := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                  ConstXmlRace:
                    if LangueDef = ConstAnglais then
                      begin
                        AjouteRaceMetierSource(FormeRaceMetierFicheMetier, Livre, RemoveQuotes(UTF8Encode(NodeNv3.TextContent)), PMetier.CodeMetier, 'X');
                        AjouteRaceMetierSiAbsent(Livre, RemoveQuotes(UTF8Encode(NodeNv3.TextContent)), PMetier.CodeMetier);
                      end;
                  ConstXmlSousChapitreNiveau:
                    begin
                      NodeNv4 := XmlElement(NodeNv3.FirstChild);
                      while Assigned(NodeNv4) do
                        begin
                          case NodeNv4.NodeName of
                             ConstXmlNvWork:
                               begin
                                 PMetierNiveau.NiveauMetier := StrToIntDef(XmlAttribut(NodeNv4, ConstXmlId),0);
                                 PMetierNiveau.Livre        := Livre;
                                 PMetierNiveau.CodeMetier   := PMetier.CodeMetier;
                                 PTraductionNv2             := InitTrad(PMetierNiveau.CodeMetier, IntToStr(PMetierNiveau.NiveauMetier), '', PMetierNiveau.Livre);
                                 Node := XmlElement(NodeNv4.FirstChild);
                                 while Assigned(Node) do
                                   begin
                                     case Node.NodeName of
                                        ConstXmlDescription:
                                          begin
                                            PMetierNiveau.Libelle  := RemoveQuotes(UTF8Encode(Node.TextContent));
                                            LangueNv2              := XmlAttribut(Node, ConstXmlLanguage);
                                            PTraductionNv2.Libelle := PMetierNiveau.Libelle;
                                          end;
                                        ConstXmlSalaire:
                                          PMetierNiveau.SalaireMetier := RemoveQuotes(UTF8Encode(Node.TextContent));
                                     end;
                                     Node := XmlElement(Node.NextSibling);
                                   end;
                                  if LangueDef = ConstAnglais then
                                    begin
                                      ListMetierNiveau.Add(PMetierNiveau);
                                      Inc(NbMetierNiveau);
                                    end;

                                 AddTrad(PTraductionNv2, LangueNv2);
                               end;
                          end;
                          NodeNv4 := XmlElement(NodeNv4.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreCarac:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlCarac:
                               begin
                                 PMetierAttribut.Livre        := Livre;
                                 PMetierAttribut.CodeMetier   := PMetier.CodeMetier;
                                 PMetierAttribut.CodeAttribut := XmlAttribut(Node, ConstXmlData);
                                 PMetierAttribut.NiveauMetier := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                                  if LangueDef = ConstAnglais then
                                    begin
                                     ListMetierAttribut.add(PMetierAttribut);
                                     inc(NbMetierAttribut);
                                    end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreCompetence:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlCompetence:
                               begin
                                 PMetierCompetence.Livre          := Livre;
                                 PMetierCompetence.CodeMetier     := PMetier.CodeMetier;
                                 PMetierCompetence.CodeCompetence := XmlAttribut(Node, ConstXmlData);
                                 PMetierCompetence.NiveauMetier   := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                                  if LangueDef = ConstAnglais then
                                    begin
                                     ListMetierCompetence.add(PMetierCompetence);
                                     inc(NbMetierCompetence);
                                    end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreTalent:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlTalent:
                               begin
                                 PMetierTalent.Livre          := Livre;
                                 PMetierTalent.CodeMetier     := PMetier.CodeMetier;
                                 PMetierTalent.CodeTalent     := XmlAttribut(Node, ConstXmlData);
                                 PMetierTalent.NiveauMetier   := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                                  if LangueDef = ConstAnglais then
                                    begin
                                     ListMetierTalent.add(PMetierTalent);
                                     inc(NbMetierTalent);
                                    end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreEquipement:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlEquipement:
                               begin
                                 PMetierEquipement.Livre          := Livre;
                                 PMetierEquipement.CodeMetier     := PMetier.CodeMetier;
                                 PMetierEquipement.Equipement     := XmlAttribut(Node, ConstXmlData);
                                 PMetierEquipement.NiveauMetier   := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                                 // Liste "2/1/1" = une quantite par branche du choix, gardee
                                 // brute ; un nombre seul reste dans Quantite.
                                 PMetierEquipement.Quantite       := 1;
                                 PMetierEquipement.QuantiteListe  := '';
                                 if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite)) then
                                   begin
                                     QuantiteAttr := XmlAttributBrut(Node, ConstXmlEquipementQuantite);
                                     if Pos(SeparateurMulti, QuantiteAttr) > 0 then
                                       PMetierEquipement.QuantiteListe := QuantiteAttr
                                     else
                                       PMetierEquipement.Quantite      := StrToIntDef(QuantiteAttr, 1);
                                   end;

                                 if LangueDef = ConstAnglais then
                                   begin
                                     PMetierEquipement.TypeEquipement := GetTypeMetierEquipement(PMetierEquipement.Equipement);
                                     ListMetierEquipement.add(PMetierEquipement);
                                     inc(NbMetierEquipement);
                                   end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                  ConstXmlSousChapitreRace:
                    begin
                      Node := XmlElement(NodeNv3.FirstChild);
                      while Assigned(Node) do
                        begin
                          case Node.NodeName of
                             ConstXmlRace:
                               begin
                                 PRaceMetier.Livre          := Livre;
                                 PRaceMetier.CodeMetier     := PMetier.CodeMetier;
                                 PRaceMetier.CodeRace       := XmlAttribut(Node, ConstXmlData);
                                 PRaceMetier.Chance         := RemoveQuotes(UTF8Encode(Node.TextContent));

                                 if LangueDef = ConstAnglais then
                                   begin
                                     AjouteRaceMetierSource(FormeRaceMetierSousChapitre, Livre, PRaceMetier.CodeRace, PRaceMetier.CodeMetier, PRaceMetier.Chance);
                                     ListRaceMetier.add(PRaceMetier);
                                     inc(NbRaceMetier);
                                   end;
                               end;
                          end;
                          Node := XmlElement(Node.NextSibling);
                        end;
                    end;
                end;

                NodeNv3 := XmlElement(NodeNv3.NextSibling);
              end;
            if LangueDef = ConstAnglais then
              begin
                ListMetier.add(PMetier);
                inc(NbMetier);
                Inc(LivreNbMetier);
              end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataWeapon(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:            TDOMNode;
    NodeNv2:            TDOMNode;
    Node:               TDOMNode;
    PTraduction:        StructureTraduction;
    PArmureSimplifiee:  StructureArmureSimplifiee;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataWeapon);
    if Assigned(NodeNv1) then
      LitArmesNoeud(NodeNv1, Livre, LangueDef, Langue);

    // ArmeBonus
    NodeNv1 := BookNode.FindNode(ConstXmlDataWeaponBonus);
    if Assigned(NodeNv1) then
      LitArmesBonusNoeud(NodeNv1, Livre, LangueDef, Langue);

    // Armures simplifiées
    NodeNv1 := BookNode.FindNode(ConstXmlDataArmorSimplified);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PArmureSimplifiee.Livre      := Livre;
            PArmureSimplifiee.CodeArmure := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction                  := InitTrad(ConstPArmureSimplifiee, PArmureSimplifiee.CodeArmure, '', PArmureSimplifiee.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlProtection:
                    PArmureSimplifiee.Protection      := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                  ConstXmlDescription:
                    begin
                      PArmureSimplifiee.Libelle       := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                          := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle             := PArmureSimplifiee.Libelle;
                    end;
                  ConstXmlDisponibilite:
                    PArmureSimplifiee.Disponibilite   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlEncombrement:
                    PArmureSimplifiee.Encombrement    := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                  ConstXmlPrix:
                    PArmureSimplifiee.Prix            := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlQualite:
                    PArmureSimplifiee.ListeBonus      := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;

                Node := XmlElement(Node.NextSibling);
              end;
            // Option Quick Armour (Rulebook p.301) desactivable via le .INI
            // (A FAIRE.txt "TOGGLE .INI PAR LIVRE", 22/09/2026) : si desactivee,
            // l'armure simplifiee n'est pas chargee du tout - vraie desactivation
            // au chargement, pas un simple filtre d'affichage.
            if LangueDef = ConstAnglais then
              ListArmureSimplifieeSource.Add(PArmureSimplifiee);
            if (LangueDef = ConstAnglais) and not OptionDesactivee(Livre, ConstOptionQuickArmour) then
              begin
                ListArmureSimplifiee.add(PArmureSimplifiee);
                inc(NbArmureSimplifiee);
              end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataOptionRule(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:         TDOMNode;
    NodeNv2:         TDOMNode;
    Node:            TDOMNode;
    POptionRegle:    StructureOptionRegle;
    IndOptionRegle:  Integer;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataOptionRule);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            POptionRegle.Livre := Livre;
            POptionRegle.CodeId := XmlAttribut(NodeNv2, ConstXmlId);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlCode:
                    POptionRegle.CodeOption := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlDescription:
                    POptionRegle.Libelle := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlExplanation:
                    POptionRegle.Explication := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;

                Node := XmlElement(Node.NextSibling);
              end;

            // Contrairement aux armures simplifiees (une seule passe anglaise,
            // jamais re-localisee), les regles optionnelles doivent afficher le
            // texte de la langue choisie quand le livre a une version traduite
            // (Quick Armour/Rulebook) : la 1ere passe rencontree cree l entree
            // (base anglaise si elle vient en premier), une 2e passe dans la
            // langue ACTIVE (ValLangue) remplace juste le texte au lieu d en
            // ajouter une 2e ligne - CONTEXT.md 2.89, 22/09/2026.
            IndOptionRegle := IndexOptionRegle(POptionRegle.Livre, POptionRegle.CodeId);
            if IndOptionRegle < 0 then
              begin
                ListOptionRegle.add(POptionRegle);
                inc(NbOptionRegle);
              end
            else if LangueDef = ValLangue then
              ListOptionRegle[IndOptionRegle] := POptionRegle;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataArmor(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    Node:         TDOMNode;
    PSort:        StructureSort;
    PTraduction:  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataArmor);
    if Assigned(NodeNv1) then
      LitArmuresNoeud(NodeNv1, Livre, LangueDef, Langue);

    // Trapping (equipement divers, hors armes/armures)
    NodeNv1 := BookNode.FindNode(ConstXmlDataTrapping);
    if Assigned(NodeNv1) then
      LitTrappingsNoeud(NodeNv1, Livre, LangueDef, Langue);

    // ArmureBonuss
    NodeNv1 := BookNode.FindNode(ConstXmlDataArmorBonus);
    if Assigned(NodeNv1) then
      LitArmuresBonusNoeud(NodeNv1, Livre, LangueDef, Langue);

    // Sorts
    NodeNv1 := BookNode.FindNode(ConstXmlDataSpell);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PSort.Livre    := Livre;
            PSort.XpFixe   := '';  // balise optionnelle : ne pas heriter du sort precedent
            PSort.CodeSort := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction    := InitTrad(ConstPSort, PSort.CodeSort, '', PSort.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlExplanation:
                    begin
                      PSort.Description         := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                    := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Description   := PSort.Description;
                    end;
                  ConstXmlDescription:
                    begin
                      PSort.Libelle             := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                    := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle       := PSort.Libelle;
                    end;
                  ConstXmlCible:
                    PSort.Cible           := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlDuree:
                    PSort.Duree           := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlPorteeSort:
                    PSort.Portee          := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlTalent:
                    PSort.ListeTalent     := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlNiveau:
                    PSort.Niveau          := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlTypeSort:
                    PSort.TypeSort        := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlXpFixe:
                    PSort.XpFixe          := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;

                Node := XmlElement(Node.NextSibling);
              end;
            if LangueDef = ConstAnglais then
              begin
                ListSort.add(PSort);
                inc(NbSort);
                Inc(LivreNbSort);
              end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSpellTalent(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    Node:         TDOMNode;
    PSortTalent:  StructureSortTalent;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSpellTalent);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PSortTalent.Livre       := Livre;
            PSortTalent.CodeSort    := XmlAttribut(NodeNv2, ConstXmlId);
            PSortTalent.ListeTalent := '';

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlTalent:
                    PSortTalent.ListeTalent := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;

                Node := XmlElement(Node.NextSibling);
              end;
            if LangueDef = ConstAnglais then
              begin
                ListSortTalent.add(PSortTalent);
                inc(NbSortTalent);
              end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSpecieTrait(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:            TDOMNode;
    NodeNv2:            TDOMNode;
    NodeNv3:            TDOMNode;
    Node:               TDOMNode;
    PTrait:             StructureTrait;
    PTraitOption:       StructureTraitOption;
    PTraduction:        StructureTraduction;
    PTraductionOption:  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSpecieTrait);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            if NodeNv2.NodeName = ConstXmlSpecieTrait then
              begin
                PTrait.Livre     := Livre;
                PTrait.Libelle   := '';
                PTrait.CodeTrait := XmlAttribut(NodeNv2, ConstXmlId);
                PTraduction      := InitTrad(ConstPTrait, PTrait.CodeTrait, '', PTrait.Livre);

                NodeNv3 := XmlElement(NodeNv2.FirstChild);
                while Assigned(NodeNv3) do
                  begin
                    case NodeNv3.NodeName of
                      ConstXmlDescription:
                        begin
                          PTrait.Libelle      := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                          Langue              := XmlAttribut(NodeNv3, ConstXmlLanguage);
                          PTraduction.Libelle := PTrait.Libelle;
                        end;
                      ConstXmlTraitOption:
                        begin
                          // Record local reutilise d'une option a l'autre : sans
                          // remise a zero, une option sans balise heriterait de
                          // la precedente (meme piege que les fonctions Cherche*).
                          PTraitOption.Livre       := Livre;
                          PTraitOption.CodeTrait   := PTrait.CodeTrait;
                          PTraitOption.Libelle     := '';
                          PTraitOption.ListeTalent := '';
                          PTraitOption.CodeOption  := XmlAttribut(NodeNv3, ConstXmlId);
                          PTraductionOption        := InitTrad(ConstPTraitOption, PTraitOption.CodeOption, '', PTraitOption.Livre);

                          Node := XmlElement(NodeNv3.FirstChild);
                          while Assigned(Node) do
                            begin
                              case Node.NodeName of
                                ConstXmlDescription:
                                  begin
                                    PTraitOption.Libelle      := RemoveQuotes(UTF8Encode(Node.TextContent));
                                    Langue                    := XmlAttribut(Node, ConstXmlLanguage);
                                    PTraductionOption.Libelle := PTraitOption.Libelle;
                                  end;
                                ConstXmlTalent:
                                  PTraitOption.ListeTalent := RemoveQuotes(UTF8Encode(Node.TextContent));
                              end;

                              Node := XmlElement(Node.NextSibling);
                            end;

                          if LangueDef = ConstAnglais then
                            begin
                              ListTraitOption.add(PTraitOption);
                              inc(NbTraitOption);
                            end;

                          AddTrad(PTraductionOption, Langue);
                        end;
                    end;

                    NodeNv3 := XmlElement(NodeNv3.NextSibling);
                  end;

                if LangueDef = ConstAnglais then
                  begin
                    ListTrait.add(PTrait);
                    inc(NbTrait);
                    Inc(LivreNbTrait);
                  end;

                AddTrad(PTraduction, Langue);
              end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCareerBonus(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:                      TDOMNode;
    NodeNv2:                      TDOMNode;
    NodeNv3:                      TDOMNode;
    Node:                         TDOMNode;
    PCareerBonus:                 StructureCareerBonus;
    PCareerBonusNiveau:           StructureCareerBonusNiveau;
    PCareerBonusModificateur:     StructureModificateur;
    TempCareerBonusModificateur:  TListModificateur;
    PCareerBonusSpecialRule:      StructureCareerBonusSpecialRule;
    TempCareerBonusSpecialRule:   TListCareerBonusSpecialRule;
    IndTempModif:                 Integer;
    PTraduction:                  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCareerBonus);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            if NodeNv2.NodeName = ConstXmlCareerBonus then
              begin
                PCareerBonus.Livre      := Livre;
                PCareerBonus.Libelle    := '';
                PCareerBonus.CodeMetier := '';
                PCareerBonus.CodeRace   := '';
                PCareerBonus.CodeBonus  := XmlAttribut(NodeNv2, ConstXmlId);
                PTraduction             := InitTrad(ConstPCareerBonus, PCareerBonus.CodeBonus, '', PCareerBonus.Livre);

                NodeNv3 := XmlElement(NodeNv2.FirstChild);
                while Assigned(NodeNv3) do
                  begin
                    case NodeNv3.NodeName of
                      ConstXmlDescription:
                        begin
                          PCareerBonus.Libelle := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                          Langue               := XmlAttribut(NodeNv3, ConstXmlLanguage);
                          PTraduction.Libelle  := PCareerBonus.Libelle;
                        end;
                      ConstXmlWork:
                        PCareerBonus.CodeMetier := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                      ConstXmlRace:
                        PCareerBonus.CodeRace   := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                      ConstXmlNiveau:
                        begin
                          // Record local reutilise d'un palier a l'autre : sans
                          // remise a zero, un palier sans balise heriterait du
                          // precedent (meme piege que les fonctions Cherche*).
                          PCareerBonusNiveau.Livre                 := Livre;
                          PCareerBonusNiveau.CodeBonus             := PCareerBonus.CodeBonus;
                          PCareerBonusNiveau.Niveau                := 0;
                          PCareerBonusNiveau.ListeCompetence       := '';
                          PCareerBonusNiveau.ListeTalent           := '';
                          PCareerBonusNiveau.NbChoixCompetence     := 0;
                          PCareerBonusNiveau.ValeurChoixCompetence := 0;
                          PCareerBonusNiveau.CodeNiveau      := XmlAttribut(NodeNv3, ConstXmlId);

                          // Modificateurs d'Attribut/Competence du palier (ex. Knight
                          // of the Inner Circle, +10 Fel/+10 WP) - CONTEXT.md 2.50
                          // etape 3. Accumules a part le temps de la boucle : <ModifyCarac>
                          // peut arriver avant <Order> dans le XML, et Niveau n'est connu
                          // qu'une fois la boucle terminee (meme raison que
                          // ListCareerBonusNiveau.add plus bas, deja differe apres la
                          // boucle).
                          // <ModifySkill> ajoute au 2.44/3d-3 (Knight, "+10 CC avec les
                          // lances" represente comme un bonus chiffre sur Melee (Cavalry))
                          // - meme mecanisme et meme raison de differer que ModifyCarac.
                          // <ModifyWeapon> ajoute le 07/09/2026, meme mecanisme, pour le
                          // meme palier Knight mais filtre par TYPE d'arme (name=) et
                          // FACULTATIVEMENT par competence (skill=). <ModifyCarac>,
                          // <ModifySkill> et <ModifyWeapon> alimentent tous trois
                          // ListCareerBonusModificateur - ModifySkill/ModifyWeapon depuis
                          // le 11/09/2026 (moteur generique, ChargeModificateur), ModifyCarac
                          // depuis le meme jour (migration ModifyCarac d'Attribut, ancienne
                          // ListCareerBonusAttributModif supprimee).
                          // <SpecialRule> ajoute le 08/09/2026, quatrieme pendant, pour
                          // le palier 4 ("Knight of the Inner Circle") de la quasi-
                          // totalite des Ordres de Chevalerie, qui n'a le plus souvent
                          // aucun equivalent chiffre - voir ChargeMetier,
                          // StructureCareerBonusSpecialRule.
                          TempCareerBonusModificateur    := TListModificateur.Create;
                          TempCareerBonusSpecialRule     := TListCareerBonusSpecialRule.Create;

                          Node := XmlElement(NodeNv3.FirstChild);
                          while Assigned(Node) do
                            begin
                              // Modificateurs numeriques : lecteur commun (e2a) ; Niveau est rempli apres la boucle.
                              if LitModificateurNoeud(Node, PCareerBonus.CodeBonus, PCareerBonusModificateur) then
                                TempCareerBonusModificateur.Add(PCareerBonusModificateur)
                              else
                              case Node.NodeName of
                                ConstXmlOrder:
                                  PCareerBonusNiveau.Niveau          := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                                ConstXmlCompetence:
                                  PCareerBonusNiveau.ListeCompetence := RemoveQuotes(UTF8Encode(Node.TextContent));
                                ConstXmlTalent:
                                  PCareerBonusNiveau.ListeTalent     := RemoveQuotes(UTF8Encode(Node.TextContent));
                                ConstXmlSpecialRule:
                                  begin
                                    PCareerBonusSpecialRule.CodeBonus := PCareerBonus.CodeBonus;
                                    PCareerBonusSpecialRule.Niveau    := 0;
                                    PCareerBonusSpecialRule.Libelle   := XmlAttribut(Node, ConstXmlData);
                                    PCareerBonusSpecialRule.Texte     := RemoveQuotes(UTF8Encode(Node.TextContent));
                                    TempCareerBonusSpecialRule.Add(PCareerBonusSpecialRule);
                                  end;
                                // <SkillChoice Count="N" Value="V"/> - choix parmi les
                                // competences raciales DU PERSONNAGE, pas une liste
                                // portee par le livre (ConstXmlSkillChoice,
                                // ChargeConstantes). Directement sur PCareerBonusNiveau,
                                // pas dans une liste temporaire : un seul choix possible
                                // par palier, contrairement aux modificateurs/regles
                                // speciales qui peuvent s'accumuler.
                                ConstXmlSkillChoice:
                                  begin
                                    PCareerBonusNiveau.NbChoixCompetence     := StrToIntDef(XmlAttribut(Node, ConstXmlSkillChoiceCount), 0);
                                    PCareerBonusNiveau.ValeurChoixCompetence := StrToIntDef(XmlAttribut(Node, ConstXmlSkillChoiceValue), 0);
                                  end;
                              end;

                              Node := XmlElement(Node.NextSibling);
                            end;

                          if LangueDef = ConstAnglais then
                            begin
                              ListCareerBonusNiveau.add(PCareerBonusNiveau);
                              inc(NbCareerBonusNiveau);
                              for IndTempModif := 0 to TempCareerBonusModificateur.Count - 1 do
                                begin
                                  PCareerBonusModificateur        := TempCareerBonusModificateur[IndTempModif];
                                  PCareerBonusModificateur.Niveau := PCareerBonusNiveau.Niveau;
                                  AjouteModificateurUnique(SourceModifCareerBonus, PCareerBonusModificateur);
                                  inc(NbCareerBonusModificateur);
                                end;
                              for IndTempModif := 0 to TempCareerBonusSpecialRule.Count - 1 do
                                begin
                                  PCareerBonusSpecialRule        := TempCareerBonusSpecialRule[IndTempModif];
                                  PCareerBonusSpecialRule.Niveau := PCareerBonusNiveau.Niveau;
                                  PCareerBonusSpecialRule.Livre  := Livre;
                                  ListCareerBonusSpecialRule.add(PCareerBonusSpecialRule);
                                  inc(NbCareerBonusSpecialRule);
                                end;
                            end;
                          TempCareerBonusModificateur.Free;
                          TempCareerBonusSpecialRule.Free;
                        end;
                    end;

                    NodeNv3 := XmlElement(NodeNv3.NextSibling);
                  end;

                if LangueDef = ConstAnglais then
                  begin
                    ListCareerBonus.add(PCareerBonus);
                    inc(NbCareerBonus);
                  end;

                AddTrad(PTraduction, Langue);
              end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCareerAdaptation(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:                 TDOMNode;
    NodeNv2:                 TDOMNode;
    NodeNv3:                 TDOMNode;
    Node:                    TDOMNode;
    PCareerAdaptation:       StructureCareerAdaptation;
    PCareerAdaptationLigne:  StructureCareerAdaptationLigne;
    NodeAdapt:               TDOMNode;
    IndTempModif:            Integer;
    TempAdaptationLignes:    TListCareerAdaptationLigne;
    NivAdapt:                Integer;
    PTraduction:             StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCareerAdaptation);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            if NodeNv2.NodeName = ConstXmlCareerAdaptation then
              begin
                PCareerAdaptation.Livre          := Livre;
                PCareerAdaptation.Libelle        := '';
                PCareerAdaptation.CodeMetier     := '';
                PCareerAdaptation.CodeRace       := '';
                PCareerAdaptation.Facultative    := false;
                PCareerAdaptation.Standing       := 0;
                PCareerAdaptation.CodeAdaptation := XmlAttribut(NodeNv2, ConstXmlId);
                PTraduction := InitTrad(ConstPAdaptation, PCareerAdaptation.CodeAdaptation, '', PCareerAdaptation.Livre);
                Langue      := LangueDef;

                NodeNv3 := XmlElement(NodeNv2.FirstChild);
                while Assigned(NodeNv3) do
                  begin
                    case NodeNv3.NodeName of
                      ConstXmlDescription:
                        begin
                          PCareerAdaptation.Libelle := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                          Langue                    := XmlAttribut(NodeNv3, ConstXmlLanguage);
                          PTraduction.Libelle       := PCareerAdaptation.Libelle;
                        end;
                      ConstXmlWork:
                        PCareerAdaptation.CodeMetier := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                      ConstXmlRace:
                        PCareerAdaptation.CodeRace   := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                      ConstXmlOptional:
                        PCareerAdaptation.Facultative := RemoveQuotes(UTF8Encode(NodeNv3.TextContent)) = '1';
                      ConstXmlStanding:
                        PCareerAdaptation.Standing   := StrToIntDef(RemoveQuotes(UTF8Encode(NodeNv3.TextContent)), 0);
                      ConstXmlNiveau:
                        begin
                          PCareerAdaptationLigne.Livre := Livre;
                          PCareerAdaptationLigne.CodeAdaptation := PCareerAdaptation.CodeAdaptation;
                          NivAdapt := 0;
                          // Le <Order> peut suivre les natures dans le XML : les
                          // lignes sont donc accumulees puis posees apres la boucle.
                          TempAdaptationLignes := TListCareerAdaptationLigne.Create;
                          Node := XmlElement(NodeNv3.FirstChild);
                          while Assigned(Node) do
                            begin
                              if Node.NodeName = ConstXmlOrder then
                                NivAdapt := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)), 0)
                              else if (Node.NodeName = ConstXmlCompetence) or (Node.NodeName = ConstXmlTalent)
                                   or (Node.NodeName = ConstXmlTrapping) then
                                begin
                                  PCareerAdaptationLigne.Nature  := Node.NodeName;
                                  PCareerAdaptationLigne.Retire  := '';
                                  PCareerAdaptationLigne.Ajoute  := '';
                                  NodeAdapt := XmlElement(Node.FirstChild);
                                  while Assigned(NodeAdapt) do
                                    begin
                                      if NodeAdapt.NodeName = ConstXmlRemove then
                                        PCareerAdaptationLigne.Retire := RemoveQuotes(UTF8Encode(NodeAdapt.TextContent))
                                      else if NodeAdapt.NodeName = ConstXmlAdd then
                                        PCareerAdaptationLigne.Ajoute := RemoveQuotes(UTF8Encode(NodeAdapt.TextContent));
                                      NodeAdapt := XmlElement(NodeAdapt.NextSibling);
                                    end;
                                  TempAdaptationLignes.Add(PCareerAdaptationLigne);
                                end;
                              Node := XmlElement(Node.NextSibling);
                            end;
                          if LangueDef = ConstAnglais then
                            for IndTempModif := 0 to TempAdaptationLignes.Count - 1 do
                              begin
                                PCareerAdaptationLigne        := TempAdaptationLignes[IndTempModif];
                                PCareerAdaptationLigne.Niveau := NivAdapt;
                                ListCareerAdaptationLigne.add(PCareerAdaptationLigne);
                                inc(NbCareerAdaptationLigne);
                              end;
                          TempAdaptationLignes.Free;
                        end;
                    end;
                    NodeNv3 := XmlElement(NodeNv3.NextSibling);
                  end;

                if LangueDef = ConstAnglais then
                  begin
                    ListCareerAdaptation.add(PCareerAdaptation);
                    inc(NbCareerAdaptation);
                  end;

                AddTrad(PTraduction, Langue);
              end;
            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCondition(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:           TDOMNode;
    NodeNv2:           TDOMNode;
    Node:              TDOMNode;
    PConditionDonnee:  StructureConditionDonnee;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCondition);
    if Assigned(NodeNv1) and (LangueDef = ConstAnglais) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            if (NodeNv2.NodeName = ConstXmlCondition) and Assigned(NodeNv2.Attributes.GetNamedItem(ConstXmlId)) then
              begin
                PConditionDonnee.Livre := Livre;
                PConditionDonnee.Code  := XmlAttribut(NodeNv2, ConstXmlId);
                PConditionDonnee.Genre := '';
                Node := XmlElement(NodeNv2.FirstChild);
                while Assigned(Node) do
                  begin
                    if Node.NodeName = ConstXmlConditionKind then
                      PConditionDonnee.Genre := RemoveQuotes(UTF8Encode(Node.TextContent));
                    Node := XmlElement(Node.NextSibling);
                  end;
                ListConditionDonnee.Add(PConditionDonnee);
              end;
            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCraftsmanship(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:                   TDOMNode;
    NodeNv2:                   TDOMNode;
    Node:                      TDOMNode;
    PArmeBonusTalent:          StructureArmeBonusTalent;
    PFabricationModificateur:  StructureModificateur;
    PArmureBonusTalent:        StructureArmureBonusTalent;
    PFabrication:              StructureFabrication;
    PTraduction:               StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCraftsmanship);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PFabrication.Livre           := Livre;
            PFabrication.CodeFabrication := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction                  := InitTrad(ConstPFabrication, PFabrication.CodeFabrication, '', PFabrication.Livre);
            PFabrication.Encombrement    := 0;
            PFabrication.Applique        := '';
            PFabrication.PorteeBonus     := 0;
            PFabrication.QualitesArme    := '';
            PFabrication.ArmeAlternative := '';
            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                // Modificateurs numeriques : lecteur commun, tous formats (e2a).
                if LitModificateurNoeud(Node, PFabrication.CodeFabrication, PFabricationModificateur) then
                  begin
                    if LangueDef = ConstAnglais then
                      begin
                        AjouteModificateurUnique(SourceModifFabrication, PFabricationModificateur);
                        inc(NbFabricationModificateur);
                      end;
                  end
                else
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                      PFabrication.Libelle     := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                   := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle      := PFabrication.Libelle;
                    end;
                  ConstXmlExplanation:
                    begin
                      PFabrication.Description := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                   := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Description  := PFabrication.Description;
                    end;
                  ConstXmlShort:
                    begin
                      PFabrication.Resume      := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                   := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Resume       := PFabrication.Resume;
                    end;
                  ConstXmlEncombrement:
                    PFabrication.Encombrement  := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                  ConstXmlMax:
                    PFabrication.Maximum       := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlFabPortee:
                    PFabrication.PorteeBonus   := StrToIntDef(RemoveQuotes(UTF8Encode(Node.TextContent)),0);
                  ConstXmlFabApplique:
                    PFabrication.Applique      := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlFabQualiteArme:
                    PFabrication.QualitesArme  := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlFabArmeAlternative:
                    PFabrication.ArmeAlternative := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlPositifNegatif:
                    PFabrication.TypeQualite   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlTalent:
                    begin
                      // Talent accorde par une fabrication (ex. objet magique
                      // Archives II "Carved of Rage" -> RULES-T0063 Frenzy), au cas
                      // par cas dans le XML - meme mecanisme que ConstXmlTalent sous
                      // <ArmureBonus>/<ArmeBonus>, reutilise tel quel : une fabrication
                      // se pose sur une arme OU une armure selon le choix du joueur
                      // (colonne Fabrication, winpersonnage.pas), donc alimente les
                      // DEUX listes de resolution avec le meme CodeFabrication. 25/09/2026.
                      PArmureBonusTalent.Livre           := Livre;
                      PArmureBonusTalent.CodeArmureBonus := PFabrication.CodeFabrication;
                      PArmureBonusTalent.CodeTalent      := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PArmeBonusTalent.Livre             := Livre;
                      PArmeBonusTalent.CodeArmeBonus     := PFabrication.CodeFabrication;
                      PArmeBonusTalent.CodeTalent        := RemoveQuotes(UTF8Encode(Node.TextContent));
                      if LangueDef = ConstAnglais then
                        begin
                          ListArmureBonusTalent.add(PArmureBonusTalent);
                          inc(NbArmureBonusTalent);
                          ListArmeBonusTalent.add(PArmeBonusTalent);
                          inc(NbArmeBonusTalent);
                        end;
                    end;
                end;
                Node := XmlElement(Node.NextSibling);
              end;
            if LangueDef = ConstAnglais then
              begin
                ListFabrication.add(PFabrication);
                inc(NbFabrication);
              end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSigneAstral(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:       TDOMNode;
    NodeNv2:       TDOMNode;
    NodeNv3:       TDOMNode;
    Node:          TDOMNode;
    PSigneAstral:  StructureSigneAstral;
    PTraduction:   StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSigneAstral);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PSigneAstral           := Default(StructureSigneAstral);
            PSigneAstral.Livre     := Livre;
            PSigneAstral.CodeSigne := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction            := InitTrad(ConstPSigneAstral, PSigneAstral.CodeSigne, '', PSigneAstral.Livre);
            Langue                 := LangueDef;
            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlSignePlage:
                    PSigneAstral.Plage        := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlDescription:
                    begin
                      PSigneAstral.Libelle      := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue                    := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle       := PSigneAstral.Libelle;
                    end;
                  ConstXmlSigneTitre:
                    begin
                      PSigneAstral.Titre        := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PTraduction.Titre         := PSigneAstral.Titre;
                    end;
                  ConstXmlSigneClassique:
                    PSigneAstral.NomClassique := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlSigneAscendant:
                    PSigneAstral.Ascendant    := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlSigneDates:
                    PSigneAstral.Dates        := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlSigneDieu:
                    PSigneAstral.Dieu         := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlSigneApparence:
                    begin
                      PSigneAstral.Apparence    := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PTraduction.Apparence     := PSigneAstral.Apparence;
                    end;
                  ConstXmlSignePersonnalite:
                    begin
                      PSigneAstral.Personnalite := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PTraduction.Personnalite  := PSigneAstral.Personnalite;
                    end;
                  ConstXmlSigneModificateur, ConstXmlTalent:
                    if LangueDef = ConstAnglais then
                      AjouteEffetSigneAstral(Livre, PSigneAstral.CodeSigne, '', Node);
                  ConstXmlSigneVariante:
                    begin
                      NodeNv3 := XmlElement(Node.FirstChild);
                      while Assigned(NodeNv3) do
                        begin
                          if LangueDef = ConstAnglais then
                            AjouteEffetSigneAstral(Livre, PSigneAstral.CodeSigne,
                              RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem('range').NodeValue)), NodeNv3);
                          NodeNv3 := XmlElement(NodeNv3.NextSibling);
                        end;
                    end;
                end;
                Node := XmlElement(Node.NextSibling);
              end;
            // Toggle .INI par livre (A FAIRE.txt "TOGGLE .INI PAR LIVRE",
            // CONTEXT.md 2.89, 22/09/2026) : si l option signes astraux est
            // desactivee pour ce livre, le signe n est jamais charge.
            if LangueDef = ConstAnglais then
              ListSigneAstralSource.Add(PSigneAstral);
            if (LangueDef = ConstAnglais) and not OptionDesactivee(Livre, ConstOptionStarSign) then
              begin
                ListSigneAstral.Add(PSigneAstral);
                Inc(NbSigneAstral);
              end;
            AddTrad(PTraduction, Langue);
            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataSpecieCareerChoix(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:                 TDOMNode;
    NodeNv2:                 TDOMNode;
    Node:                    TDOMNode;
    PMetierRaceChoixMetier:  StructureMetierRaceChoixMetier;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataSpecieCareerChoix);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PMetierRaceChoixMetier.Livre    := Livre;

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlRace:
                    PMetierRaceChoixMetier.CodeRace       := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlWork:
                    PMetierRaceChoixMetier.CodeMetier     := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlAlternative:
                    PMetierRaceChoixMetier.CodeSousMetier := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;
                Node := XmlElement(Node.NextSibling);
              end;
            if LangueDef = ConstAnglais then
              begin
                ListMetierRaceChoixMetier.add(PMetierRaceChoixMetier);
                inc(NbMetierRaceChoixMetier);
              end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCareerSpecie(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    Node:         TDOMNode;
    PRaceMetier:  StructureRaceMetier;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCareerSpecie);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            if NodeNv2.NodeName = ConstXmlEntry then
             begin
            PRaceMetier.Livre      := Livre;
            PRaceMetier.CodeRace   := '';
            PRaceMetier.CodeMetier := '';
            PRaceMetier.Chance     := '';

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlRace:
                    PRaceMetier.CodeRace   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlWork:
                    begin
                      PRaceMetier.CodeMetier := XmlAttribut(Node, ConstXmlData);
                      PRaceMetier.Chance     := RemoveQuotes(UTF8Encode(Node.TextContent));
                    end;
                end;
                Node := XmlElement(Node.NextSibling);
              end;
            if LangueDef = ConstAnglais then
              begin
                AjouteRaceMetierSource(FormeRaceMetierData, Livre, PRaceMetier.CodeRace, PRaceMetier.CodeMetier, PRaceMetier.Chance);
                ListRaceMetier.add(PRaceMetier);
                inc(NbRaceMetier);
              end;
             end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataRegle(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:      TDOMNode;
    NodeNv2:      TDOMNode;
    Node:         TDOMNode;
    PRegle:       StructureRegle;
    PTraduction:  StructureTraduction;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataRegle);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            if NodeNv2.NodeName = ConstXmlRegleJeu then
             begin
            PRegle.Livre     := Livre;
            PRegle.Libelle   := '';
            PRegle.ClasseRemplacee := '';
            PRegle.CodeRegle := XmlAttribut(NodeNv2, ConstXmlId);
            PTraduction      := InitTrad(ConstPRegle, PRegle.CodeRegle, '', PRegle.Livre);

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                      PRegle.Libelle      := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue              := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle := PRegle.Libelle;
                    end;
                  ConstXmlClass:
                    PRegle.ClasseRemplacee := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;

                Node := XmlElement(Node.NextSibling);
              end;

            // Toggle .INI par livre (A FAIRE.txt "TOGGLE .INI PAR LIVRE",
            // CONTEXT.md 2.89, 22/09/2026) : si l option carriere alternative
            // est desactivee pour ce livre, la regle n est jamais chargee (la
            // table de tirage associee, ci-dessous, reste alors orpheline mais
            // inoffensive - rien ne la referencera plus).
            if LangueDef = ConstAnglais then
              ListRegleSource.add(PRegle);
            if (LangueDef = ConstAnglais) and not OptionDesactivee(Livre, ConstOptionCareerAlt) then
              begin
                ListRegle.add(PRegle);
                inc(NbRegle);
              end;

            AddTrad(PTraduction, Langue);
             end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataRegleMetier(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:       TDOMNode;
    NodeNv2:       TDOMNode;
    Node:          TDOMNode;
    PRegleMetier:  StructureRegleMetier;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataRegleMetier);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            // Ne traiter que les vrais <Entry> : un commentaire ou un noeud texte
            // entre deux entrées est aussi un enfant, et sans cette garde il
            // rejouerait les valeurs de l'entrée précédente (doublon silencieux).
            if NodeNv2.NodeName = ConstXmlEntry then
             begin
            PRegleMetier.Livre      := Livre;
            PRegleMetier.CodeRegle  := '';
            PRegleMetier.CodeRace   := '';
            PRegleMetier.CodeMetier := '';
            PRegleMetier.Chance     := '';

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlRegleJeu:
                    PRegleMetier.CodeRegle  := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlRace:
                    PRegleMetier.CodeRace   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlWork:
                    begin
                      PRegleMetier.CodeMetier := XmlAttribut(Node, ConstXmlData);
                      PRegleMetier.Chance     := RemoveQuotes(UTF8Encode(Node.TextContent));
                    end;
                end;
                Node := XmlElement(Node.NextSibling);
              end;

            // Meme toggle que la regle elle-meme ci-dessus (ConstOptionCareerAlt) :
            // pas la peine de charger une table de tirage rattachee a une regle
            // desactivee.
            if (LangueDef = ConstAnglais) and not OptionDesactivee(Livre, ConstOptionCareerAlt) then
              begin
                ListRegleMetier.add(PRegleMetier);
                inc(NbRegleMetier);
              end;
             end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCareerSubChoice(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:            TDOMNode;
    NodeNv2:            TDOMNode;
    Node:               TDOMNode;
    PMetierSousMetier:  StructureMetierSousMetier;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCareerSubChoice);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PMetierSousMetier.Livre    := Livre;

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                case Node.NodeName of
                  ConstXmlWork:
                    PMetierSousMetier.CodeMetier       := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlAlternative:
                    begin
                      PMetierSousMetier.CodeSousMetier := XmlAttribut(Node, ConstXmlData);
                      PMetierSousMetier.Chance         := RemoveQuotes(UTF8Encode(Node.TextContent));
                    end;
                end;
                Node := XmlElement(Node.NextSibling);
              end;
            if LangueDef = ConstAnglais then
              begin
                ListMetierSousMetier.add(PMetierSousMetier);
                inc(NbMetierSousMetier);
              end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataPhysicalCorruption(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:                  TDOMNode;
    NodeNv2:                  TDOMNode;
    PRaceCorruptionCreation:  StructureRaceCorruptionCreation;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataPhysicalCorruption);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PRaceCorruptionCreation.Livre          := Livre;
            PRaceCorruptionCreation.CodeRace       := XmlAttribut(NodeNv2, ConstXmlData);
            PRaceCorruptionCreation.TypeCorruption := CorruptionPhysique;
            PRaceCorruptionCreation.Chance         := RemoveQuotes(UTF8Encode(NodeNv2.TextContent));

             if LangueDef = ConstAnglais then
               begin
                ListRaceCorruptionCreation.add(PRaceCorruptionCreation);
                inc(nbRaceCorruptionCreation);
               end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataMentalCorruption(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:                  TDOMNode;
    NodeNv2:                  TDOMNode;
    PRaceCorruptionCreation:  StructureRaceCorruptionCreation;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataMentalCorruption);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PRaceCorruptionCreation.Livre          := Livre;
            PRaceCorruptionCreation.CodeRace       := XmlAttribut(NodeNv2, ConstXmlData);
            PRaceCorruptionCreation.TypeCorruption := CorruptionMentale;
            PRaceCorruptionCreation.Chance         := RemoveQuotes(UTF8Encode(NodeNv2.TextContent));

             if LangueDef = ConstAnglais then
               begin
                ListRaceCorruptionCreation.add(PRaceCorruptionCreation);
                inc(nbRaceCorruptionCreation);
               end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCorruptionTablePhys(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:                             TDOMNode;
    NodeNv2:                             TDOMNode;
    Node:                                TDOMNode;
    PTraduction:                         StructureTraduction;
    PCorruptionTable:                    StructureCorruptionTable;
    PCorruptionModificateur:             StructureModificateur;
    PCorruptionCompetenceAttributModif:  StructureCorruptionCompetenceAttributModif;
    PCorruptionTalent:                   StructureCorruptionTalent;
    PCorruptionEquipement:               StructureCorruptionEquipement;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCorruptionTablePhys);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PCorruptionTable.Livre          := Livre;
            PCorruptionTable.TypeCorruption := CorruptionPhysique;
            PCorruptionTable.Code           := XmlAttribut(NodeNv2, ConstXmlData);

            // Itère les enfants (au lieu de FindNode) pour pouvoir accueillir, en plus de
            // Libelle/Effet, zéro ou plusieurs <ModifyCarac name="...">/<ModifySkill name="...">
            // optionnels (effets à delta pur, CONTEXT.md §2.7 étape 8) - même mécanisme que
            // <Modifier name="..."> sous <BonusMalus> pour les armures.
            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                // Modificateurs numeriques : lecteur commun, tous formats (e2a).
                if LitModificateurNoeud(Node, PCorruptionTable.Code, PCorruptionModificateur) then
                  begin
                    if LangueDef = ConstAnglais then
                      begin
                        AjouteModificateurUnique(SourceModifMutation, PCorruptionModificateur);
                        inc(NbCorruptionModificateur);
                      end;
                  end
                else
                case Node.NodeName of
                  ConstXmlDescription:
                    PCorruptionTable.Libelle := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlExplanation:
                    PCorruptionTable.Effet   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlModifieCompetenceAttribut:
                    begin
                      PCorruptionCompetenceAttributModif.Livre          := Livre;
                      PCorruptionCompetenceAttributModif.CodeCorruption := PCorruptionTable.Code;
                      PCorruptionCompetenceAttributModif.CodeAttribut   := XmlAttribut(Node, ConstXmlData);
                      PCorruptionCompetenceAttributModif.Valeur         := StrToInt(RemoveQuotes(UTF8Encode(Node.TextContent)));
                      if LangueDef = ConstAnglais then
                         begin
                          ListCorruptionCompetenceAttributModif.add(PCorruptionCompetenceAttributModif);
                          inc(NbCorruptionCompetenceAttributModif);
                         end;
                    end;
                  ConstXmlTalent:
                    begin
                      // Talent accorde par la mutation (ex. Fleshy Tentacle -> Tentacles),
                      // cas par cas dans le XML - CONTEXT.md, chantier "traits de creature".
                      PCorruptionTalent.Livre          := Livre;
                      PCorruptionTalent.CodeCorruption := PCorruptionTable.Code;
                      PCorruptionTalent.CodeTalent     := RemoveQuotes(UTF8Encode(Node.TextContent));
                      if LangueDef = ConstAnglais then
                         begin
                          ListCorruptionTalent.add(PCorruptionTalent);
                          inc(NbCorruptionTalent);
                         end;
                    end;
                  ConstXmlArme, ConstXmlArmure:
                    begin
                      // Arme ou armure accordee par la mutation, cas par cas dans le XML -
                      // meme chantier que ConstXmlTalent juste au-dessus.
                      PCorruptionEquipement.Livre          := Livre;
                      PCorruptionEquipement.CodeCorruption := PCorruptionTable.Code;
                      PCorruptionEquipement.CodeEquipement := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PCorruptionEquipement.EstArme        := Node.NodeName = ConstXmlArme;
                      if LangueDef = ConstAnglais then
                         begin
                          ListCorruptionEquipement.add(PCorruptionEquipement);
                          inc(NbCorruptionEquipement);
                         end;
                    end;
                end;
                Node := XmlElement(Node.NextSibling);
              end;

            PTraduction              := InitTrad(ConstPCorruptionTable, PCorruptionTable.Code, '', PCorruptionTable.Livre);
            PTraduction.Libelle      := PCorruptionTable.Libelle;
            PTraduction.Description  := PCorruptionTable.Effet;

             if LangueDef = ConstAnglais then
               begin
                ListCorruptionTable.add(PCorruptionTable);
                inc(nbCorruptionTable);
               end;

            AddTrad(PTraduction, LangueDef);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCorruptionTableMent(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:                             TDOMNode;
    NodeNv2:                             TDOMNode;
    Node:                                TDOMNode;
    PTraduction:                         StructureTraduction;
    PCorruptionTable:                    StructureCorruptionTable;
    PCorruptionModificateur:             StructureModificateur;
    PCorruptionCompetenceAttributModif:  StructureCorruptionCompetenceAttributModif;
    PCorruptionTalent:                   StructureCorruptionTalent;
    PCorruptionEquipement:               StructureCorruptionEquipement;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCorruptionTableMent);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PCorruptionTable.Livre          := Livre;
            PCorruptionTable.TypeCorruption := CorruptionMentale;
            PCorruptionTable.Code           := XmlAttribut(NodeNv2, ConstXmlData);

            // Même itération que la table Physique ci-dessus (ModifyCarac/ModifySkill optionnels).
            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                // Modificateurs numeriques : lecteur commun, tous formats (e2a).
                if LitModificateurNoeud(Node, PCorruptionTable.Code, PCorruptionModificateur) then
                  begin
                    if LangueDef = ConstAnglais then
                      begin
                        AjouteModificateurUnique(SourceModifMutation, PCorruptionModificateur);
                        inc(NbCorruptionModificateur);
                      end;
                  end
                else
                case Node.NodeName of
                  ConstXmlDescription:
                    PCorruptionTable.Libelle := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlExplanation:
                    PCorruptionTable.Effet   := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlModifieCompetenceAttribut:
                    begin
                      PCorruptionCompetenceAttributModif.Livre          := Livre;
                      PCorruptionCompetenceAttributModif.CodeCorruption := PCorruptionTable.Code;
                      PCorruptionCompetenceAttributModif.CodeAttribut   := XmlAttribut(Node, ConstXmlData);
                      PCorruptionCompetenceAttributModif.Valeur         := StrToInt(RemoveQuotes(UTF8Encode(Node.TextContent)));
                      if LangueDef = ConstAnglais then
                         begin
                          ListCorruptionCompetenceAttributModif.add(PCorruptionCompetenceAttributModif);
                          inc(NbCorruptionCompetenceAttributModif);
                         end;
                    end;
                  ConstXmlTalent:
                    begin
                      PCorruptionTalent.Livre          := Livre;
                      PCorruptionTalent.CodeCorruption := PCorruptionTable.Code;
                      PCorruptionTalent.CodeTalent     := RemoveQuotes(UTF8Encode(Node.TextContent));
                      if LangueDef = ConstAnglais then
                         begin
                          ListCorruptionTalent.add(PCorruptionTalent);
                          inc(NbCorruptionTalent);
                         end;
                    end;
                  ConstXmlArme, ConstXmlArmure:
                    begin
                      PCorruptionEquipement.Livre          := Livre;
                      PCorruptionEquipement.CodeCorruption := PCorruptionTable.Code;
                      PCorruptionEquipement.CodeEquipement := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PCorruptionEquipement.EstArme        := Node.NodeName = ConstXmlArme;
                      if LangueDef = ConstAnglais then
                         begin
                          ListCorruptionEquipement.add(PCorruptionEquipement);
                          inc(NbCorruptionEquipement);
                         end;
                    end;
                end;
                Node := XmlElement(Node.NextSibling);
              end;

            PTraduction              := InitTrad(ConstPCorruptionTable, PCorruptionTable.Code, '', PCorruptionTable.Livre);
            PTraduction.Libelle      := PCorruptionTable.Libelle;
            PTraduction.Description  := PCorruptionTable.Effet;

             if LangueDef = ConstAnglais then
               begin
                ListCorruptionTable.add(PCorruptionTable);
                inc(nbCorruptionTable);
               end;

            AddTrad(PTraduction, LangueDef);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataDisease(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:               TDOMNode;
    NodeNv2:               TDOMNode;
    Node:                  TDOMNode;
    PTraduction:           StructureTraduction;
    PDisease:              StructureDisease;
    PDiseaseModificateur:  StructureModificateur;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataDisease);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PDisease.Livre := Livre;
            PDisease.Code  := XmlAttribut(NodeNv2, ConstXmlData);
            PDisease.Libelle     := '';
            PDisease.Contraction := '';
            PDisease.Incubation  := '';
            PDisease.Duration    := '';
            PDisease.Symptoms    := '';

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                // Modificateurs numeriques : lecteur commun, tous formats (e2a).
                if LitModificateurNoeud(Node, PDisease.Code, PDiseaseModificateur) then
                  begin
                    if LangueDef = ConstAnglais then
                      begin
                        AjouteModificateurUnique(SourceModifMaladie, PDiseaseModificateur);
                        inc(NbDiseaseModificateur);
                      end;
                  end
                else
                case Node.NodeName of
                  ConstXmlDescription: PDisease.Libelle     := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlContraction: PDisease.Contraction := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlIncubation:  PDisease.Incubation  := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlDuration:    PDisease.Duration    := RemoveQuotes(UTF8Encode(Node.TextContent));
                  ConstXmlSymptoms:    PDisease.Symptoms    := RemoveQuotes(UTF8Encode(Node.TextContent));
                end;
                Node := XmlElement(Node.NextSibling);
              end;

            PTraduction              := InitTrad(ConstPDisease, PDisease.Code, '', PDisease.Livre);
            PTraduction.Libelle      := PDisease.Libelle;
            PTraduction.Description  := PDisease.Symptoms;
            PTraduction.Contraction  := PDisease.Contraction;
            PTraduction.Incubation   := PDisease.Incubation;
            PTraduction.Duration     := PDisease.Duration;

            if LangueDef = ConstAnglais then
              begin
                ListDisease.add(PDisease);
                inc(nbDisease);
              end;

            AddTrad(PTraduction, LangueDef);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataClassItem(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    QuantiteAttr:        String;
    NodeNv1:             TDOMNode;
    NodeNv2:             TDOMNode;
    NodeNv3:             TDOMNode;
    Node:                TDOMNode;
    PClassEquipement:    StructureClassEquipement;
    CodeClasseCourante:  String;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataClassItem);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            CodeClasseCourante := XmlAttribut(NodeNv2, ConstXmlData);
            NodeNv3 := XmlElement(NodeNv2.FirstChild);
            while Assigned(NodeNv3) do
              begin
                if NodeNv3.NodeName = ConstXmlSousChapitreEquipement then
                  begin
                    Node := XmlElement(NodeNv3.FirstChild);
                    while Assigned(Node) do
                      begin
                        if Node.NodeName = ConstXmlEquipement then
                          begin
                            PClassEquipement.Livre          := Livre;
                            PClassEquipement.CodeClasse     := CodeClasseCourante;
                            PClassEquipement.Equipement     := XmlAttribut(Node, ConstXmlData);
                            PClassEquipement.Quantite       := 1;
                            PClassEquipement.QuantiteListe  := '';
                            PClassEquipement.Action         := '';
                            PClassEquipement.Cible          := '';
                            if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite)) then
                              begin
                                QuantiteAttr := XmlAttributBrut(Node, ConstXmlEquipementQuantite);
                                if Pos(SeparateurMulti, QuantiteAttr) > 0 then
                                  PClassEquipement.QuantiteListe := QuantiteAttr
                                else
                                  PClassEquipement.Quantite      := StrToIntDef(QuantiteAttr, 1);
                              end;

                            if LangueDef = ConstAnglais then
                              begin
                                PClassEquipement.TypeEquipement := GetTypeMetierEquipement(PClassEquipement.Equipement);
                                ListClassEquipement.add(PClassEquipement);
                                inc(NbClassEquipement);
                              end;
                          end;
                        Node := XmlElement(Node.NextSibling);
                      end;
                  end
                else if (NodeNv3.NodeName = ConstXmlRemove) or (NodeNv3.NodeName = ConstXmlReplace) then
                  begin
                    // Retire ou remplace un objet de la classe (meme vocabulaire que
                    // DATA_CAREER_ADAPTATION) : <Remove>"code"</Remove> ou
                    // <Replace from="code" quantite="n">"nouveau"</Replace>. Les actions
                    // suivent les ajouts du meme livre dans la liste.
                    PClassEquipement.Livre          := Livre;
                    PClassEquipement.CodeClasse     := CodeClasseCourante;
                    PClassEquipement.Quantite       := 0;
                    PClassEquipement.QuantiteListe  := '';
                    PClassEquipement.TypeEquipement := '';
                    if NodeNv3.NodeName = ConstXmlRemove then
                      begin
                        PClassEquipement.Action     := 'REMOVE';
                        PClassEquipement.Cible      := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                        PClassEquipement.Equipement := '';
                      end
                    else
                      begin
                        PClassEquipement.Action     := 'REPLACE';
                        PClassEquipement.Cible      := '';
                        if Assigned(NodeNv3.Attributes.GetNamedItem(ConstXmlFrom)) then
                          PClassEquipement.Cible    := XmlAttributBrut(NodeNv3, ConstXmlFrom);
                        PClassEquipement.Equipement := RemoveQuotes(UTF8Encode(NodeNv3.TextContent));
                        PClassEquipement.TypeEquipement := GetTypeMetierEquipement(PClassEquipement.Equipement);
                        if Assigned(NodeNv3.Attributes.GetNamedItem(ConstXmlEquipementQuantite)) then
                          begin
                            QuantiteAttr := XmlAttributBrut(NodeNv3, ConstXmlEquipementQuantite);
                            if Pos(SeparateurMulti, QuantiteAttr) > 0 then
                              PClassEquipement.QuantiteListe := QuantiteAttr
                            else
                              PClassEquipement.Quantite      := StrToIntDef(QuantiteAttr, 0);
                          end;
                      end;
                    if LangueDef = ConstAnglais then
                      begin
                        ListClassEquipement.add(PClassEquipement);
                        inc(NbClassEquipement);
                      end;
                  end;
                NodeNv3 := XmlElement(NodeNv3.NextSibling);
              end;
            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCorruptionPhysChance(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:            TDOMNode;
    NodeNv2:            TDOMNode;
    PCorruptionChance:  StructureCorruptionChance;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCorruptionPhysChance);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PCorruptionChance.Livre          := Livre;
            PCorruptionChance.TypeCorruption := CorruptionPhysique;
            PCorruptionChance.Chance         := XmlAttribut(NodeNv2, ConstXmlData);
            PCorruptionChance.Code           := RemoveQuotes(UTF8Encode(NodeNv2.TextContent));

             if LangueDef = ConstAnglais then
               begin
                ListCorruptionChance.add(PCorruptionChance);
                inc(nbCorruptionChance);
               end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataCorruptionMentChance(BookNode: TDOMNode; Livre, LangueDef: String);
  var
    NodeNv1:            TDOMNode;
    NodeNv2:            TDOMNode;
    PCorruptionChance:  StructureCorruptionChance;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataCorruptionMentChance);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PCorruptionChance.Livre          := Livre;
            PCorruptionChance.TypeCorruption := CorruptionMentale;
            PCorruptionChance.Chance         := XmlAttribut(NodeNv2, ConstXmlData);
            PCorruptionChance.Code           := RemoveQuotes(UTF8Encode(NodeNv2.TextContent));

             if LangueDef = ConstAnglais then
               begin
                ListCorruptionChance.add(PCorruptionChance);
                inc(nbCorruptionChance);
               end;

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure LitDataAffliction(BookNode: TDOMNode; Livre, LangueDef: String; var Langue: String);
  var
    NodeNv1:                             TDOMNode;
    NodeNv2:                             TDOMNode;
    Node:                                TDOMNode;
    PTraduction:                         StructureTraduction;
    PAffliction:                         StructureAffliction;
    PAfflictionModificateur:             StructureModificateur;
    PAfflictionCompetenceAttributModif:  StructureAfflictionCompetenceAttributModif;
  begin
    NodeNv1 := BookNode.FindNode(ConstXmlDataAffliction);
    if Assigned(NodeNv1) then
      begin
        NodeNv2 := XmlElement(NodeNv1.FirstChild);
        While Assigned(NodeNv2) do
          begin
            PAffliction.Livre   := Livre;
            PAffliction.Code    := XmlAttribut(NodeNv2, ConstXmlData);
            PAffliction.Libelle := '';
            PAffliction.Effet   := '';
            PTraduction         := InitTrad(ConstPAffliction, PAffliction.Code, '', PAffliction.Livre);
            Langue              := LangueDef;

            Node := XmlElement(NodeNv2.FirstChild);
            while Assigned(Node) do
              begin
                // Modificateurs numeriques : lecteur commun, tous formats (e2a).
                if LitModificateurNoeud(Node, PAffliction.Code, PAfflictionModificateur) then
                  begin
                    if LangueDef = ConstAnglais then
                      begin
                        AjouteModificateurUnique(SourceModifAffliction, PAfflictionModificateur);
                        inc(NbAfflictionModificateur);
                      end;
                  end
                else
                case Node.NodeName of
                  ConstXmlDescription:
                    begin
                      PAffliction.Libelle := RemoveQuotes(UTF8Encode(Node.TextContent));
                      Langue              := XmlAttribut(Node, ConstXmlLanguage);
                      PTraduction.Libelle := PAffliction.Libelle;
                    end;
                  ConstXmlExplanation:
                    begin
                      PAffliction.Effet       := RemoveQuotes(UTF8Encode(Node.TextContent));
                      PTraduction.Description := PAffliction.Effet;
                    end;
                  // <ModifySkillAttribut name="..."> optionnel (malus/bonus de Test
                  // portant sur TOUTES les competences d'un attribut de rattachement,
                  // ex. Disfigurement/Stench "-10 to all Fellowship Tests") - meme
                  // principe que le pendant Mutation, liste dediee
                  // ListAfflictionCompetenceAttributModif. Ajout du 27/09/2026, a la
                  // demande de Nono.
                  ConstXmlModifieCompetenceAttribut:
                    begin
                      PAfflictionCompetenceAttributModif.Livre        := Livre;
                      PAfflictionCompetenceAttributModif.CodeSource   := PAffliction.Code;
                      PAfflictionCompetenceAttributModif.CodeAttribut := XmlAttribut(Node, ConstXmlData);
                      PAfflictionCompetenceAttributModif.Valeur       := StrToInt(RemoveQuotes(UTF8Encode(Node.TextContent)));
                      if LangueDef = ConstAnglais then
                         begin
                          ListAfflictionCompetenceAttributModif.add(PAfflictionCompetenceAttributModif);
                          inc(NbAfflictionCompetenceAttributModif);
                         end;
                    end;
                end;
                Node := XmlElement(Node.NextSibling);
              end;

            if LangueDef = ConstAnglais then
              begin
                ListAffliction.add(PAffliction);
                inc(nbAffliction);
              end;

            AddTrad(PTraduction, Langue);

            NodeNv2 := XmlElement(NodeNv2.NextSibling);
          end;
      end;
  end;

Procedure XmlImport(FileName: String; OnlyPrimary: Boolean; CheminComplet: String = '');
  var
    XMLDoc:                   TXMLDocument;
    BookNode:                 TDOMNode;
    Livre:                    String;
    CodeLivre:                String;
    NodeCode:                 TDOMNode;
    Node:                     TDOMNode;
    PLivre:                   StructureLivre;
    Langue:                   String;
    LangueDef:                String;
    Version:                  String;
    Officiel:                 Integer;
    Complet:                  Integer = 1;
    Disclaimer:               String = '';
  begin
    LivreNbMetier := 0;
    LivreNbRace   := 0;
    LivreNbCompetence := 0;
    LivreNbTalent     := 0;
    LivreNbArme       := 0;
    LivreNbArmure     := 0;
    LivreNbTrapping   := 0;
    LivreNbSort       := 0;
    LivreNbTrait      := 0;
    XMLDoc   := TXMLDocument.Create;
    try
      // CheminComplet permet de lire un fichier hors de ConstCheminLivre (dossier de
      // l'edition active) - cas de INTERFACE.Xml/INTERFACE_FRANCAIS.Xml, poses directement
      // sous DATABASE\ pour ne pas etre dupliques entre WFRP4\ et WFRP5\ (13/09/2026,
      // CONTEXT.md §2.70). Vide (defaut) : comportement inchange pour tous les autres appels.
      if CheminComplet <> '' then
        ReadXMLFile(XMLDoc, CheminComplet)
      else
        ReadXMLFile(XMLDoc, GetCurrentDir + ConstCheminLivre + FileName + '.xml');
      BookNode := XMLDoc.DocumentElement;
      if Assigned(BookNode) and (BookNode.NodeName = ConstXmlDataBook) then
        Begin
          LitPagesFiches(BookNode);
          Livre     := XmlTexte(BookNode, ConstXmlLibelleLivre);
          LivreImportEnCours := Livre;
          NodeCode  := BookNode.FindNode(ConstXmlCodeLivre);
          if Assigned(NodeCode) then
            CodeLivre := XmlTexte(BookNode, ConstXmlCodeLivre);
          NodeCode  := BookNode.FindNode(ConstXmlVersionLivre);
          if Assigned(NodeCode) then
            Version := XmlTexte(BookNode, ConstXmlVersionLivre);
          NodeCode  := BookNode.FindNode(ConstXmlOfficielLivre);
          if Assigned(NodeCode) then
            Officiel:= StrToInt(XmlTexte(BookNode, ConstXmlOfficielLivre));
          NodeCode  := BookNode.FindNode(ConstXmlCompletLivre);
          if Assigned(NodeCode) then
            Complet := StrToInt(XmlTexte(BookNode, ConstXmlCompletLivre));
          NodeCode  := BookNode.FindNode(ConstXmlDisclaimerLivre);
          if Assigned(NodeCode) then
            Disclaimer := XmlTexte(BookNode, ConstXmlDisclaimerLivre);
          Node      := BookNode.FindNode(ConstXmlLanguage);
          LangueDef := RemoveQuotes(UTF8Encode(Node.TextContent));

          PLIvre.CodeLivre:= '';
          PLivre := ChercheLivreLibelle(Livre);
          if PLivre.CodeLivre = '' then
            begin
              PLivre.CodeLivre := CodeLivre;
              PLivre.Libelle   := Livre;
              PLivre.Version   := Version;
              PLivre.Officiel  := Officiel;
              PLivre.Complet   := Complet;
              PLivre.Disclaimer:= Disclaimer;
              ListLivre.add(PLivre);
              inc(NbLivre);
            end;
          if OnlyPrimary then
            begin
              // Attribut
              LitDataAttribut(BookNode, Livre, LangueDef, Langue);

              // AttributAugmentation
              LitDataAttributCost(BookNode, Livre, LangueDef);

              // CompetenceAugmentation
              LitDataSkillCost(BookNode, Livre, LangueDef);

              // Texte
              LitDataLabel(BookNode, Livre, LangueDef, Langue);
            end;

         if Not OnlyPrimary then
            begin
              // Compétences
              LitDataSkill(BookNode, Livre, LangueDef, Langue);

              // Compétences spécialisée
              LitDataSkillSpe(BookNode, Livre, LangueDef, Langue);

              // Talent
              LitDataTalent(BookNode, Livre, LangueDef, Langue);

              // talents spécialisée
              LitDataTalentSpe(BookNode, Livre, LangueDef, Langue);

              // Talent Création
              LitDataRandomTalent(BookNode, Livre, LangueDef);

              // Espece (RACE générique regroupant plusieurs ethnies - voir ChargeEspece.pas
              // pour le vocabulaire : ici <Race>, alors que <Specie> plus bas = ethnie)
              LitDataEspece(BookNode, Livre, LangueDef, Langue);

              // Nation (bloc DATA_NATION : regroupement POLITIQUE des ethnies, distinct
              // de DATA_RACE juste au-dessus qui est biologique. CONTEXT.md 2.51.)
              LitDataNation(BookNode, Livre, LangueDef, Langue);

              // Race
              LitDataSpecie(BookNode, Livre, LangueDef, Langue);

              // Race au hasard
              LitDataSpecieCreation(BookNode, Livre, LangueDef);

              // Métier
              LitDataCareer(BookNode, Livre, LangueDef, Langue);

              // Armes
              LitDataWeapon(BookNode, Livre, LangueDef, Langue);

              // Regles optionnelles du livre (toggle .INI, A FAIRE.txt "TOGGLE .INI PAR
              // LIVRE", CONTEXT.md 2.89, 22/09/2026) - toujours chargees (definitions),
              // seul leur EFFET (ci-dessus pour Quick Armour) est conditionne au .INI.
              LitDataOptionRule(BookNode, Livre, LangueDef);

              // Armures
              LitDataArmor(BookNode, Livre, LangueDef, Langue);

              // Acces aux sorts par talent - bloc ADDITIF, voir CONTEXT.md 2.39.
              // N'importe quel livre peut porter des lignes pour des sorts d'un AUTRE
              // livre : c'est tout l'objet du bloc. Rien n'est ecrase, TalentsDuSort
              // (ChargeSort) concatene ces lignes au champ <Talent> du sort lui-meme.
              LitDataSpellTalent(BookNode, Livre, LangueDef);

              // Traits d'ethnie - bloc de LIVRE, voir CONTEXT.md 2.41. Un Trait porte
              // N Options, chaque Option porte une liste de talents separee par des
              // virgules ou les formes A/B et RULES-T* restent valables.
              LitDataSpecieTrait(BookNode, Livre, LangueDef, Langue);

              // Appartenances greffees sur une carriere - bloc de LIVRE, purement
              // ADDITIF, voir CONTEXT.md 2.44. Un CareerBonus porte N paliers ; chaque
              // palier porte son numero de niveau et deux listes separees par des
              // virgules ou la forme A/B reste valable.
              LitDataCareerBonus(BookNode, Livre, LangueDef, Langue);

              // Adaptations de carriere (Adapting Careers, High Elf Player's Guide p.60-62) -
              // bloc de LIVRE, additif, comme DATA_CAREER_BONUS. Chaque <Level> porte son
              // <Order> et, par nature (Skill/Talent/Trapping), un <Remove> et/ou un <Add>.
              LitDataCareerAdaptation(BookNode, Livre, LangueDef, Langue);

              // Conditions declarees (DATA_CONDITION) : gardees pour l'export seulement
              LitDataCondition(BookNode, Livre, LangueDef);

              // Fabrication
              LitDataCraftsmanship(BookNode, Livre, LangueDef, Langue);

              // Signes astraux (Archives of the Empire II)
              LitDataSigneAstral(BookNode, Livre, LangueDef, Langue);

              // Metier choix race
              LitDataSpecieCareerChoix(BookNode, Livre, LangueDef);

              // Metier choix race direct (ajout d'une race à un métier existant, ou
              // inversement, sans passer par <Specie>/<Career> - indépendant de l'ordre
              // de chargement des livres, comme Metier choix race ci-dessus)
              LitDataCareerSpecie(BookNode, Livre, LangueDef);

              // Regles de jeu optionnelles apportées par le livre (voir ChargeRegle.pas)
              LitDataRegle(BookNode, Livre, LangueDef, Langue);

              // Table de tirage des métiers propre à une règle. CodeRace y désigne
              // indifféremment une ETHNIE ou une RACE (résolution à l'usage, pas au
              // chargement : l'ordre de lecture des livres n'est pas garanti).
              LitDataRegleMetier(BookNode, Livre, LangueDef);

              // Metier Sous Métier
              LitDataCareerSubChoice(BookNode, Livre, LangueDef);

              // Race Corruption Physique
              LitDataPhysicalCorruption(BookNode, Livre, LangueDef);

              // Race Corruption Mentale
              LitDataMentalCorruption(BookNode, Livre, LangueDef);

              // Catalogue de mutation Physique (Physical Corruption Table, CONTEXT.md §2.7).
              // Balises <Description language="X">/<Explanation language="X"> (renommées le
              // 17/08/2026 depuis <Libelle>/<Effet>, à la demande de Nono, pour la même
              // convention que les autres chapitres - Attribut/Compétence/Talent/etc.) restent
              // lues dans les champs Pascal .Libelle/.Effet existants (noms internes conservés,
              // choix de Nono). L'attribut language= n'est pas lu (toujours redondant avec le
              // <language> de tête du livre - LangueDef - même s'il est maintenant présent dans
              // le XML pour la cohérence visuelle avec les autres chapitres). Code = code stable
              // du catalogue (ex. "RULES-CORPHY_001"), décorrélé de la plage D100 - voir
              // DATA_CORRUPTION_PHYSICAL_CHANCE/DATA_CORRUPTION_MENTAL_CHANCE plus bas pour le
              // tirage (conception revue avec Nono le 17/08/2026).
              LitDataCorruptionTablePhys(BookNode, Livre, LangueDef);

              // Catalogue de mutation Mentale (Mental Corruption Table, CONTEXT.md §2.7)
              LitDataCorruptionTableMent(BookNode, Livre, LangueDef);

              // Catalogue des maladies (The Litany of Pestilence, Rulebook p.186-188), audit du
              // 23/09/2026. Pas de table de chance (pas de tirage D100) ; <ModifyCarac> optionnel
              // ajoute le 27/09/2026 pour les effets permanents chiffrables (ChargeDiseaseModificateur).
              LitDataDisease(BookNode, Livre, LangueDef);

              // Equipement de depart par Classe (Rulebook p.37, "Class Trappings"), audit du
              // 23/09/2026. Meme format que l'equipement de Carriere (SUBCHAPTER_ITEM/Item),
              // mais un seul niveau par Classe (pas de DATA_CAREER_LEVEL) : ajoute a la
              // creation en plus de l'equipement de la Carriere choisie (wincreation.pas, via
              // <Class> deja charge dans StructureMetier.LibelleGroupe).
              LitDataClassItem(BookNode, Livre, LangueDef);

              // Table de chance Physique (D100 -> Code), CONTEXT.md §2.7 - propre à ce livre,
              // pas de traduction (juste une plage et un code), chargée une seule fois comme
              // DATA_CORRUPTION_PHYSICAL/DATA_CORRUPTION_MENTAL plus haut.
              LitDataCorruptionPhysChance(BookNode, Livre, LangueDef);

              // Table de chance Mentale (D100 -> Code), CONTEXT.md §2.7
              LitDataCorruptionMentChance(BookNode, Livre, LangueDef);

              // Catalogue des Afflictions (Unofficial Grimoire, fan book, p.30-31,
              // CONTEXT.md 2.96). Pas de table de chance (contrairement a la
              // Physical/Mental Corruption Table, qui est officielle) - decision de
              // Nono du 27/09/2026. Les 3 plages D100 par categorie de lanceur restent
              // en texte libre dans Effet, faute d'un tirage a cabler. <ModifyCarac>
              // optionnel ajoute le 27/09/2026 pour les effets permanents chiffrables
              // (ChargeAfflictionModificateur).
              LitDataAffliction(BookNode, Livre, LangueDef, Langue);

            end;

        end;
    finally
      XMLDoc.Free;
    end;
  end;

Procedure XmlRetireLivre(Libelle: String);
  // Les listes sont toutes balayees a l'envers. Dec(Nb, N) plutot que Nb := Count : les Nb* sont
  // des bornes de boucle (ex. chargearme.pas), on retire exactement ce que l'import avait compte.
  // Non touchees : ListLivre/ListLivreTraduit (dedoublonnees, restent valides) et les listes de
  // chaines par livre (ListeOptionDesactiveeParLivre = choix de l'utilisateur).
  var
    I, N: Integer;
  begin
    N := 0; for I := ListRace.Count - 1 downto 0 do if ListRace[I].Livre = Libelle then begin ListRace.Delete(I); Inc(N); end; Dec(NbRace, N);
    N := 0; for I := ListEspece.Count - 1 downto 0 do if ListEspece[I].Livre = Libelle then begin ListEspece.Delete(I); Inc(N); end; Dec(NbEspece, N);
    N := 0; for I := ListNation.Count - 1 downto 0 do if ListNation[I].Livre = Libelle then begin ListNation.Delete(I); Inc(N); end; Dec(NbNation, N);
    N := 0; for I := ListRegle.Count - 1 downto 0 do if ListRegle[I].Livre = Libelle then begin ListRegle.Delete(I); Inc(N); end; Dec(NbRegle, N);
    N := 0; for I := ListRegleSource.Count - 1 downto 0 do if ListRegleSource[I].Livre = Libelle then begin ListRegleSource.Delete(I); Inc(N); end;
    N := 0; for I := ListRegleMetier.Count - 1 downto 0 do if ListRegleMetier[I].Livre = Libelle then begin ListRegleMetier.Delete(I); Inc(N); end; Dec(NbRegleMetier, N);
    N := 0; for I := ListTalent.Count - 1 downto 0 do if ListTalent[I].Livre = Libelle then begin ListTalent.Delete(I); Inc(N); end; Dec(NbTalent, N);
    N := 0; for I := ListCompetence.Count - 1 downto 0 do if ListCompetence[I].Livre = Libelle then begin ListCompetence.Delete(I); Inc(N); end; Dec(NbCompetence, N);
    N := 0; for I := ListMetierCompetence.Count - 1 downto 0 do if ListMetierCompetence[I].Livre = Libelle then begin ListMetierCompetence.Delete(I); Inc(N); end; Dec(NbMetierCompetence, N);
    N := 0; for I := ListMetier.Count - 1 downto 0 do if ListMetier[I].Livre = Libelle then begin ListMetier.Delete(I); Inc(N); end; Dec(NbMetier, N);
    N := 0; for I := ListMetierNiveau.Count - 1 downto 0 do if ListMetierNiveau[I].Livre = Libelle then begin ListMetierNiveau.Delete(I); Inc(N); end; Dec(NbMetierNiveau, N);
    N := 0; for I := ListMetierAttribut.Count - 1 downto 0 do if ListMetierAttribut[I].Livre = Libelle then begin ListMetierAttribut.Delete(I); Inc(N); end; Dec(NbMetierAttribut, N);
    N := 0; for I := ListMetierTalent.Count - 1 downto 0 do if ListMetierTalent[I].Livre = Libelle then begin ListMetierTalent.Delete(I); Inc(N); end; Dec(NbMetierTalent, N);
    N := 0; for I := ListeAttribut.Count - 1 downto 0 do if ListeAttribut[I].Livre = Libelle then begin ListeAttribut.Delete(I); Inc(N); end; Dec(NbAttribut, N);
    N := 0; for I := ListRaceMetier.Count - 1 downto 0 do if ListRaceMetier[I].Livre = Libelle then begin ListRaceMetier.Delete(I); Inc(N); end; Dec(NbRaceMetier, N);
    N := 0; for I := ListRaceMetierSource.Count - 1 downto 0 do if ListRaceMetierSource[I].Livre = Libelle then begin ListRaceMetierSource.Delete(I); Inc(N); end;
    N := 0; for I := ListRaceAttribut.Count - 1 downto 0 do if ListRaceAttribut[I].Livre = Libelle then begin ListRaceAttribut.Delete(I); Inc(N); end; Dec(NbRaceAttribut, N);
    N := 0; for I := ListRacePhysique.Count - 1 downto 0 do if ListRacePhysique[I].Livre = Libelle then begin ListRacePhysique.Delete(I); Inc(N); end; Dec(NbRacePhysique, N);
    N := 0; for I := ListRaceCouleur.Count - 1 downto 0 do if ListRaceCouleur[I].Livre = Libelle then begin ListRaceCouleur.Delete(I); Inc(N); end; Dec(NbRaceCouleur, N);
    N := 0; for I := ListRaceNom.Count - 1 downto 0 do if ListRaceNom[I].Livre = Libelle then begin ListRaceNom.Delete(I); Inc(N); end; Dec(NbRaceNom, N);
    N := 0; for I := ListRaceNomModele.Count - 1 downto 0 do if ListRaceNomModele[I].Livre = Libelle then begin ListRaceNomModele.Delete(I); Inc(N); end; Dec(NbRaceNomModele, N);
    N := 0; for I := ListRaceNomRegle.Count - 1 downto 0 do if ListRaceNomRegle[I].Livre = Libelle then begin ListRaceNomRegle.Delete(I); Inc(N); end;
    N := 0; for I := ListRaceCompetence.Count - 1 downto 0 do if ListRaceCompetence[I].Livre = Libelle then begin ListRaceCompetence.Delete(I); Inc(N); end; Dec(NbRaceCompetence, N);
    N := 0; for I := ListRaceTalent.Count - 1 downto 0 do if ListRaceTalent[I].Livre = Libelle then begin ListRaceTalent.Delete(I); Inc(N); end; Dec(NbRaceTalent, N);
    N := 0; for I := ListTalentCreation.Count - 1 downto 0 do if ListTalentCreation[I].Livre = Libelle then begin ListTalentCreation.Delete(I); Inc(N); end; Dec(NbTalentCreation, N);
    N := 0; for I := ListeAttributAugmentation.Count - 1 downto 0 do if ListeAttributAugmentation[I].Livre = Libelle then begin ListeAttributAugmentation.Delete(I); Inc(N); end; Dec(NbAttributAugmentation, N);
    N := 0; for I := ListeCompetenceAugmentation.Count - 1 downto 0 do if ListeCompetenceAugmentation[I].Livre = Libelle then begin ListeCompetenceAugmentation.Delete(I); Inc(N); end; Dec(NbCompetenceAugmentation, N);
    N := 0; for I := ListArme.Count - 1 downto 0 do if ListArme[I].Livre = Libelle then begin ListArme.Delete(I); Inc(N); end; Dec(NbArme, N);
    N := 0; for I := ListArmure.Count - 1 downto 0 do if ListArmure[I].Livre = Libelle then begin ListArmure.Delete(I); Inc(N); end; Dec(NbArmure, N);
    N := 0; for I := ListTrapping.Count - 1 downto 0 do if ListTrapping[I].Livre = Libelle then begin ListTrapping.Delete(I); Inc(N); end; Dec(NbTrapping, N);
    N := 0; for I := ListArmureSimplifiee.Count - 1 downto 0 do if ListArmureSimplifiee[I].Livre = Libelle then begin ListArmureSimplifiee.Delete(I); Inc(N); end; Dec(NbArmureSimplifiee, N);
    for I := ListArmureSimplifieeSource.Count - 1 downto 0 do if ListArmureSimplifieeSource[I].Livre = Libelle then ListArmureSimplifieeSource.Delete(I);
    N := 0; for I := ListOptionRegle.Count - 1 downto 0 do if ListOptionRegle[I].Livre = Libelle then begin ListOptionRegle.Delete(I); Inc(N); end; Dec(NbOptionRegle, N);
    N := 0; for I := ListArmeBonus.Count - 1 downto 0 do if ListArmeBonus[I].Livre = Libelle then begin ListArmeBonus.Delete(I); Inc(N); end; Dec(NbArmeBonus, N);
    N := 0; for I := ListMetierEquipement.Count - 1 downto 0 do if ListMetierEquipement[I].Livre = Libelle then begin ListMetierEquipement.Delete(I); Inc(N); end; Dec(NbMetierEquipement, N);
    N := 0; for I := ListArmureBonus.Count - 1 downto 0 do if ListArmureBonus[I].Livre = Libelle then begin ListArmureBonus.Delete(I); Inc(N); end; Dec(NbArmureBonus, N);
    N := 0; for I := ListSort.Count - 1 downto 0 do if ListSort[I].Livre = Libelle then begin ListSort.Delete(I); Inc(N); end; Dec(NbSort, N);
    N := 0; for I := ListSortTalent.Count - 1 downto 0 do if ListSortTalent[I].Livre = Libelle then begin ListSortTalent.Delete(I); Inc(N); end; Dec(NbSortTalent, N);
    N := 0; for I := ListTrait.Count - 1 downto 0 do if ListTrait[I].Livre = Libelle then begin ListTrait.Delete(I); Inc(N); end; Dec(NbTrait, N);
    N := 0; for I := ListTraitOption.Count - 1 downto 0 do if ListTraitOption[I].Livre = Libelle then begin ListTraitOption.Delete(I); Inc(N); end; Dec(NbTraitOption, N);
    N := 0; for I := ListCareerBonus.Count - 1 downto 0 do if ListCareerBonus[I].Livre = Libelle then begin ListCareerBonus.Delete(I); Inc(N); end; Dec(NbCareerBonus, N);
    N := 0; for I := ListCareerBonusNiveau.Count - 1 downto 0 do if ListCareerBonusNiveau[I].Livre = Libelle then begin ListCareerBonusNiveau.Delete(I); Inc(N); end; Dec(NbCareerBonusNiveau, N);
    N := 0; for I := ListCareerBonusSpecialRule.Count - 1 downto 0 do if ListCareerBonusSpecialRule[I].Livre = Libelle then begin ListCareerBonusSpecialRule.Delete(I); Inc(N); end; Dec(NbCareerBonusSpecialRule, N);
    N := 0; for I := ListCareerAdaptation.Count - 1 downto 0 do if ListCareerAdaptation[I].Livre = Libelle then begin ListCareerAdaptation.Delete(I); Inc(N); end; Dec(NbCareerAdaptation, N);
    N := 0; for I := ListCareerAdaptationLigne.Count - 1 downto 0 do if ListCareerAdaptationLigne[I].Livre = Libelle then begin ListCareerAdaptationLigne.Delete(I); Inc(N); end; Dec(NbCareerAdaptationLigne, N);
    N := 0; for I := ListFabrication.Count - 1 downto 0 do if ListFabrication[I].Livre = Libelle then begin ListFabrication.Delete(I); Inc(N); end; Dec(NbFabrication, N);
    N := 0; for I := ListSigneAstral.Count - 1 downto 0 do if ListSigneAstral[I].Livre = Libelle then begin ListSigneAstral.Delete(I); Inc(N); end; Dec(NbSigneAstral, N);
    for I := ListSigneAstralSource.Count - 1 downto 0 do if ListSigneAstralSource[I].Livre = Libelle then ListSigneAstralSource.Delete(I);
    N := 0; for I := ListSigneEffet.Count - 1 downto 0 do if ListSigneEffet[I].Livre = Libelle then begin ListSigneEffet.Delete(I); Inc(N); end; Dec(NbSigneEffet, N);
    N := 0; for I := ListRaceCreation.Count - 1 downto 0 do if ListRaceCreation[I].Livre = Libelle then begin ListRaceCreation.Delete(I); Inc(N); end; Dec(NbRaceCreation, N);
    N := 0; for I := ListMetierSousMetier.Count - 1 downto 0 do if ListMetierSousMetier[I].Livre = Libelle then begin ListMetierSousMetier.Delete(I); Inc(N); end; Dec(NbMetierSousMetier, N);
    N := 0; for I := ListMetierRaceChoixMetier.Count - 1 downto 0 do if ListMetierRaceChoixMetier[I].Livre = Libelle then begin ListMetierRaceChoixMetier.Delete(I); Inc(N); end; Dec(NbMetierRaceChoixMetier, N);
    N := 0; for I := ListTraduction.Count - 1 downto 0 do if ListTraduction[I].Livre = Libelle then begin ListTraduction.Delete(I); Inc(N); end; Dec(NbTraduction, N);
    N := 0; for I := ListTexte.Count - 1 downto 0 do if ListTexte[I].Livre = Libelle then begin ListTexte.Delete(I); Inc(N); end; Dec(NbTexte, N);
    N := 0; for I := ListRaceCorruptionCreation.Count - 1 downto 0 do if ListRaceCorruptionCreation[I].Livre = Libelle then begin ListRaceCorruptionCreation.Delete(I); Inc(N); end; Dec(NbRaceCorruptionCreation, N);
    N := 0; for I := ListCorruptionTable.Count - 1 downto 0 do if ListCorruptionTable[I].Livre = Libelle then begin ListCorruptionTable.Delete(I); Inc(N); end; Dec(NbCorruptionTable, N);
    N := 0; for I := ListCorruptionChance.Count - 1 downto 0 do if ListCorruptionChance[I].Livre = Libelle then begin ListCorruptionChance.Delete(I); Inc(N); end; Dec(NbCorruptionChance, N);
    N := 0; for I := ListDisease.Count - 1 downto 0 do if ListDisease[I].Livre = Libelle then begin ListDisease.Delete(I); Inc(N); end; Dec(NbDisease, N);
    N := 0; for I := ListAffliction.Count - 1 downto 0 do if ListAffliction[I].Livre = Libelle then begin ListAffliction.Delete(I); Inc(N); end; Dec(NbAffliction, N);
    N := 0; for I := ListClassEquipement.Count - 1 downto 0 do if ListClassEquipement[I].Livre = Libelle then begin ListClassEquipement.Delete(I); Inc(N); end; Dec(NbClassEquipement, N);
    N := 0; for I := ListTalentEffet.Count - 1 downto 0 do if ListTalentEffet[I].Livre = Libelle then begin ListTalentEffet.Delete(I); Inc(N); end; Dec(NbTalentEffet, N);
    N := 0; for I := ListTalentCompetenceModif.Count - 1 downto 0 do if ListTalentCompetenceModif[I].Livre = Libelle then begin ListTalentCompetenceModif.Delete(I); Inc(N); end; Dec(NbTalentCompetenceModif, N);
    N := 0; for I := ListRaceOpinion.Count - 1 downto 0 do if ListRaceOpinion[I].Livre = Libelle then begin ListRaceOpinion.Delete(I); Inc(N); end; Dec(NbRaceOpinion, N);
    N := 0; for I := ListCorruptionCompetenceAttributModif.Count - 1 downto 0 do if ListCorruptionCompetenceAttributModif[I].Livre = Libelle then begin ListCorruptionCompetenceAttributModif.Delete(I); Inc(N); end; Dec(NbCorruptionCompetenceAttributModif, N);
    N := 0; for I := ListCorruptionTalent.Count - 1 downto 0 do if ListCorruptionTalent[I].Livre = Libelle then begin ListCorruptionTalent.Delete(I); Inc(N); end; Dec(NbCorruptionTalent, N);
    N := 0; for I := ListCorruptionEquipement.Count - 1 downto 0 do if ListCorruptionEquipement[I].Livre = Libelle then begin ListCorruptionEquipement.Delete(I); Inc(N); end; Dec(NbCorruptionEquipement, N);
    N := 0; for I := ListArmureBonusTalent.Count - 1 downto 0 do if ListArmureBonusTalent[I].Livre = Libelle then begin ListArmureBonusTalent.Delete(I); Inc(N); end; Dec(NbArmureBonusTalent, N);
    N := 0; for I := ListArmeBonusTalent.Count - 1 downto 0 do if ListArmeBonusTalent[I].Livre = Libelle then begin ListArmeBonusTalent.Delete(I); Inc(N); end; Dec(NbArmeBonusTalent, N);
    N := 0; for I := ListAfflictionCompetenceAttributModif.Count - 1 downto 0 do if ListAfflictionCompetenceAttributModif[I].Livre = Libelle then begin ListAfflictionCompetenceAttributModif.Delete(I); Inc(N); end; Dec(NbAfflictionCompetenceAttributModif, N);
    N := 0; for I := ListModificateur.Count - 1 downto 0 do if ListModificateur[I].Livre = Libelle then begin ListModificateur.Delete(I); Inc(N); end;
    N := 0; for I := ListConditionDonnee.Count - 1 downto 0 do if ListConditionDonnee[I].Livre = Libelle then begin ListConditionDonnee.Delete(I); Inc(N); end;
  end;

Function XmlLivre(FileName: String): string;
  var
    XMLDoc:                   TXMLDocument;
    BookNode:                 TDOMNode;
    Node:                     TDOMNode;
    Livre:                    String = '';
  begin
    XMLDoc   := TXMLDocument.Create;
    try
      ReadXMLFile(XMLDoc, GetCurrentDir + ConstCheminLivre + FileName + '.xml');
      BookNode := XMLDoc.DocumentElement;
      if Assigned(BookNode) and (BookNode.NodeName = ConstXmlDataBook) then
        begin
          Livre          := XmlTexte(BookNode, ConstXmlLibelleLivre);
          Node           := BookNode.FindNode(ConstXmlLanguage);
          LivreLangue    := RemoveQuotes(UTF8Encode(Node.TextContent));
          Node           := BookNode.FindNode(ConstXmlCompletLivre);
          if Assigned(BookNode.FindNode(ConstXmlCompletLivre)) then
            LivreComplet := StrtoBool(RemoveQuotes(UTF8Encode(Node.TextContent)))
          else
            LivreComplet := True;
        end;
    finally
      XMLDoc.Free;
    end;
    Result := Livre;
  end;

Function XmlLivreBalise(CheminFichier: String; Balise: String): String;
  // Lit une balise a la racine d'un fichier livre XML, sans dependre de ConstCheminLivre
  // (contrairement a XmlLivre, toujours lu dans le repertoire du livre actif) - utilisee
  // pour scanner les sous-repertoires DATABASE\<version>\ a la recherche de <OFFICIAL>/
  // <VERSION> (selecteur de version, TMenu.ChargerListeVersions, warhammersource.pas,
  // demande de Nono le 13/09/2026).
  var
    XMLDoc: TXMLDocument;
    Racine: TDOMNode;
    Node:   TDOMNode;
  begin
    Result := '';
    XMLDoc := TXMLDocument.Create;
    try
      ReadXMLFile(XMLDoc, CheminFichier);
      Racine := XMLDoc.DocumentElement;
      if Assigned(Racine) then
        begin
          Node := Racine.FindNode(Balise);
          if Assigned(Node) then
            Result := RemoveQuotes(UTF8Encode(Node.TextContent));
        end;
    finally
      XMLDoc.Free;
    end;
  end;

Function XmlMajLivre(CodePrincipal, CheminEbauche, CheminRestauration: String): String;
  var
    Libelle: String;
    Autres:  TStringList;
    Rech:    TSearchRec;

  procedure Recharge(Chemin: String);
    var
      Ind: Integer;
    begin
      XmlRetireLivre(Libelle);
      if Chemin = '' then
        XmlImport(CodePrincipal, true)
      else
        XmlImport(CodePrincipal, true, Chemin);
      for Ind := 0 to Autres.Count - 1 do
        XmlImport(Autres[Ind], true);
      if Chemin = '' then
        XmlImport(CodePrincipal, false)
      else
        XmlImport(CodePrincipal, false, Chemin);
      for Ind := 0 to Autres.Count - 1 do
        XmlImport(Autres[Ind], false);
      CompleteRaceMetierParEspece;
      Traduit(ValLangue, Libelle);
    end;

  begin
    Result  := '';
    Libelle := XmlLivreBalise(GetCurrentDir + ConstCheminLivre + CodePrincipal + '.xml', ConstXmlLibelleLivre);
    Autres  := TStringList.Create;
    try
      // Les autres fichiers du livre (traductions) : retirer le livre emporte aussi leurs libelles.
      if FindFirst(GetCurrentDir + ConstCheminLivre + '*.xml', faAnyFile, Rech) = 0 then
        begin
          repeat
            if (ExtractStringBefore(Rech.Name, '.') <> CodePrincipal)
              and (XmlLivreBalise(GetCurrentDir + ConstCheminLivre + Rech.Name, ConstXmlLibelleLivre) = Libelle) then
              Autres.Add(ExtractStringBefore(Rech.Name, '.'));
          until FindNext(Rech) <> 0;
          FindClose(Rech);
        end;
      try
        Recharge(CheminEbauche);
      except
        on E: Exception do
          begin
            Result := E.Message;
            try
              Recharge(CheminRestauration);
            except
              on E2: Exception do
                Result := Result + LineEnding + E2.Message;
            end;
          end;
      end;
    finally
      Autres.Free;
    end;
  end;

// Specialisations propres au personnage : des <Skill> et <Talent> au format DATA_SKILL_SPECIALIZATION /
// DATA_TALENT_SPECIALIZATION d'un livre (id, Description, Generique), rangees dans le meme bloc
// <CUSTOM_ITEMS> que les objets propres et injectes sous le meme livre virtuel. Le code garde le
// radical du parent (PERSO-<RADICAL>_<hex>) : la fenetre de choix les rapproche comme celles d'un livre.
Procedure LitSpecialisationsPropresNoeud(NodeNv1: TDOMNode; Livre: String);
  var
    Node:        TDOMNode;
    Fils:        TDOMNode;
    PCompetence: StructureCompetence;
    PTalent:     StructureTalent;
    PTraduction: StructureTraduction;
    Code:        String;
    Libelle:     String;
    Generique:   String;
  begin
    Node := XmlElement(NodeNv1.FirstChild);
    while Assigned(Node) do
      begin
        Code      := RemoveQuotes(UTF8Encode(TDOMElement(Node).GetAttribute(ConstXmlId)));
        Libelle   := '';
        Generique := '';
        Fils      := XmlElement(Node.FirstChild);
        while Assigned(Fils) do
          begin
            if Fils.NodeName = ConstXmlDescription then
              Libelle := RemoveQuotes(UTF8Encode(Fils.TextContent))
            else if Fils.NodeName = ConstXmlGenerique then
              Generique := RemoveQuotes(UTF8Encode(Fils.TextContent));
            Fils := XmlElement(Fils.NextSibling);
          end;
        if (Code <> '') and (Libelle <> '') then
          begin
            if Node.NodeName = ConstXmlCompetence then
              begin
                PCompetence                := Default(StructureCompetence);
                PCompetence.Livre          := Livre;
                PCompetence.SousCompetence := True;
                PCompetence.CodeCompetence := Code;
                PCompetence.CodeGenerique  := Generique;
                PCompetence.Libelle        := Libelle;
                PCompetence.CodeAttribut   := ChercheCompetence(Generique).CodeAttribut;
                ListCompetence.Add(PCompetence);
                Inc(NbCompetence);
                PTraduction := InitTrad(ConstPCompetence, Code, '', Livre);
              end
            else
              begin
                PTalent               := Default(StructureTalent);
                PTalent.Livre         := Livre;
                PTalent.SousTalent    := True;
                PTalent.CodeTalent    := Code;
                PTalent.CodeGenerique := Generique;
                PTalent.Libelle       := Libelle;
                ListTalent.Add(PTalent);
                Inc(NbTalent);
                PTraduction := InitTrad(ConstPTalent, Code, '', Livre);
              end;
            // un seul nom saisi : il sert pour l'anglais et pour la langue courante
            PTraduction.Libelle := Libelle;
            AddTrad(PTraduction, ConstAnglais);
            if ValLangue <> ConstAnglais then
              AddTrad(PTraduction, ValLangue);
          end;
        Node := XmlElement(Node.NextSibling);
      end;
  end;

// Injecte dans les listes les objets propres d'un personnage (contenu de <CUSTOM_ITEMS> : des
// <Weapon>, <Armor> et <Trapping> au format d'un livre). Les objets sont CUMULES d'une fiche a
// l'autre (codes uniques, ils ne se telescopent pas) : les membres d'un groupe charges l'un apres
// l'autre gardent tous leurs noms. Un objet deja vu est remplace par sa nouvelle version ; un objet
// supprime reste en memoire jusqu'a la fermeture, sans effet puisque rien ne le cite. Le livre
// est retire puis reinjecte en entier a chaque appel. Appele par PersonnageXmlChargement a chaque
// chargement de fiche, y compris avec ''.
var
  ObjetsPropresIds:  TStringList = nil;
  ObjetsPropresXmls: TStringList = nil;

Procedure InjecteObjetsPropres(const Xml: String);
  var
    Langue:        String;
    Tout:          String;
    SauveLivre:    String;
    SauveNbArme:   Integer;
    SauveNbArmure: Integer;
    SauveNbTrap:   Integer;
    SauveNbUnique: Integer;

  // Un passage par type : le document est relu et prive des elements d'un autre type, car chaque
  // lecteur de livre parcourt tous les enfants du noeud qu'on lui donne.
  procedure Lire(const Balise: String; Lecteur: Integer; const Prefixe: String = '');
    var
      Doc:    TXMLDocument;
      Flux:   TStringStream;
      Noeud:  TDOMNode;
      Suivant: TDOMNode;
    begin
      Doc  := nil;
      // Les specialisations (lecteur 5) ne se cumulent PAS d'une fiche a l'autre : la fenetre de choix
      // les propose, un autre personnage ouvert dans la session pourrait les prendre. Seules celles de
      // la fiche en cours sont injectees. Les objets, eux, restent cumules (rien ne les cite).
      if Lecteur = 5 then
        Flux := TStringStream.Create('<' + ConstXmlObjetsPropres + '>' + Xml + '</' + ConstXmlObjetsPropres + '>')
      else
        Flux := TStringStream.Create('<' + ConstXmlObjetsPropres + '>' + Tout + '</' + ConstXmlObjetsPropres + '>');
      try
        ReadXMLFile(Doc, Flux);
        Noeud := Doc.DocumentElement.FirstChild;
        while Assigned(Noeud) do
          begin
            Suivant := Noeud.NextSibling;
            if (Noeud.NodeName <> Balise)
               or ((Prefixe <> '') and (Pos(Prefixe, TDOMElement(Noeud).GetAttribute(ConstXmlId)) <> 1)) then
              Doc.DocumentElement.RemoveChild(Noeud);
            Noeud := Suivant;
          end;
        case Lecteur of
          0: LitArmesNoeud(Doc.DocumentElement, ConstLivreObjetsPropres, ConstAnglais, Langue);
          1: LitArmuresNoeud(Doc.DocumentElement, ConstLivreObjetsPropres, ConstAnglais, Langue);
          3: LitArmesBonusNoeud(Doc.DocumentElement, ConstLivreObjetsPropres, ConstAnglais, Langue);
          4: LitArmuresBonusNoeud(Doc.DocumentElement, ConstLivreObjetsPropres, ConstAnglais, Langue);
          5: LitSpecialisationsPropresNoeud(Doc.DocumentElement, ConstLivreObjetsPropres);
        else
          LitTrappingsNoeud(Doc.DocumentElement, ConstLivreObjetsPropres, ConstAnglais, Langue);
        end;
      finally
        Doc.Free;
        Flux.Free;
      end;
    end;

  // Range chaque element de la fiche sous son id, puis recompose le fragment de tous les objets connus.
  procedure Cumuler;
    var
      Doc:   TXMLDocument;
      Flux:  TStringStream;
      Sortie: TStringStream;
      Noeud: TDOMNode;
      Id:    String;
      Ind:   Integer;
      I:     Integer;
    begin
      if not Assigned(ObjetsPropresIds) then
        begin
          ObjetsPropresIds  := TStringList.Create;
          ObjetsPropresXmls := TStringList.Create;
        end;
      if Trim(Xml) <> '' then
        begin
          Doc  := nil;
          Flux := TStringStream.Create('<' + ConstXmlObjetsPropres + '>' + Xml + '</' + ConstXmlObjetsPropres + '>');
          try
            ReadXMLFile(Doc, Flux);
            Noeud := Doc.DocumentElement.FirstChild;
            while Assigned(Noeud) do
              begin
                if Noeud.NodeType = ELEMENT_NODE then
                  begin
                    Id     := TDOMElement(Noeud).GetAttribute(ConstXmlId);
                    Sortie := TStringStream.Create('');
                    try
                      WriteXML(Noeud, Sortie);
                      Ind := ObjetsPropresIds.IndexOf(Id);
                      if Ind < 0 then
                        begin
                          ObjetsPropresIds.Add(Id);
                          ObjetsPropresXmls.Add(Sortie.DataString);
                        end
                      else
                        ObjetsPropresXmls[Ind] := Sortie.DataString;
                    finally
                      Sortie.Free;
                    end;
                  end;
                Noeud := Noeud.NextSibling;
              end;
          finally
            Doc.Free;
            Flux.Free;
          end;
        end;
      Tout := '';
      for I := 0 to ObjetsPropresXmls.Count - 1 do
        Tout := Tout + ObjetsPropresXmls[I];
    end;

  // Les lecteurs de livre rangent tout dans les listes globales, sous le livre PERSO-OBJETS. On les
  // en retire ici pour les mettre dans les listes propres au personnage : les catalogues et les
  // livres ne voient jamais ces elements, ChercheArme & co. les retrouvent en dernier recours.
  procedure DeplaceVersPerso;
    var
      I, N: Integer;
    begin
      N := 0; for I := ListArme.Count - 1 downto 0 do if ListArme[I].Livre = ConstLivreObjetsPropres then begin ListArmePerso.Insert(0, ListArme[I]); ListArme.Delete(I); Inc(N); end; Dec(NbArme, N);
      N := 0; for I := ListArmure.Count - 1 downto 0 do if ListArmure[I].Livre = ConstLivreObjetsPropres then begin ListArmurePerso.Insert(0, ListArmure[I]); ListArmure.Delete(I); Inc(N); end; Dec(NbArmure, N);
      N := 0; for I := ListTrapping.Count - 1 downto 0 do if ListTrapping[I].Livre = ConstLivreObjetsPropres then begin ListTrappingPerso.Insert(0, ListTrapping[I]); ListTrapping.Delete(I); Inc(N); end; Dec(NbTrapping, N);
      N := 0; for I := ListArmeBonus.Count - 1 downto 0 do if ListArmeBonus[I].Livre = ConstLivreObjetsPropres then begin ListArmeBonusPerso.Insert(0, ListArmeBonus[I]); ListArmeBonus.Delete(I); Inc(N); end; Dec(NbArmeBonus, N);
      N := 0; for I := ListArmureBonus.Count - 1 downto 0 do if ListArmureBonus[I].Livre = ConstLivreObjetsPropres then begin ListArmureBonusPerso.Insert(0, ListArmureBonus[I]); ListArmureBonus.Delete(I); Inc(N); end; Dec(NbArmureBonus, N);
      N := 0; for I := ListCompetence.Count - 1 downto 0 do if ListCompetence[I].Livre = ConstLivreObjetsPropres then begin ListCompetencePerso.Insert(0, ListCompetence[I]); ListCompetence.Delete(I); Inc(N); end; Dec(NbCompetence, N);
      N := 0; for I := ListTalent.Count - 1 downto 0 do if ListTalent[I].Livre = ConstLivreObjetsPropres then begin ListTalentPerso.Insert(0, ListTalent[I]); ListTalent.Delete(I); Inc(N); end; Dec(NbTalent, N);
    end;

  begin
    ListArmePerso.Clear;
    ListArmurePerso.Clear;
    ListTrappingPerso.Clear;
    ListArmeBonusPerso.Clear;
    ListArmureBonusPerso.Clear;
    ListCompetencePerso.Clear;
    ListTalentPerso.Clear;
    XmlRetireLivre(ConstLivreObjetsPropres);
    try
      Cumuler;
    except
      on E: Exception do
        begin
          XmlSignale('Objets propres illisibles : ' + E.Message);
          exit;
        end;
    end;
    if (Trim(Tout) = '') and (Trim(Xml) = '') then exit;
    Langue        := ConstAnglais;
    SauveLivre    := LivreImportEnCours;
    SauveNbArme   := LivreNbArme;
    SauveNbArmure := LivreNbArmure;
    SauveNbTrap   := LivreNbTrapping;
    SauveNbUnique := NbArmeUnique;
    try
      try
        LivreImportEnCours := ConstLivreObjetsPropres;
        Lire('BonusMalus', 3, ConstPrefixeQualiteArme);
        Lire('BonusMalus', 4, ConstPrefixeQualiteArmure);
        Lire('Weapon', 0);
        Lire('Armor', 1);
        Lire('Trapping', 2);
        // deux passages (le filtre garde une seule balise a la fois), meme lecteur pour Skill et Talent
        Lire(ConstXmlCompetence, 5);
        Lire(ConstXmlTalent, 5);
        DeplaceVersPerso;
      except
        on E: Exception do
          XmlSignale('Objets propres illisibles : ' + E.Message);
      end;
    finally
      LivreImportEnCours := SauveLivre;
      LivreNbArme        := SauveNbArme;
      LivreNbArmure      := SauveNbArmure;
      LivreNbTrapping    := SauveNbTrap;
      NbArmeUnique       := SauveNbUnique;
    end;
  end;

end.

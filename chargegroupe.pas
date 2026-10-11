unit ChargeGroupe;

{$mode ObjFPC}{$H+}
{$ModeSwitch ArrayOperators}

// Fichier GROUPE_<Nom>.xml (CONTEXT.md 2.100) : liste d'inventaire partage entre les
// personnages d'une equipe (animaux, vehicules, bateaux). Reutilise la structure et les
// helpers XML deja en place pour l'equipement "Divers" d'un personnage (ChargePersonnage,
// XmlExportImport) : rien de nouveau cote format, juste un fichier plus petit.

interface

uses
  Classes, SysUtils, DOM, XMLRead, ChargeConstantes, ChargePersonnage,
  ChargeFabrication, XmlExportImport, UnitCalcul, ChargeArme, ChargeArmure,
  ChargeArmureSimplifie, ChargeTrapping;

Type
  // Contenu complet d'un fichier de groupe (CONTEXT.md 2.100) : la liste d'inventaire
  // partage (etapes 2 a 6) et, depuis l'ambition de groupe, les 2 champs de saisie libre
  // partages par toute l'equipe (memes tags XML que Personnage.AmbitionGroupeCourt/Long,
  // desormais lus/ecrits ICI quand le personnage est dans un groupe).
  StructureGroupe = Record
     Biens:         TArrayPersonnageEquipement;
     AmbitionCourt: String;
     AmbitionLong:  String;
  end;

  function GroupeXmlCreation(Groupe: StructureGroupe; FileName: String): Boolean;
  function GroupeXmlChargement(FileName: String): StructureGroupe;
  // Contenu complet d'un groupe, {Biens: [], AmbitionCourt/Long: ''} si le personnage est
  // solo ou le fichier absent - meme usage que GroupeXmlChargement mais sans exiger que
  // l'appelant verifie FileExists.
  function ChargeGroupeComplet(const Directory, GroupeId: String): StructureGroupe;
  // Met a jour les 2 champs d'ambition de groupe, sans toucher aux biens.
  function GroupeEcritAmbitions(const Directory, GroupeId, AmbitionCourt, AmbitionLong: String): Boolean;
  // Chemin complet du fichier d'un groupe, a partir du dossier racine des personnages
  // (GetCurrentDir+ConstCheminPersonnage) et du nom de groupe (Personnage.GroupeId).
  function NomFichierGroupe(const Directory, NomGroupe: String): String;
  // Noms des groupes existants (fichiers GROUPE_*.xml trouves a la racine de Directory).
  function ListeFichiersGroupe(const Directory: String): TStringList;
  // Noms des personnages (sous-dossiers de Directory) dont GroupeId vaut NomGroupe - pas de
  // liste de membres stockee dans le fichier de groupe, on la reconstruit en scannant.
  function ListeMembresGroupe(const Directory: String; const NomGroupe: String): TStringList;
  // Vrai si un objet de l'equipement fourni est actuellement confie (PortePar) a un bien du
  // groupe GroupeId - condition qui bloque "Sortir du groupe" (WinGroupe).
  function PersonnageUtiliseGroupe(const GroupeId: String; Equipement: TArrayPersonnageEquipement; const Directory: String): Boolean;
  // Ajoute un bien (deja retire de Personnage.Equipement par l'appelant, CONTEXT.md 2.100
  // etape 4 - "Partager avec le groupe") au fichier de groupe existant.
  function GroupeAjouteBien(const Directory, GroupeId: String; Bien: StructurePersonnageEquipement): Boolean;
  // Liste des biens d'un groupe, [] si le personnage est solo ou le fichier absent - meme
  // usage que GroupeXmlChargement mais sans exiger que l'appelant verifie FileExists.
  function ListeBiensGroupe(const Directory, GroupeId: String): TArrayPersonnageEquipement;
  // Un bien precis du groupe par son IdInstance, CodeEquipement = '' si introuvable -
  // resolveur carriedby etendu au groupe (CONTEXT.md 2.100, etape 5).
  function ChercheBienGroupe(const Directory, GroupeId, IdInstance: String): StructurePersonnageEquipement;
  // Retire un bien du fichier de groupe (CONTEXT.md 2.100, etape 6 - "Reprendre" dans
  // WinGroupe) : l'appelant l'ajoute ensuite a Personnage.Equipement.
  function GroupeRetireBien(const Directory, GroupeId, IdInstance: String): Boolean;
  // Libelle d'une ligne d'equipement quel que soit son type (arme/armure/set/divers-animal) -
  // utilise pour lister, dans WinGroupe, les objets confies a un bien du groupe.
  function EquipementLigneLibelle(const Ligne: StructurePersonnageEquipement): String;
  // Pour chaque membre du groupe, les objets qu'il a confies (PortePar) au bien IdBien -
  // une entree "Personnage - Objet" par ligne trouvee. Balaie chaque fiche membre en entier
  // (PersonnageXmlChargement) : acceptable, le nombre de membres reste petit.
  function ListeObjetsSurBien(const Directory, GroupeId, IdBien: String): TStringList;

implementation

function GroupeXmlCreation(Groupe: StructureGroupe; FileName: String): Boolean;
var
  XMLContent: TStringList;
  Bien:       StructurePersonnageEquipement;
begin
  Result := False;
  XMLContent := TStringList.Create;
  try
    XMLContent.Add(XmlDataBase());
    XMLContent.Add(XmlDebut(ConstXmlGroupe));
      XMLContent.Add(XmlLigne(ConstXmlAmbitionGroupeCourt, Groupe.AmbitionCourt));
      XMLContent.Add(XmlLigne(ConstXmlAmbitionGroupeLong, Groupe.AmbitionLong));
      XMLContent.Add(XmlDebut(ConstXmlSousChapitreDivers));
      for Bien in Groupe.Biens do
        XMLContent.Add(XmlLigneDonnee(ConstXmlItem, Bien.CodeEquipement, QualiteSansMarqueur(Bien.QualiteEquipement),
          XmlAttributEquipementInstance(Bien)+XmlAttributEquipementQuantite(Bien.Quantite)));
      XMLContent.Add(XmlFin(ConstXmlSousChapitreDivers));
    XMLContent.Add(XmlFin(ConstXmlGroupe));
    XMLContent.SaveToFile(FileName);
    Result := True;
  finally
    XMLContent.Free;
  end;
end;

function GroupeXmlChargement(FileName: String): StructureGroupe;
var
  XMLDoc:         TXMLDocument;
  GroupeNode:     TDOMNode;
  SubChapterNode: TDOMNode;
  Node:           TDOMNode;
  Bien:           StructurePersonnageEquipement;
begin
  Result.Biens         := [];
  Result.AmbitionCourt := '';
  Result.AmbitionLong  := '';
  XMLDoc := TXMLDocument.Create;
  try
    ReadXMLFile(XMLDoc, FileName);
    GroupeNode := XMLDoc.DocumentElement;
    if Assigned(GroupeNode) and (GroupeNode.NodeName = ConstXmlGroupe) then
      begin
        if Assigned(GroupeNode.FindNode(ConstXmlAmbitionGroupeCourt)) then
          Result.AmbitionCourt := RemoveQuotes(UTF8Encode(GroupeNode.FindNode(ConstXmlAmbitionGroupeCourt).TextContent));
        if Assigned(GroupeNode.FindNode(ConstXmlAmbitionGroupeLong)) then
          Result.AmbitionLong := RemoveQuotes(UTF8Encode(GroupeNode.FindNode(ConstXmlAmbitionGroupeLong).TextContent));
        SubChapterNode := GroupeNode.FindNode(ConstXmlSousChapitreDivers);
        if Assigned(SubChapterNode) then
          begin
            Node := SubChapterNode.FirstChild;
            while Assigned(Node) do
              begin
                if (Node.NodeType = ELEMENT_NODE) then
                  begin
                    Bien.CodeEquipement    := RemoveQuotes(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlData).NodeValue));
                    Bien.TypeEquipement    := TrimRight(TypeEquipAN);
                    Bien.QualiteEquipement := RemoveQuotes(UTF8Encode(Node.TextContent));
                    Bien.Porte             := False;
                    LitEquipementInstance(Node, Bien);
                    if Assigned(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite)) then
                      Bien.Quantite        := StrToIntDef(UTF8Encode(Node.Attributes.GetNamedItem(ConstXmlEquipementQuantite).NodeValue), 1)
                    else
                      Bien.Quantite        := 1;
                    Result.Biens           += [Bien];
                  end;
                Node := Node.NextSibling;
              end;
          end;
      end;
  finally
    XMLDoc.Free;
  end;
end;

function ChargeGroupeComplet(const Directory, GroupeId: String): StructureGroupe;
var
  FileName: String;
begin
  Result.Biens         := [];
  Result.AmbitionCourt := '';
  Result.AmbitionLong  := '';
  if GroupeId = '' then Exit;
  FileName := NomFichierGroupe(Directory, GroupeId);
  if FileExists(FileName) then
    Result := GroupeXmlChargement(FileName);
end;

function GroupeEcritAmbitions(const Directory, GroupeId, AmbitionCourt, AmbitionLong: String): Boolean;
var
  Groupe: StructureGroupe;
begin
  Result := False;
  if GroupeId = '' then Exit;
  Groupe               := ChargeGroupeComplet(Directory, GroupeId);
  Groupe.AmbitionCourt := AmbitionCourt;
  Groupe.AmbitionLong  := AmbitionLong;
  Result               := GroupeXmlCreation(Groupe, NomFichierGroupe(Directory, GroupeId));
end;

function NomFichierGroupe(const Directory, NomGroupe: String): String;
begin
  Result := IncludeTrailingPathDelimiter(Directory) + 'GROUPE_' + NomGroupe + '.xml';
end;

function ListeFichiersGroupe(const Directory: String): TStringList;
var
  SearchRec: TSearchRec;
  Nom:       String;
begin
  Result := TStringList.Create;
  if FindFirst(IncludeTrailingPathDelimiter(Directory) + 'GROUPE_*.xml', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Attr and faDirectory) = 0 then
          begin
            Nom := ChangeFileExt(SearchRec.Name, '');
            Delete(Nom, 1, Length('GROUPE_'));
            Result.Add(Nom);
          end;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
end;

function ListeMembresGroupe(const Directory: String; const NomGroupe: String): TStringList;
var
  SearchRec:         TSearchRec;
  FichierPersonnage: String;
begin
  Result := TStringList.Create;
  if FindFirst(IncludeTrailingPathDelimiter(Directory) + '*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if ((SearchRec.Attr and faDirectory) <> 0) and (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            FichierPersonnage := PersonnageXmlFichierActuel(IncludeTrailingPathDelimiter(Directory) + SearchRec.Name);
            if (FichierPersonnage <> '') and (PersonnageGroupeIdFichier(FichierPersonnage) = NomGroupe) then
              Result.Add(SearchRec.Name);
          end;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
end;

function PersonnageUtiliseGroupe(const GroupeId: String; Equipement: TArrayPersonnageEquipement; const Directory: String): Boolean;
var
  Bien:  StructurePersonnageEquipement;
  Ligne: StructurePersonnageEquipement;
begin
  Result := False;
  if GroupeId = '' then Exit;
  for Ligne in Equipement do
    if Ligne.PortePar <> '' then
      for Bien in ChargeGroupeComplet(Directory, GroupeId).Biens do
        if Bien.IdInstance = Ligne.PortePar then
          begin
            Result := True;
            Exit;
          end;
end;

function GroupeAjouteBien(const Directory, GroupeId: String; Bien: StructurePersonnageEquipement): Boolean;
var
  Groupe: StructureGroupe;
begin
  Groupe        := ChargeGroupeComplet(Directory, GroupeId);
  Groupe.Biens += [Bien];
  Result        := GroupeXmlCreation(Groupe, NomFichierGroupe(Directory, GroupeId));
end;

function ListeBiensGroupe(const Directory, GroupeId: String): TArrayPersonnageEquipement;
begin
  Result := ChargeGroupeComplet(Directory, GroupeId).Biens;
end;

function ChercheBienGroupe(const Directory, GroupeId, IdInstance: String): StructurePersonnageEquipement;
var
  Bien: StructurePersonnageEquipement;
begin
  Result.CodeEquipement := '';
  if IdInstance = '' then Exit;
  for Bien in ListeBiensGroupe(Directory, GroupeId) do
    if Bien.IdInstance = IdInstance then
      begin
        Result := Bien;
        Exit;
      end;
end;

function GroupeRetireBien(const Directory, GroupeId, IdInstance: String): Boolean;
var
  Groupe:   StructureGroupe;
  Nouveaux: TArrayPersonnageEquipement;
  Bien:     StructurePersonnageEquipement;
begin
  Result   := False;
  if not FileExists(NomFichierGroupe(Directory, GroupeId)) then Exit;
  Groupe   := ChargeGroupeComplet(Directory, GroupeId);
  Nouveaux := [];
  for Bien in Groupe.Biens do
    if Bien.IdInstance <> IdInstance then
      Nouveaux += [Bien];
  Groupe.Biens := Nouveaux;
  Result       := GroupeXmlCreation(Groupe, NomFichierGroupe(Directory, GroupeId));
end;

function EquipementLigneLibelle(const Ligne: StructurePersonnageEquipement): String;
var
  Typ: String;
begin
  Typ := TrimRight(Ligne.TypeEquipement);
  if Typ = TrimRight(TypeEquipWe) then Result := ChercheArme(Ligne.CodeEquipement).Libelle
  else if Typ = TrimRight(TypeEquipAr) then Result := ChercheArmure(Ligne.CodeEquipement).Libelle
  else if Typ = TrimRight(TypeEquipArS) then Result := ChercheArmureSimplifiee(Ligne.CodeEquipement).Libelle
  else Result := ChercheTrapping(Ligne.CodeEquipement).Libelle;
  if Result = '' then Result := Ligne.CodeEquipement;
end;

function ListeObjetsSurBien(const Directory, GroupeId, IdBien: String): TStringList;
var
  Membres:           TStringList;
  I:                 Integer;
  FichierPersonnage: String;
  Perso:             StructurePersonnage;
  Ligne:             StructurePersonnageEquipement;
begin
  Result := TStringList.Create;
  if (GroupeId = '') or (IdBien = '') then Exit;
  Membres := ListeMembresGroupe(Directory, GroupeId);
  try
    for I := 0 to Membres.Count - 1 do
      begin
        FichierPersonnage := PersonnageXmlFichierActuel(IncludeTrailingPathDelimiter(Directory) + Membres[I]);
        if FichierPersonnage = '' then continue;
        Perso := PersonnageXmlChargement(FichierPersonnage);
        for Ligne in Perso.Equipement do
          if Ligne.PortePar = IdBien then
            Result.Add(Membres[I] + ' - ' + EquipementLigneLibelle(Ligne));
      end;
  finally
    Membres.Free;
  end;
end;

end.

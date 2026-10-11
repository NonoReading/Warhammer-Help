unit TraductionTexte;

{$mode ObjFPC}{$H+}

// Textes traduisibles d'un livre XML (balises portant language= et libelles <Text name=> de DATA_LABEL), avec la
// cle qui permet d'apparier un texte du livre source et sa traduction. Partage entre la grille de traduction de
// WinLivre (PanelTraduction) et le taux de traduction du menu des livres (CompterTraduction).
//
// Cle = chaine des id= des ancetres + balise (ou name= d'un libelle). Chaine = les ancetres du texte (balise +
// attribut id/name), de quoi le recreer dans un livre de traduction ou il n'existe pas encore.

interface

uses
  Classes, SysUtils, DOM, UnitCalcul;

const
  SepAttr = #1;  // dans un segment de chaine : balise, nom de l'attribut, valeur de l'attribut
  SepSeg = #2;   // entre deux segments de chaine

type
  TCollecte = class
    Cles, Codes, Champs, Valeurs, Chaines, Occurrences, Vus: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Ajouter(Cle, Code, Champ, Valeur, Chaine: String);
  end;

// Texte de la balise de l'en-tete (language), tel qu'ecrit dans le fichier.
function LangueBrute(Doc: TDOMDocument): String;
// Remplit C avec tous les textes traduisibles de Doc, dans l'ordre du livre.
procedure Collecter(Doc: TDOMDocument; C: TCollecte);
// Nombre de textes du livre source et nombre de ceux qui ont une traduction non vide dans le livre de traduction.
procedure CompterTraduction(Source, Traduction: TDOMDocument; out Traduits, Total: Integer);

implementation

function ValeurNoeud(Node: TDOMNode): String;
begin
  Result := '';
  if Node = nil then Exit;
  Result := RemoveQuotes(Trim(Node.TextContent));
end;

constructor TCollecte.Create;
begin
  Cles := TStringList.Create;
  Codes := TStringList.Create;
  Champs := TStringList.Create;
  Valeurs := TStringList.Create;
  Chaines := TStringList.Create;
  Occurrences := TStringList.Create;
  Vus := TStringList.Create;
  Vus.Sorted := True;
  Vus.CaseSensitive := True;
end;

destructor TCollecte.Destroy;
begin
  Cles.Free;
  Codes.Free;
  Champs.Free;
  Valeurs.Free;
  Chaines.Free;
  Occurrences.Free;
  Vus.Free;
  inherited Destroy;
end;

// Deux textes de meme cle (meme balise repetee chez un meme proprietaire) se distinguent par un rang.
procedure TCollecte.Ajouter(Cle, Code, Champ, Valeur, Chaine: String);
var
  N: Integer;
  Base: String;
begin
  Base := Cle;
  N := 0;
  while Vus.IndexOf(Cle) >= 0 do
  begin
    Inc(N);
    Cle := Base + '#' + IntToStr(N + 1);
  end;
  Vus.Add(Cle);
  Cles.Add(Cle);
  Codes.Add(Code);
  Champs.Add(Champ);
  Valeurs.Add(Valeur);
  Chaines.Add(Chaine);
  Occurrences.Add(IntToStr(N));
end;

// Texte de la balise de l'en-tete (language), tel qu'ecrit dans le fichier.
function LangueBrute(Doc: TDOMDocument): String;
var
  N: TDOMNode;
begin
  Result := '';
  if (Doc = nil) or (Doc.DocumentElement = nil) then Exit;
  N := Doc.DocumentElement.FindNode('language');
  if N <> nil then Result := ValeurNoeud(N);
end;

procedure Parcourir(E: TDOMElement; Chaine, Chemin, Dernier, Langue: String; C: TCollecte);
var
  Enfant: TDOMNode;
  Id, Lang, Segment, AttrNom, AttrVal: String;
  ADesEnfants: Boolean;
begin
  AttrNom := '';
  AttrVal := E.GetAttribute('id');
  if AttrVal <> '' then
    AttrNom := 'id'
  else if E.NodeName <> 'Text' then
  begin
    AttrVal := E.GetAttribute('name');
    if AttrVal <> '' then AttrNom := 'name';
  end;
  Id := AttrVal;
  Segment := E.NodeName + SepAttr + AttrNom + SepAttr + AttrVal;
  if Id <> '' then
  begin
    Chemin := Chemin + '/' + Id;
    Dernier := Id;
  end;

  ADesEnfants := False;
  Enfant := E.FirstChild;
  while Enfant <> nil do
  begin
    if Enfant.NodeType = ELEMENT_NODE then
    begin
      ADesEnfants := True;
      Break;
    end;
    Enfant := Enfant.NextSibling;
  end;

  Lang := UpperCase(E.GetAttribute('language'));
  if (Lang <> '') and not ADesEnfants and ((Langue = '') or (Lang = UpperCase(Langue))) then
    C.Ajouter(Chemin + '|' + E.NodeName, Dernier, E.NodeName, ValeurNoeud(E), Chaine + E.NodeName)
  else if (E.NodeName = 'Text') and (E.GetAttribute('name') <> '') and (E.ParentNode <> nil)
    and (E.ParentNode.NodeType = ELEMENT_NODE) then
  begin
    Lang := UpperCase(TDOMElement(E.ParentNode).GetAttribute('language'));
    if (Lang <> '') and ((Langue = '') or (Lang = UpperCase(Langue))) then
      C.Ajouter('LABEL|' + E.GetAttribute('name'), E.GetAttribute('name'), '', ValeurNoeud(E),
        'LABEL' + SepAttr + E.GetAttribute('name'));
  end;

  Enfant := E.FirstChild;
  while Enfant <> nil do
  begin
    if Enfant.NodeType = ELEMENT_NODE then
      Parcourir(TDOMElement(Enfant), Chaine + Segment + SepSeg, Chemin, Dernier, Langue, C);
    Enfant := Enfant.NextSibling;
  end;
end;

procedure Collecter(Doc: TDOMDocument; C: TCollecte);
var
  Enfant: TDOMNode;
  Langue: String;
begin
  if (Doc = nil) or (Doc.DocumentElement = nil) then Exit;
  Langue := LangueBrute(Doc);
  // La racine (DATA_BOOK) n'entre pas dans les chaines : on part de ses enfants.
  Enfant := Doc.DocumentElement.FirstChild;
  while Enfant <> nil do
  begin
    if Enfant.NodeType = ELEMENT_NODE then
      Parcourir(TDOMElement(Enfant), '', '', '', Langue, C);
    Enfant := Enfant.NextSibling;
  end;
end;

procedure CompterTraduction(Source, Traduction: TDOMDocument; out Traduits, Total: Integer);
var
  CS, CT: TCollecte;
  Index: TStringList;
  I, Pos: Integer;
begin
  Traduits := 0;
  Total := 0;
  CS := TCollecte.Create;
  CT := TCollecte.Create;
  Index := TStringList.Create;
  try
    Collecter(Source, CS);
    Collecter(Traduction, CT);
    Index.Sorted := True;
    Index.CaseSensitive := True;
    for I := 0 to CT.Cles.Count - 1 do
      Index.AddObject(CT.Cles[I], TObject(PtrInt(I)));
    Total := CS.Cles.Count;
    for I := 0 to CS.Cles.Count - 1 do
    begin
      Pos := Index.IndexOf(CS.Cles[I]);
      if (Pos >= 0) and (CT.Valeurs[PtrInt(Index.Objects[Pos])] <> '') then Inc(Traduits);
    end;
  finally
    CS.Free;
    CT.Free;
    Index.Free;
  end;
end;

end.

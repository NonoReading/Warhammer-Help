unit PanelCarrieresCoches;

{$mode ObjFPC}{$H+}

// Metiers d'entree (<Entries>) ou de sortie (<Exits> + <ExitCodes>) d'une carriere WFRP2 en cases a cocher :
// toutes les carrieres connues sont proposees, celles du livre sont cochees.
// Le livre garde ses deux textes (noms) et ses codes ; tant que les cases sont celles du chargement,
// les valeurs d'origine sont rendues telles quelles (aucune donnee ne bouge sans saisie).
// Le panneau se glisse sous les champs de TPanelFiche (propriete Extra), sans champ propre.

interface

uses
  BCLabelContour, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, CheckLst, DOM, ChargeTexte, PanelModificateurs, PanelFiche;

type
  TPanelCarrieresCoches = class(TPanelExtraFiche)
  private
    FSorties: Boolean;          // False = Entries (noms seuls), True = Exits + ExitCodes
    FListe: TCheckListBox;
    FTitre: TLabel;
    FCodes: TStringList;        // code de chaque case ('' = metier du livre connu par son nom seulement)
    FNoms: TStringList;         // nom de chaque case (texte du livre)
    FChoix: TStringList;        // proposition : code=nom
    FOrigNoms, FOrigCodes: String;
    FSignatureInitiale: String;
    function  SignatureCases: String;
    function  CleCase(I: Integer): String;
    procedure EcrireBalise(Element: TDOMElement; const Balise, Valeur, Apres: String);
    function  Decouper(const Texte: String): TStringList;
  public
    constructor Create(AOwner: TComponent; Sorties: Boolean); reintroduce;
    destructor Destroy; override;
    // carrieres proposees : lignes « code=nom » (a appeler avant Charger)
    procedure Preparer(Choix: TStrings);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

constructor TPanelCarrieresCoches.Create(AOwner: TComponent; Sorties: Boolean);
begin
  inherited Create(AOwner);
  FSorties := Sorties;
  BevelOuter := bvNone;
  Caption := '';
  Height := 430;
  FCodes := TStringList.Create;
  FNoms := TStringList.Create;
  FChoix := TStringList.Create;
  FTitre := TLabelContour.Create(Self);
  FTitre.Parent := Self;
  FTitre.SetBounds(0, 0, 400, 20);
  if Sorties then FTitre.Caption := GetTexteLibelle('RULES-LAB_704') else FTitre.Caption := GetTexteLibelle('RULES-LAB_703');
  FListe := TCheckListBox.Create(Self);
  FListe.Parent := Self;
  FListe.SetBounds(0, 24, 500, 400);
  Visible := False;
end;

destructor TPanelCarrieresCoches.Destroy;
begin
  FCodes.Free;
  FNoms.Free;
  FChoix.Free;
  inherited Destroy;
end;

procedure TPanelCarrieresCoches.Preparer(Choix: TStrings);
begin
  FChoix.Assign(Choix);
end;

function TPanelCarrieresCoches.Decouper(const Texte: String): TStringList;
var
  I: Integer;
begin
  Result := TStringList.Create;
  Result.Delimiter := ',';
  Result.StrictDelimiter := True;
  Result.DelimitedText := Texte;
  for I := Result.Count - 1 downto 0 do
  begin
    Result[I] := Trim(Result[I]);
    if Result[I] = '' then Result.Delete(I);
  end;
end;

// cle d'une case : le code pour les sorties (quand il existe), sinon le nom
function TPanelCarrieresCoches.CleCase(I: Integer): String;
begin
  if FSorties and (FCodes[I] <> '') then Result := FCodes[I]
  else Result := FNoms[I];
end;

procedure TPanelCarrieresCoches.Charger(Element: TDOMElement);
var
  Noms, Codes: TStringList;
  I, J, K: Integer;
  Code, Nom: String;
  Coche: array of Boolean;
begin
  if FSorties then FOrigNoms := ValeurXML(Element.FindNode('Exits'))
  else FOrigNoms := ValeurXML(Element.FindNode('Entries'));
  if FSorties then FOrigCodes := ValeurXML(Element.FindNode('ExitCodes')) else FOrigCodes := '';
  FCodes.Clear;
  FNoms.Clear;
  FListe.Items.Clear;
  for I := 0 to FChoix.Count - 1 do
  begin
    FCodes.Add(FChoix.Names[I]);
    FNoms.Add(FChoix.ValueFromIndex[I]);
  end;
  SetLength(Coche, FCodes.Count);
  for I := 0 to High(Coche) do Coche[I] := False;
  Noms := Decouper(FOrigNoms);
  Codes := Decouper(FOrigCodes);
  try
    if FSorties and (Codes.Count > 0) then
    begin
      // codes du livre ; un code hors de la proposition devient une case de plus, nommee d'apres le texte
      for K := 0 to Codes.Count - 1 do
      begin
        J := FCodes.IndexOf(Codes[K]);
        if J < 0 then
        begin
          if (Noms.Count = Codes.Count) then Nom := Noms[K] else Nom := Codes[K];
          FCodes.Add(Codes[K]);
          FNoms.Add(Nom);
          SetLength(Coche, FCodes.Count);
          J := FCodes.Count - 1;
        end;
        Coche[J] := True;
      end;
    end
    else
    begin
      // noms seuls : retrouves par leur nom, sinon une case de plus sans code
      for K := 0 to Noms.Count - 1 do
      begin
        J := FNoms.IndexOf(Noms[K]);
        if J < 0 then
        begin
          FCodes.Add('');
          FNoms.Add(Noms[K]);
          SetLength(Coche, FCodes.Count);
          J := FCodes.Count - 1;
        end;
        Coche[J] := True;
      end;
    end;
  finally
    Noms.Free;
    Codes.Free;
  end;
  for I := 0 to FNoms.Count - 1 do
  begin
    Code := FNoms[I];
    FListe.Items.Add(Code);
    FListe.Checked[I] := Coche[I];
  end;
  FSignatureInitiale := SignatureCases;
end;

function TPanelCarrieresCoches.SignatureCases: String;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FListe.Items.Count - 1 do
    if FListe.Checked[I] then Result := Result + '|' + CleCase(I);
end;

function TPanelCarrieresCoches.Controler: Boolean;
begin
  Result := True;
end;

function TPanelCarrieresCoches.Signature(const Sep: String): String;
begin
  Result := Sep + SignatureCases;
end;

procedure TPanelCarrieresCoches.EcrireBalise(Element: TDOMElement; const Balise, Valeur, Apres: String);
var
  N, Suivant: TDOMNode;
begin
  N := Element.FindNode(Balise);
  if N = nil then
  begin
    if Valeur = '' then Exit;
    N := Element.OwnerDocument.CreateElement(Balise);
    Suivant := Element.FirstChild;
    while (Suivant <> nil) and not ((Suivant.NodeType = ELEMENT_NODE) and (Pos(',' + Suivant.NodeName + ',', Apres) > 0)) do
      Suivant := Suivant.NextSibling;
    Element.InsertBefore(N, Suivant);
  end;
  EcrireValeurXML(TDOMElement(N), Valeur);
end;

procedure TPanelCarrieresCoches.Ecrire(Element: TDOMElement);
var
  I: Integer;
  Noms, Codes: String;
begin
  if SignatureCases = FSignatureInitiale then
  begin
    // cases inchangees : textes et codes d'origine rendus tels quels
    Noms := FOrigNoms;
    Codes := FOrigCodes;
  end
  else
  begin
    Noms := '';
    Codes := '';
    for I := 0 to FListe.Items.Count - 1 do
      if FListe.Checked[I] then
      begin
        if Noms <> '' then Noms := Noms + ', ';
        Noms := Noms + FNoms[I];
        if FCodes[I] <> '' then
        begin
          if Codes <> '' then Codes := Codes + ',';
          Codes := Codes + FCodes[I];
        end;
      end;
  end;
  if FSorties then
  begin
    EcrireBalise(Element, 'Exits', Noms, ',ExitCodes,Basic,StartMoney,Source,Page,');
    EcrireBalise(Element, 'ExitCodes', Codes, ',Basic,StartMoney,Source,Page,');
  end
  else
    EcrireBalise(Element, 'Entries', Noms, ',Exits,ExitCodes,Basic,StartMoney,Source,Page,');
end;

procedure TPanelCarrieresCoches.MettreLectureSeule(Valeur: Boolean);
begin
  FListe.Enabled := not Valeur;
end;

end.

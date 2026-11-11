unit FenetreApprentissageV1;

{$mode ObjFPC}{$H+}

// WFRP 1re edition : fenetre "Apprendre un sort" de WinPersonnage (Core p.136-137, Learning Spells).
// Un sort s'apprend si la liste est ouverte par une carriere deja atteinte, si son niveau n'est pas
// superieur a celui de la carriere, si le personnage a les EP et reussit un test d'Intelligence
// (modificateur par niveau de sort, 96-100 rate toujours pour Petty et niveau 1). Un echec ne coute
// rien ; on ne retente qu'avec une autre source ou une Intelligence plus haute.

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Grids, Dialogs, MessageTest,
  Graphics, GlobalFonts, ChargeTexte, ChargePersonnage, ChargeSort, ChargeMetierAttribut, ChargeRacePhysique, ChargeConstantes;

type
  PPersonnageV1 = ^StructurePersonnage;

// Rend True si quelque chose a change dans le personnage (sort appris ou echec note) ; les codes des sorts
// appris pendant l'appel sont ajoutes a Appris. Intelligence = valeur courante, XpDispo = EP disponibles.
function ApprendreSortV1(Proprietaire: TComponent; Personnage: PPersonnageV1; Intelligence, XpDispo: Integer;
  Appris, Oublies: TStrings): Boolean;
// Le personnage a-t-il une carriere de magicien (hors clerc et druide) qui lui ouvre des sorts ?
function PeutApprendreSortsV1(const Personnage: StructurePersonnage): Boolean;
// Carriere de magicien en cours avec moins de 2 sorts connus alors qu'un sort au moins reste apprenable
// (Core : au moins 2 sorts appris avant de passer au niveau suivant, si disponibles)
function SortsInsuffisantsV1(const Personnage: StructurePersonnage): Boolean;

// Le personnage est-il Initiate ou Priest d'un culte (il peut alors petitionner son dieu pour de nouvelles prieres) ?
function PeutPetitionnerV1(const Personnage: StructurePersonnage): Boolean;
// Fenetre de petition (Realm of Divine Magic p.32-34) : prieres du culte accessibles au rang du clerc, 50 EP (Petty) ou
// 100 EP (rangs 1 a 4), jet sur la table Granting New Prayers. Les prieres accordees sont ajoutees a SortsV1 et a Appris ;
// EpPerdus recoit les EP payes pour une petition sans priere. Rend True si quelque chose a change.
function PetitionPrieresV1(Proprietaire: TComponent; Personnage: PPersonnageV1; XpDispo: Integer;
  Appris: TStrings; var EpPerdus: Integer): Boolean;
// Fenetre de choix du culte de l'Initiate (Realm of Divine Magic) ; rend le code du culte, '' si rien n'est choisi
function ChoisirCulteV1(Proprietaire: TComponent): String;
// Les quatre prieres Petty accordees a l'entree dans la carriere d'Initiate (Realm of Divine Magic p.32), notees a 0 EP
// dans SortsV1 avec le culte pour source ; rend leurs libelles separes par des virgules
function AccordePrieresInitiateV1(var SortsV1: String; const Source: String): String;

const
  PrefixeTypeSortV1 = 'RULES-SPELLV1_';

implementation

type
  { TFenetreApprentissage }

  TFenetreApprentissage = class(TForm)
  private
    Perso:        PPersonnageV1;
    Int_:         Integer;
    Xp:           Integer;
    Appris:       TStrings;
    Oublies:      TStrings;
    BtnOublier:   TButton;
    Codes:       TStringList;
    Grille:       TStringGrid;
    LabInfo:      TLabel;
    EditSource:   TEdit;
    EditJet:      TEdit;
    BtnApprendre: TButton;
    BtnFermer:    TButton;
    function FacteurCout(): Integer;
    function NbSortsNonMineurs(): Integer;
    function NbSortsDuNiveau(const Niveau: String): Integer;
    procedure Remplit();
    procedure AfficheInfo();
    procedure ApprendreClick(Sender: TObject);
    procedure OublierClick(Sender: TObject);
  public
    Change: Boolean;
    constructor Cree(AProprietaire: TComponent; APerso: PPersonnageV1; AInt, AXp: Integer; AAppris, AOublies: TStrings);
    destructor Destroy; override;
  end;

function NiveauNumerique(const Niveau: String): Integer;
begin
  if ValeurLivreEgale(Niveau, 'P') then Result := 0
  else Result := StrToIntDef(Niveau, 99);
end;

// Codes des carrieres deja prises : anciennes + en cours
procedure CarrieresPrises(const Personnage: StructurePersonnage; Liste: TStrings);
var
  PMetier: StructurePersonnageMetier;
begin
  for PMetier in Personnage.MetierAncien do
    Liste.Add(PMetier.CodeMetier);
  if Personnage.MetierEnCours.CodeMetier <> '' then
    Liste.Add(Personnage.MetierEnCours.CodeMetier);
end;

// Niveau le plus haut de sort de cette liste que les carrieres atteintes permettent ; -1 = liste fermee
function NiveauMaxListe(const Personnage: StructurePersonnage; const Liste: String): Integer;
var
  Carrieres: TStringList;
  Code:      String;
  Ecole:     String;
  Niveau:    Integer;
  Max_:      Integer;
begin
  Result    := -1;
  Carrieres := TStringList.Create;
  try
    CarrieresPrises(Personnage, Carrieres);
    for Code in Carrieres do
      begin
        Ecole := EcoleMagieV1(Code);
        if (Ecole = '') or (ListesSortsEcoleV1(Ecole) = '') then Continue;
        if (';' + ListesSortsEcoleV1(Ecole) + ';').IndexOf(';' + Liste + ';') < 0 then Continue;
        Niveau := NiveauCarriereV1(Code);
        if Liste = 'Petty' then
          Max_ := 0
        else if Ecole = 'ALCHEMIST' then
          // un alchimiste ne lance que des sorts d'un niveau inferieur au sien, jamais le niveau 4
          begin
            Max_ := Niveau - 1;
            if Max_ > 3 then Max_ := 3;
            if Max_ < 1 then Continue;
          end
        else if Pos('WORK_RUNE_MASTER', UpperCase(Code)) > 0 then
          // le Rune Master n'a qu'un niveau mais connait les runes de niveau 1 a 3
          Max_ := 3
        else
          Max_ := Niveau;
        if Max_ > Result then Result := Max_;
      end;
  finally
    Carrieres.Free;
  end;
end;

function NiveauMagiqueMax(const Personnage: StructurePersonnage): Integer;
var
  Carrieres: TStringList;
  Code:      String;
begin
  Result    := 0;
  Carrieres := TStringList.Create;
  try
    CarrieresPrises(Personnage, Carrieres);
    for Code in Carrieres do
      if (ListesSortsEcoleV1(EcoleMagieV1(Code)) <> '') and (NiveauCarriereV1(Code) > Result) then
        Result := NiveauCarriereV1(Code);
  finally
    Carrieres.Free;
  end;
end;

function PeutApprendreSortsV1(const Personnage: StructurePersonnage): Boolean;
begin
  Result := NiveauMagiqueMax(Personnage) > 0;
end;

// Sorts Petty gratuits encore a prendre : 2 si l'Apprenti Wizard est la premiere carriere, 1 a chaque entree
// ulterieure (Core p.137). Un sort gratuit est note a 0 EP dans SortsV1.
function SortsGratuitsRestantsV1(const Personnage: StructurePersonnage): Integer;
var
  Carrieres: TStringList;
  Reste:     String;
  Item:      String;
  Champs:    TStringArray;
  I:         Integer;
begin
  Result    := 0;
  Carrieres := TStringList.Create;
  try
    CarrieresPrises(Personnage, Carrieres);
    for I := 0 to Carrieres.Count - 1 do
      if (EcoleMagieV1(Carrieres[I]) = 'WIZARD') and (NiveauCarriereV1(Carrieres[I]) = 1) then
        if I = 0 then Inc(Result, 2) else Inc(Result);
  finally
    Carrieres.Free;
  end;
  Reste := Personnage.SortsV1;
  while Reste <> '' do
    begin
      Item   := ElementSuivantV1(Reste);
      Champs := Item.Split('|');
      if (Length(Champs) >= 3) and (Champs[2] = '0') and ValeurLivreEgale(ChercheSort(Champs[0]).Niveau, 'P') then
        Dec(Result);
    end;
  if Result < 0 then Result := 0;
end;

function SortsInsuffisantsV1(const Personnage: StructurePersonnage): Boolean;
var
  Reste: String;
  Nb:    Integer;
  PSort: StructureSort;
  Max_:  Integer;
begin
  Result := False;
  if ListesSortsEcoleV1(EcoleMagieV1(Personnage.MetierEnCours.CodeMetier)) = '' then Exit;
  Nb    := 0;
  Reste := Personnage.SortsV1;
  while Reste <> '' do
    begin
      ElementSuivantV1(Reste);
      Inc(Nb);
    end;
  if Nb >= 2 then Exit;
  for PSort in ListSort do
    begin
      if Copy(PSort.TypeSort, 1, Length(PrefixeTypeSortV1)) <> PrefixeTypeSortV1 then Continue;
      if SortConnuV1(Personnage.SortsV1, PSort.CodeSort) then Continue;
      Max_ := NiveauMaxListe(Personnage, PSort.ListesSorts);
      if (Max_ < 0) or (NiveauNumerique(PSort.Niveau) > Max_) then Continue;
      if ApprentissageSortV1(PSort.Niveau).CoutEP = 0 then Continue;
      Result := True;
      Exit;
    end;
end;

{ TFenetreApprentissage }

constructor TFenetreApprentissage.Cree(AProprietaire: TComponent; APerso: PPersonnageV1; AInt, AXp: Integer;
  AAppris, AOublies: TStrings);
var
  LabSource: TLabel;
  LabJet:    TLabel;
begin
  inherited CreateNew(AProprietaire);
  Perso       := APerso;
  Int_        := AInt;
  Xp          := AXp;
  Appris      := AAppris;
  Oublies     := AOublies;
  Codes      := TStringList.Create;
  Caption     := GetTexteLibelle('RULES-LAB_845');
  Position    := poOwnerFormCenter;
  BorderStyle := bsDialog;
  ClientWidth := 760;
  ClientHeight := 520;

  LabInfo          := TLabel.Create(Self);
  LabInfo.Parent   := Self;
  LabInfo.SetBounds(10, 10, 740, 20);

  Grille           := TStringGrid.Create(Self);
  Grille.Parent    := Self;
  Grille.SetBounds(10, 40, 740, 350);
  Grille.ColCount  := 5;
  Grille.RowCount  := 1;
  Grille.FixedCols := 0;
  Grille.Options   := Grille.Options + [goRowSelect] - [goRangeSelect];
  Grille.ColWidths[0] := 280;
  Grille.ColWidths[1] := 170;
  Grille.ColWidths[2] := 70;
  Grille.ColWidths[3] := 100;
  Grille.ColWidths[4] := 100;
  Grille.Cells[0, 0]  := GetTexteLibelle('RULES-LAB_846');
  Grille.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_847');
  Grille.Cells[2, 0]  := GetTexteLibelle('RULES-LAB_848');
  Grille.Cells[3, 0]  := GetTexteLibelle('RULES-LAB_849');
  Grille.Cells[4, 0]  := GetTexteLibelle('RULES-LAB_850');

  LabSource        := TLabel.Create(Self);
  LabSource.Parent := Self;
  LabSource.SetBounds(10, 405, 740, 20);
  LabSource.Caption := GetTexteLibelle('RULES-LAB_851');
  EditSource        := TEdit.Create(Self);
  EditSource.Parent := Self;
  EditSource.SetBounds(10, 427, 740, 24);

  LabJet           := TLabel.Create(Self);
  LabJet.Parent    := Self;
  LabJet.SetBounds(10, 462, 430, 20);
  LabJet.Caption   := GetTexteLibelle('RULES-LAB_852');
  EditJet          := TEdit.Create(Self);
  EditJet.Parent   := Self;
  EditJet.SetBounds(445, 458, 60, 24);

  BtnApprendre         := TButton.Create(Self);
  BtnApprendre.Parent  := Self;
  BtnApprendre.SetBounds(530, 480, 100, 30);
  BtnApprendre.Caption := GetTexteLibelle('RULES-LAB_853');
  BtnApprendre.OnClick := @ApprendreClick;
  BtnOublier           := TButton.Create(Self);
  BtnOublier.Parent    := Self;
  BtnOublier.SetBounds(10, 480, 250, 30);
  BtnOublier.Caption   := GetTexteLibelle('RULES-LAB_857');
  BtnOublier.OnClick   := @OublierClick;
  BtnFermer            := TButton.Create(Self);
  BtnFermer.Parent     := Self;
  BtnFermer.SetBounds(645, 480, 100, 30);
  BtnFermer.Caption    := GetTexteLibelle('RULES-LAB_854');
  BtnFermer.ModalResult := mrClose;

  Remplit();
  AfficheInfo();
  // charte : fond noir du formulaire, controles styles en bloc comme les autres fenetres
  Color := clBlack;
  MiseAJourUnContenaire(Self);
end;

destructor TFenetreApprentissage.Destroy;
begin
  Codes.Free;
  inherited Destroy;
end;

// Petty / Battle... : x2 en EP si la carriere en cours n'est pas magique (Core p.137)
function TFenetreApprentissage.FacteurCout(): Integer;
begin
  Result := 1;
  if EcoleMagieV1(Perso^.MetierEnCours.CodeMetier) = '' then
    Result := 2;
end;

function TFenetreApprentissage.NbSortsNonMineurs(): Integer;
var
  Reste: String;
  Item:  String;
begin
  Result := 0;
  Reste  := Perso^.SortsV1;
  while Reste <> '' do
    begin
      Item := ElementSuivantV1(Reste);
      if not ValeurLivreEgale(ChercheSort(Copy(Item, 1, Pos('|', Item + '|') - 1)).Niveau, 'P') then
        Inc(Result);
    end;
end;

function TFenetreApprentissage.NbSortsDuNiveau(const Niveau: String): Integer;
var
  Reste: String;
  Item:  String;
begin
  Result := 0;
  Reste  := Perso^.SortsV1;
  while Reste <> '' do
    begin
      Item := ElementSuivantV1(Reste);
      if ValeurLivreEgale(ChercheSort(Copy(Item, 1, Pos('|', Item + '|') - 1)).Niveau, Niveau) then
        Inc(Result);
    end;
end;

procedure TFenetreApprentissage.Remplit();
var
  PSort:  StructureSort;
  Regle:  StructureApprentissageSortV1;
  Max_:   Integer;
  Ligne:  Integer;
begin
  Grille.RowCount := 1;
  Codes.Clear;
  for PSort in ListSort do
    begin
      if Copy(PSort.TypeSort, 1, Length(PrefixeTypeSortV1)) <> PrefixeTypeSortV1 then Continue;
      if SortConnuV1(Perso^.SortsV1, PSort.CodeSort) then Continue;
      Max_ := NiveauMaxListe(Perso^, PSort.ListesSorts);
      if (Max_ < 0) or (NiveauNumerique(PSort.Niveau) > Max_) then Continue;
      Regle := ApprentissageSortV1(PSort.Niveau);
      if Regle.CoutEP = 0 then Continue;
      Grille.RowCount := Grille.RowCount + 1;
      Ligne           := Grille.RowCount - 1;
      Grille.Cells[0, Ligne] := PSort.Libelle;
      Grille.Cells[1, Ligne] := GetTexteLibelle(PSort.TypeSort);
      Grille.Cells[2, Ligne] := LibelleValeurLivre(PSort.Niveau);
      if ValeurLivreEgale(PSort.Niveau, 'P') and (SortsGratuitsRestantsV1(Perso^) > 0) then
        Grille.Cells[3, Ligne] := '0'
      else
        begin
          Grille.Cells[3, Ligne] := IntToStr(Regle.CoutEP * FacteurCout());
          // Hedge-Wizard : double cout hors Petty (Realms of Sorcery p.30)
          if not ValeurLivreEgale(PSort.Niveau, 'P') and (EcoleMagieV1(Perso^.MetierEnCours.CodeMetier) = 'HEDGE') then
            Grille.Cells[3, Ligne] := IntToStr(Regle.CoutEP * 2);
        end;
      Grille.Cells[4, Ligne] := IntToStr(SeuilApprentissageSortV1(PSort.Niveau, Int_));
      Codes.Add(PSort.CodeSort);
    end;
end;

procedure TFenetreApprentissage.AfficheInfo();
begin
  LabInfo.Caption := GetTexteLibelle('RULES-LAB_855') + ' : ' + IntToStr(Int_) + '    ' +
                     GetTexteLibelle('RULES-LAB_856') + ' : ' + IntToStr(Xp);
end;

procedure TFenetreApprentissage.ApprendreClick(Sender: TObject);
var
  Ligne:  Integer;
  Code:   String;
  Cout:   Integer;
  Seuil:  Integer;
  Jet:    Integer;
  Niveau: String;
  Libelle: String;
  Source: String;
  Reussi: Boolean;
begin
  Ligne := Grille.Row;
  if (Ligne < 1) or (Ligne > Codes.Count) then
    begin
      ShowMessage(GetTexteLibelle('RULES-MESS_096'));
      Exit;
    end;
  Code    := Codes[Ligne - 1];
  Libelle := Grille.Cells[0, Ligne];
  Niveau  := ChercheSort(Code).Niveau;   // la colonne 2 affiche le libelle traduit : on relit le niveau du livre
  Cout    := StrToIntDef(Grille.Cells[3, Ligne], 0);
  Seuil   := StrToIntDef(Grille.Cells[4, Ligne], 0);
  Source  := EditSource.Text;
  // sort Petty de depart de l'Apprenti : donne, sans jet ni EP
  if ValeurLivreEgale(Niveau, 'P') and (Cout = 0) then
    begin
      AjouteSortV1(Perso^.SortsV1, Code, Source, 0);
      Appris.Add(Code);
      Change := True;
      ShowMessage(GetTexteLibelle('RULES-MESS_093') + ' ' + Libelle);
      Remplit();
      AfficheInfo();
      Exit;
    end;
  if Xp < Cout then
    begin
      ShowMessage(GetTexteLibelle('RULES-MESS_091'));
      Exit;
    end;
  if not EssaiPossibleSortV1(Perso^.EchecsSortsV1, Code, Source, Int_) then
    begin
      ShowMessage(GetTexteLibelle('RULES-MESS_092'));
      Exit;
    end;
  // sorts autres que Petty : (Intelligence / 10) x niveau magique (Core p.137)
  if not ValeurLivreEgale(Niveau, 'P') and (NbSortsNonMineurs() >= (Int_ div 10) * NiveauMagiqueMax(Perso^)) then
    begin
      ShowMessage(GetTexteLibelle('RULES-MESS_095'));
      Exit;
    end;
  // Hedge-Wizard : au plus 4 sorts hors Petty par niveau (Realms of Sorcery p.30)
  if not ValeurLivreEgale(Niveau, 'P') and (EcoleMagieV1(Perso^.MetierEnCours.CodeMetier) = 'HEDGE') and
     (NbSortsDuNiveau(Niveau) >= 4) then
    begin
      ShowMessage(GetTexteLibelle('RULES-MESS_110'));
      Exit;
    end;
  if Trim(EditJet.Text) = '' then
    Jet := LanceFormule('1D100', False)
  else
    begin
      Jet := StrToIntDef(Trim(EditJet.Text), 0);
      if (Jet < 1) or (Jet > 100) then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_097'));
          Exit;
        end;
    end;
  Reussi := (not EchecAutoApprentissageV1(Niveau, Jet)) and (Jet <= Seuil);
  Change := True;
  if Reussi then
    begin
      AjouteSortV1(Perso^.SortsV1, Code, Source, Cout);
      Xp := Xp - Cout;
      Appris.Add(Code);
      ShowMessage(GetTexteLibelle('RULES-MESS_093') + ' ' + Libelle + ' [d100 = ' + IntToStr(Jet) + ' / ' + IntToStr(Seuil) + ']');
    end
  else
    begin
      AjouteEchecSortV1(Perso^.EchecsSortsV1, Code, Source, Int_);
      ShowMessage(GetTexteLibelle('RULES-MESS_094') + ' ' + Libelle + ' [d100 = ' + IntToStr(Jet) + ' / ' + IntToStr(Seuil) + ']');
    end;
  EditJet.Text := '';
  Remplit();
  AfficheInfo();
end;

// Si l'Intelligence a baisse, les sorts en trop (hors Petty) sont oublies, tires au hasard (Core p.137)
procedure TFenetreApprentissage.OublierClick(Sender: TObject);
var
  Liste:  TStringList;
  Reste:  String;
  Item:   String;
  Code:   String;
  Excedent, Choix, I: Integer;
  Nouvelle: String;
begin
  Liste := TStringList.Create;
  try
    Reste := Perso^.SortsV1;
    while Reste <> '' do
      begin
        Item := ElementSuivantV1(Reste);
        Code := Copy(Item, 1, Pos('|', Item + '|') - 1);
        if not ValeurLivreEgale(ChercheSort(Code).Niveau, 'P') then
          Liste.Add(Code);
      end;
    Excedent := Liste.Count - (Int_ div 10) * NiveauMagiqueMax(Perso^);
    if Excedent <= 0 then
      begin
        ShowMessage(GetTexteLibelle('RULES-MESS_105'));
        Exit;
      end;
    for I := 1 to Excedent do
      begin
        Choix := LanceFormule('1D' + IntToStr(Liste.Count), False) - 1;
        Code  := Liste[Choix];
        Liste.Delete(Choix);
        // retire le sort de la liste du personnage
        Nouvelle := '';
        Reste    := Perso^.SortsV1;
        while Reste <> '' do
          begin
            Item := ElementSuivantV1(Reste);
            if Copy(Item, 1, Pos('|', Item + '|') - 1) <> Code then
              begin
                if Nouvelle <> '' then Nouvelle := Nouvelle + ';';
                Nouvelle := Nouvelle + Item;
              end;
          end;
        Perso^.SortsV1 := Nouvelle;
        Oublies.Add(Code);
        Change := True;
        ShowMessage(GetTexteLibelle('RULES-MESS_106') + ' ' + ChercheSort(Code).Libelle);
      end;
    Remplit();
  finally
    Liste.Free;
  end;
end;

function ChoisirCulteV1(Proprietaire: TComponent): String;
var
  Fenetre: TForm;
  Liste:   TListBox;
  Bouton:  TButton;
  PCulte:  StructureCulteV1;
begin
  Result := '';
  if ListCulteV1.Count = 0 then Exit;
  Fenetre := TForm.CreateNew(Proprietaire);
  try
    Fenetre.Caption      := GetTexteLibelle('RULES-LAB_858');
    Fenetre.Position     := poOwnerFormCenter;
    Fenetre.BorderStyle  := bsDialog;
    Fenetre.ClientWidth  := 400;
    Fenetre.ClientHeight := 420;
    Liste        := TListBox.Create(Fenetre);
    Liste.Parent := Fenetre;
    Liste.SetBounds(10, 10, 380, 360);
    for PCulte in ListCulteV1 do
      Liste.Items.Add(PCulte.Libelle);
    Liste.ItemIndex := 0;
    Bouton             := TButton.Create(Fenetre);
    Bouton.Parent      := Fenetre;
    Bouton.SetBounds(290, 380, 100, 30);
    Bouton.Caption     := GetTexteLibelle('RULES-LAB_859');
    Bouton.ModalResult := mrOk;
    Fenetre.Color := clBlack;
    MiseAJourUnContenaire(Fenetre);
    if (Fenetre.ShowModal = mrOk) and (Liste.ItemIndex >= 0) then
      Result := ListCulteV1[Liste.ItemIndex].Code;
  finally
    Fenetre.Free;
  end;
end;

function AccordePrieresInitiateV1(var SortsV1: String; const Source: String): String;
const
  Prieres: array[1..4] of String = ('WRDM-PRAYER_PETTY_BLESS_TOKEN', 'WRDM-PRAYER_PETTY_BLESSED_SACRAMENTS',
                                    'WRDM-PRAYER_PETTY_HEAL_CULTIST', 'WRDM-PRAYER_PETTY_KNOW_FOLLOWER');
var
  I:     Integer;
  PSort: StructureSort;
begin
  Result := '';
  for I := Low(Prieres) to High(Prieres) do
    begin
      PSort := ChercheSort(Prieres[I]);
      if (PSort.CodeSort = '') or SortConnuV1(SortsV1, Prieres[I]) then Continue;
      AjouteSortV1(SortsV1, Prieres[I], Source, 0);
      if Result <> '' then Result := Result + ', ';
      Result := Result + PSort.Libelle;
    end;
end;

function ApprendreSortV1(Proprietaire: TComponent; Personnage: PPersonnageV1; Intelligence, XpDispo: Integer;
  Appris, Oublies: TStrings): Boolean;
var
  Fenetre: TFenetreApprentissage;
begin
  Fenetre := TFenetreApprentissage.Cree(Proprietaire, Personnage, Intelligence, XpDispo, Appris, Oublies);
  try
    Fenetre.ShowModal;
    Result := Fenetre.Change;
  finally
    Fenetre.Free;
  end;
end;

// Niveau de clerc : 0 = Initiate, 1 a 4 = Priest, -1 = ni l'un ni l'autre
function NiveauClercV1(const CodeMetier: String): Integer;
var
  Code: String;
begin
  Result := -1;
  Code   := UpperCase(CodeMetier);
  if EstInitiateV1(Code) then
    Result := 0
  else if Pos('WRDM-WORK_PRIEST_', Code) = 1 then
    Result := StrToIntDef(Copy(Code, Length('WRDM-WORK_PRIEST_') + 1, 5), -1);
end;

function PeutPetitionnerV1(const Personnage: StructurePersonnage): Boolean;
begin
  Result := (Personnage.CulteV1 <> '') and (NiveauClercV1(Personnage.MetierEnCours.CodeMetier) >= 0);
end;

type
  { TFenetrePetition }

  TFenetrePetition = class(TForm)
  private
    Perso:     PPersonnageV1;
    Xp:        Integer;
    Appris:    TStrings;
    Perdus:    Integer;
    Codes:     TStringList;
    Grille:    TStringGrid;
    LabInfo:   TLabel;
    EditJet:   TEdit;
    CaseDieu:  TCheckBox;
    BtnPetition: TButton;
    BtnFermer: TButton;
    procedure Remplit();
    procedure AfficheInfo();
    function  PrioreAuHasard(const Exclue: String): String;
    procedure Accorde(const Code: String; Cout: Integer);
    procedure PetitionClick(Sender: TObject);
  public
    Change: Boolean;
    constructor Cree(AProprietaire: TComponent; APerso: PPersonnageV1; AXp: Integer; AAppris: TStrings);
    destructor Destroy; override;
    property EpPerdus: Integer read Perdus;
  end;

const
  CoutPetitionPetty = 50;
  CoutPetitionRang  = 100;

function RangNumeriquePriere(const Rang: String): Integer;
begin
  if Rang = 'INITIATE' then Result := 0
  else Result := StrToIntDef(Rang, 99);
end;

constructor TFenetrePetition.Cree(AProprietaire: TComponent; APerso: PPersonnageV1; AXp: Integer; AAppris: TStrings);
var
  LabJet: TLabel;
begin
  inherited CreateNew(AProprietaire);
  Perso   := APerso;
  Xp      := AXp;
  Appris  := AAppris;
  Perdus  := 0;
  Codes   := TStringList.Create;
  Caption := GetTexteLibelle('RULES-LAB_865') + ' : ' + ChercheCulteV1(Perso^.CulteV1).Libelle;
  Position     := poOwnerFormCenter;
  BorderStyle  := bsDialog;
  ClientWidth  := 760;
  ClientHeight := 500;

  LabInfo        := TLabel.Create(Self);
  LabInfo.Parent := Self;
  LabInfo.SetBounds(10, 10, 740, 20);

  Grille           := TStringGrid.Create(Self);
  Grille.Parent    := Self;
  Grille.SetBounds(10, 40, 740, 350);
  Grille.ColCount  := 4;
  Grille.RowCount  := 1;
  Grille.FixedCols := 0;
  Grille.Options   := Grille.Options + [goRowSelect] - [goRangeSelect];
  Grille.ColWidths[0] := 380;
  Grille.ColWidths[1] := 100;
  Grille.ColWidths[2] := 160;
  Grille.ColWidths[3] := 90;
  Grille.Cells[0, 0]  := GetTexteLibelle('RULES-LAB_846');
  Grille.Cells[1, 0]  := GetTexteLibelle('RULES-LAB_848');
  Grille.Cells[2, 0]  := GetTexteLibelle('RULES-LAB_862');
  Grille.Cells[3, 0]  := GetTexteLibelle('RULES-LAB_849');

  CaseDieu         := TCheckBox.Create(Self);
  CaseDieu.Parent  := Self;
  CaseDieu.SetBounds(10, 402, 740, 22);
  CaseDieu.Caption := GetTexteLibelle('RULES-LAB_864');

  LabJet         := TLabel.Create(Self);
  LabJet.Parent  := Self;
  LabJet.SetBounds(10, 438, 430, 20);
  LabJet.Caption := GetTexteLibelle('RULES-LAB_852');
  EditJet        := TEdit.Create(Self);
  EditJet.Parent := Self;
  EditJet.SetBounds(445, 434, 60, 24);

  BtnPetition         := TButton.Create(Self);
  BtnPetition.Parent  := Self;
  BtnPetition.SetBounds(530, 460, 100, 30);
  BtnPetition.Caption := GetTexteLibelle('RULES-LAB_863');
  BtnPetition.OnClick := @PetitionClick;
  BtnFermer             := TButton.Create(Self);
  BtnFermer.Parent      := Self;
  BtnFermer.SetBounds(645, 460, 100, 30);
  BtnFermer.Caption     := GetTexteLibelle('RULES-LAB_854');
  BtnFermer.ModalResult := mrClose;

  Remplit();
  AfficheInfo();
  Color := clBlack;
  MiseAJourUnContenaire(Self);
end;

destructor TFenetrePetition.Destroy;
begin
  Codes.Free;
  inherited Destroy;
end;

// Prieres de la liste du culte dont le niveau ne depasse pas le rang du clerc et qu'il ne connait pas encore
procedure TFenetrePetition.Remplit();
var
  PPriere: StructurePriereCulteV1;
  PSort:   StructureSort;
  Niveau:  Integer;
  Ligne:   Integer;
begin
  Grille.RowCount := 1;
  Codes.Clear;
  Niveau := NiveauClercV1(Perso^.MetierEnCours.CodeMetier);
  for PPriere in ListPriereCulteV1 do
    begin
      if PPriere.Culte <> Perso^.CulteV1 then Continue;
      if RangNumeriquePriere(PPriere.Rang) > Niveau then Continue;
      if SortConnuV1(Perso^.SortsV1, PPriere.CodePriere) then Continue;
      PSort := ChercheSort(PPriere.CodePriere);
      if PSort.CodeSort = '' then Continue;
      Grille.RowCount := Grille.RowCount + 1;
      Ligne           := Grille.RowCount - 1;
      Grille.Cells[0, Ligne] := PSort.Libelle;
      Grille.Cells[1, Ligne] := LibelleValeurLivre(PSort.Niveau);
      if PPriere.Genre = 'REQUIRED' then
        Grille.Cells[2, Ligne] := GetTexteLibelle('RULES-LAB_860')
      else
        Grille.Cells[2, Ligne] := GetTexteLibelle('RULES-LAB_861');
      if RangNumeriquePriere(PPriere.Rang) = 0 then
        Grille.Cells[3, Ligne] := IntToStr(CoutPetitionPetty)
      else
        Grille.Cells[3, Ligne] := IntToStr(CoutPetitionRang);
      Codes.Add(PPriere.CodePriere);
    end;
end;

procedure TFenetrePetition.AfficheInfo();
begin
  LabInfo.Caption := GetTexteLibelle('RULES-LAB_856') + ' : ' + IntToStr(Xp);
end;

// Priere au hasard parmi celles que le clerc peut recevoir, hors Exclue si une autre existe ; '' si aucune
function TFenetrePetition.PrioreAuHasard(const Exclue: String): String;
var
  Choix: TStringList;
  I:     Integer;
begin
  Result := '';
  Choix  := TStringList.Create;
  try
    for I := 0 to Codes.Count - 1 do
      if Codes[I] <> Exclue then Choix.Add(Codes[I]);
    if Choix.Count = 0 then
      Result := Exclue
    else
      Result := Choix[LanceFormule('1D' + IntToStr(Choix.Count), False) - 1];
  finally
    Choix.Free;
  end;
end;

procedure TFenetrePetition.Accorde(const Code: String; Cout: Integer);
begin
  AjouteSortV1(Perso^.SortsV1, Code, ChercheCulteV1(Perso^.CulteV1).Libelle, Cout);
  Appris.Add(Code);
end;

// Table Granting New Prayers (p.33) sans modificateur de piete ; le livre ne couvre pas 21-30 (traite comme 01-10)
// et donne 50 a deux lignes (traite comme 50-95)
procedure TFenetrePetition.PetitionClick(Sender: TObject);
var
  Ligne:     Integer;
  Demande:   String;
  Cout:      Integer;
  Jet:       Integer;
  Dieu:      Boolean;
  Accordee:  String;
  Paye:      Integer;
  Texte:     String;
begin
  Ligne := Grille.Row;
  if (Ligne < 1) or (Ligne > Codes.Count) then
    begin
      ShowMessage(GetTexteLibelle('RULES-MESS_096'));
      Exit;
    end;
  Demande := Codes[Ligne - 1];
  Cout    := StrToIntDef(Grille.Cells[3, Ligne], CoutPetitionRang);
  if Xp < Cout then
    begin
      ShowMessage(GetTexteLibelle('RULES-MESS_091'));
      Exit;
    end;
  if Trim(EditJet.Text) = '' then
    Jet := LanceFormule('1D100', False)
  else
    begin
      Jet := StrToIntDef(Trim(EditJet.Text), 0);
      if (Jet < 1) or (Jet > 100) then
        begin
          ShowMessage(GetTexteLibelle('RULES-MESS_097'));
          Exit;
        end;
    end;
  Dieu     := CaseDieu.Checked;
  if Dieu then Demande := PrioreAuHasard('');
  Accordee := '';
  Paye     := Cout;
  if Jet >= 96 then
    begin
      Accordee := Demande;
      Paye     := 0;
    end
  else if Jet >= 50 then
    Accordee := Demande
  else if Jet >= 41 then
    Accordee := PrioreAuHasard(Demande)
  else if Jet >= 31 then
    begin
      if Dieu then Accordee := Demande
    end
  else if (Jet >= 11) and (Jet <= 20) then
    begin
      if (Xp >= Cout + CoutPetitionPetty) and
         (MessageDlg(GetTexteLibelle('RULES-MESS_116'), mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
        begin
          Accordee := Demande;
          Paye     := Cout + CoutPetitionPetty;
        end;
    end;
  Change := True;
  Texte  := ' [d100 = ' + IntToStr(Jet) + ']';
  if Accordee <> '' then
    begin
      Accorde(Accordee, Paye);
      Xp := Xp - Paye;
      if Accordee = Demande then
        ShowMessage(GetTexteLibelle('RULES-MESS_113') + ' ' + ChercheSort(Accordee).Libelle + Texte)
      else
        ShowMessage(GetTexteLibelle('RULES-MESS_114') + ' ' + ChercheSort(Accordee).Libelle + Texte);
    end
  else
    begin
      Xp     := Xp - Paye;
      Perdus := Perdus + Paye;
      ShowMessage(GetTexteLibelle('RULES-MESS_115') + Texte);
    end;
  EditJet.Text := '';
  Remplit();
  AfficheInfo();
end;

function PetitionPrieresV1(Proprietaire: TComponent; Personnage: PPersonnageV1; XpDispo: Integer;
  Appris: TStrings; var EpPerdus: Integer): Boolean;
var
  Fenetre: TFenetrePetition;
begin
  Fenetre := TFenetrePetition.Cree(Proprietaire, Personnage, XpDispo, Appris);
  try
    Fenetre.ShowModal;
    EpPerdus := EpPerdus + Fenetre.EpPerdus;
    Result   := Fenetre.Change;
  finally
    Fenetre.Free;
  end;
end;

end.

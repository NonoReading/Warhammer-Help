unit ScriptEcran;

// Mode --script <fichier> : rejoue des gestes d utilisateur dans les vraies fenetres (clic,
// saisie, case, liste, ligne de grille) et ecrit ce qui est affiche. Meme idee que --dumpecran,
// mais en agissant. Les fenetres modales (ShowModal) sont gerees : la minuterie continue de
// tourner dans leur boucle, les commandes suivantes visent alors la fenetre modale.
//
// Une commande par ligne, # = commentaire, les noms sont ceux des composants (Name) :
//   CLIC nom               clique sur un bouton / image / composant ayant OnClick
//   COCHE nom [0|1]        coche / decoche une case (sans 0|1 : inverse)
//   SAISIE nom texte       ecrit dans un champ
//   CHOIX nom texte        choisit l element d une liste deroulante (par son texte)
//   CLICGRILLE nom n       clic souris sur la ligne n (n >= 1) d une grille (cases a cocher des filtres)
//   LIGNE nom n            selectionne la ligne n d une grille
//   DBLCLIC nom            double-clic (WinFiltre : coche / decoche toute la grille)
//   CLICCOL nom l c        clic souris sur la cellule (ligne l, colonne c) d une grille (ex. +5 / -5 d une avance)
//   SAISIETOUCHE nom texte comme SAISIE, puis OnKeyUp (champs recalcules a la frappe)
//   LIGNE nom =texte       (ou texte non numerique) choisit la ligne dont la colonne 1 ou 2 vaut ce texte
//   VERIFIE COMPTEMIN nom N | CELLULE nom l c valeur | CELLULEPLUS nom l c N   controles de grille
//   COMPTE nom            une ligne : nombre de lignes de donnees d une grille (sortie courte)
//   DUMP [titre]          ecrit le contenu de la fenetre active dans le fichier de sortie
//   FENETRES               liste les fenetres ouvertes
//   FERMER                 ferme la fenetre active
//   ATTENDRE n             attend n dixiemes de seconde
//   VERIFIE COMPTE nom N          la grille a N lignes de donnees
//   VERIFIE CASE nom 0|1          la case est decochee / cochee
//   VERIFIE TEXTE nom valeur      texte d un champ, d une liste ou d une etiquette
//   VERIFIE FENETRE classe 0|1    la fenetre (ex. TWinMetiers) est visible ou non
//   REPONDS OUI|NON|FERME  reponse donnee aux boites Oui/Non suivantes (FERME = fermee sans reponse, par defaut)
//   ACTIVE classe          declenche l activation de la fenetre (TMenu : rouvre la fiche apres MAJ Fiche)
//   VERIFIE BOITE 0|1           une boite de message est apparue (et a ete fermee) depuis la derniere fois
//   -> lignes « OK : ... » ou « ECHEC : ... », bilan « RESULTAT : n OK, m ECHEC » en derniere ligne,
//      code de sortie 1 s il y a un ECHEC, une ERREUR ou une EXCEPTION (un test = un script, rejouable)
//   CLICSI nom                    comme CLIC, mais seulement si le composant est visible et actif (sinon rien)
//   REPETE n ... FINREPETE        recopie les lignes du bloc n fois (pour rejouer les phases d un assistant)
//   SI commande ...               rend la commande silencieuse si son composant n existe plus (ex. SI SAISIE ...)
//   ARRETESI FENETRE classe 0|1   saute le reste de la boucle REPETE si la condition est vraie
//   ETAT                          une ligne : onglet actif de l assistant de la fenetre active
//   VERIFIE FICHIER chemin 0|1    le fichier / dossier existe (chemin relatif au dossier de l essai)
//   OUVRELIVRE chemin      ouvre WinLivre sur ce livre (dans ce processus)
//   ARBRE                  ecrit l arbre de WinLivre (texte indente) pour preparer un script
//   NOEUD texte            selectionne le 1er noeud de l arbre dont le texte commence par <texte>
//   VERIFIE NOEUD texte 0|1 | NOEUDSMIN n   noeud present / l arbre a au moins n noeuds
//   VERIFIE CONTIENT|ABSENT texte   le contenu de la fenetre active (comme DUMP) contient / ne contient pas ce texte
//                          (champs crees en code, sans Name : CHAMP  = "valeur"  (lecture seule : False))
//   MEMOPDF dossier        retient le nombre de .PDF du dossier ; VERIFIE PLUSDEPDF dossier : un .PDF absent du memo est apparu
//                          (en mode --script le PDF est ecrit sans ouvrir le lecteur)
//   QUITTER                termine le programme
// Le nom est cherche d abord dans la fenetre active, puis dans toutes les autres (le menu
// principal, cache, reste atteignable : CLIC ButtonMetier ouvre la fenetre des metiers).
// Sortie : <fichier script>.sortie.txt

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, StrUtils, Forms, Controls, StdCtrls, CheckLst, ExtCtrls, Grids, ComCtrls, Spin, Menus, DumpEcran, WinCreation;

// Charge le script et demarre la minuterie. A appeler avant Application.Run.
procedure LancerScript(const Fichier: String);

implementation

uses WinLivre, PdfPersonnage;

var
  PdfMemo: TStringList = nil;   // MEMOPDF : noms des .PDF d un dossier a un instant donne (PdfPurgeAnciens retire les anciens : un compte ne suffit pas)

procedure ListeFichiersPdf(const Dossier: String; L: TStringList);
var
  SR: TSearchRec;
begin
  L.Clear;
  if FindFirst(IncludeTrailingPathDelimiter(Dossier) + '*.PDF', faAnyFile, SR) = 0 then
  begin
    repeat
      L.Add(SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

function NouveauPdf(const Dossier: String): Boolean;
var
  L: TStringList;
  I: Integer;
begin
  Result := False;
  L := TStringList.Create;
  try
    ListeFichiersPdf(Dossier, L);
    for I := 0 to L.Count - 1 do
      if (PdfMemo = nil) or (PdfMemo.IndexOf(L[I]) < 0) then Result := True;
  finally
    L.Free;
  end;
end;

procedure DeroulerRepetitions(L: TStringList); forward;

var
  ReponseBoite: Integer = 0;   // 0 = fermer (defaut), 1 = Oui, 2 = Non (commande REPONDS)

type
  TControlOuvert = class(TControl);   // Click est protege dans TControl

  TPilote = class
  public
    Minuterie: TTimer;
    Lignes:    TStringList;
    Sortie:    TStringList;
    Fichier:   String;
    Index:     Integer;
    Pause:     Integer;       // ticks restants avant la prochaine commande
    Occupe:    Boolean;
    PrecedenteSansEffet: Boolean;   // la commande d avant n a rien change a l ecran
    SansPause: Boolean;      // la commande n a rien change a l ecran (CLICSI sur un bouton absent, ARRETESI...) : pas d attente
    FormCmd:  TCustomForm;   // fenetre active quand la commande en cours a demarre
    procedure Tick(Sender: TObject);
    procedure SurException(Sender: TObject; E: Exception);   // note l exception dans la sortie (la boite systeme est fermee seule)
    procedure Execute(const Ligne: String);
    function  Trouve(const Nom: String): TComponent;
    procedure Fin;
    procedure Verifie(const Quoi, Obtenu, Attendu: String);
  public
    BoitesVues: Integer;      // boites systeme fermees depuis la derniere VERIFIE BOITE
  end;

var
  Pilote: TPilote = nil;
  DebutMs: QWord = 0;   // heure du premier ordre : chaque ligne de la sortie porte le temps ecoule (mesure des lenteurs)

function Mot(var S: String): String;
var
  P: Integer;
begin
  S := Trim(S);
  P := Pos(' ', S);
  if P = 0 then
  begin
    Result := S;
    S := '';
  end
  else
  begin
    Result := Copy(S, 1, P - 1);
    S := Trim(Copy(S, P + 1, MaxInt));
  end;
end;

// Cherche par Name dans l arbre des controles (les controles crees en code ont un autre proprietaire que la fiche)
function ChercheControle(Parent: TWinControl; const Nom: String): TComponent;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Parent.ControlCount - 1 do
  begin
    if SameText(Parent.Controls[I].Name, Nom) then Exit(Parent.Controls[I]);
    if Parent.Controls[I] is TWinControl then
    begin
      Result := ChercheControle(TWinControl(Parent.Controls[I]), Nom);
      if Result <> nil then Exit;
    end;
  end;
end;

// Boites de creation de WinLivre : Genre 'E' = n-ieme TEdit, 'C' = n-ieme TComboBox (visibles), 'B' = bouton dont Tag = n (mrOk / mrCancel)
function TrouveDialogue(Parent: TWinControl; Genre: Char; N: Integer): TControl;
var
  I, Vus: Integer;
  C: TControl;
  Compte: Integer;

  function Cherche(P: TWinControl): TControl;
  var
    K: Integer;
    X: TControl;
  begin
    Result := nil;
    for K := 0 to P.ControlCount - 1 do
    begin
      X := P.Controls[K];
      if X.Visible then
      begin
        if ((Genre = 'E') and (X is TEdit)) or ((Genre = 'C') and (X is TComboBox)) or
           ((Genre = 'K') and (X is TCheckBox)) then
        begin
          Inc(Compte);
          if Compte = N then Exit(X);
        end
        else if (Genre = 'B') and (X.Tag = N) and (Pos('Button', X.ClassName) > 0) then Exit(X)
        else if (Genre = 'B') and (X is TCustomButton) and (TCustomButton(X).ModalResult = N) then Exit(X);   // boites standard (InputQuery)
        if X is TWinControl then
        begin
          Result := Cherche(TWinControl(X));
          if Result <> nil then Exit;
        end;
      end;
    end;
  end;

begin
  Compte := 0;
  Result := Cherche(Parent);
end;

function TPilote.Trouve(const Nom: String): TComponent;
var
  I: Integer;
begin
  Result := nil;
  if Screen.ActiveCustomForm <> nil then
    Result := Screen.ActiveCustomForm.FindComponent(Nom);
  if Result <> nil then Exit;
  for I := Screen.CustomFormCount - 1 downto 0 do
  begin
    Result := Screen.CustomForms[I].FindComponent(Nom);
    if Result <> nil then Exit;
  end;
  for I := Screen.CustomFormCount - 1 downto 0 do
  begin
    Result := ChercheControle(Screen.CustomForms[I], Nom);
    if Result <> nil then Exit;
  end;
end;

procedure TPilote.Verifie(const Quoi, Obtenu, Attendu: String);
begin
  if Obtenu = Attendu then
    Sortie.Add('  OK : ' + Quoi + ' = ' + Obtenu)
  else
    Sortie.Add('  ECHEC : ' + Quoi + ' : attendu ' + Attendu + ', obtenu ' + Obtenu);
end;

procedure TPilote.Fin;
var
  I, NbOk, NbEchec: Integer;
begin
  NbOk := 0;
  NbEchec := 0;
  for I := 0 to Sortie.Count - 1 do
    if Pos('  OK : ', Sortie[I]) = 1 then Inc(NbOk)
    else if (Pos('  ECHEC', Sortie[I]) = 1) or (Pos('  ERREUR', Sortie[I]) = 1)
         or (Pos('  EXCEPTION', Sortie[I]) = 1) then Inc(NbEchec);
  Sortie.Add('RESULTAT : ' + IntToStr(NbOk) + ' OK, ' + IntToStr(NbEchec) + ' ECHEC');
  if NbEchec > 0 then ExitCode := 1;
  Minuterie.Enabled := False;
  Sortie.SaveToFile(Fichier + '.sortie.txt');
  Application.Terminate;
end;

procedure TPilote.Execute(const Ligne: String);
var
  Reste, Cmd, Nom, Texte: String;
  Comp: TComponent;
  I, N, J: Integer;
  F: TCustomForm;
  Tmp: TStringList;
  R: TRect;
  Ctl: TControl;
  Vu, Silencieux: Boolean;
  Touche: Word;
  Arbre: TTreeView;
  Elem: TMenuItem;
begin
  Reste := Trim(Ligne);
  Cmd := UpperCase(Mot(Reste));
  Silencieux := False;
  if Cmd = 'SI' then      // SI <commande> ... : pas d erreur si le composant ou la fenetre n existe plus
  begin
    Silencieux := True;
    Cmd := UpperCase(Mot(Reste));
  end;
  if DebutMs = 0 then DebutMs := GetTickCount64;
  Sortie.Add('> ' + Ligne + '   [' + IntToStr(GetTickCount64 - DebutMs) + ' ms]');
  // ATTENDRE apres une commande sans effet (bouton absent...) : rien a attendre
  SansPause := (Cmd = 'ARRETESI') or (Cmd = 'ETAT') or ((Cmd = 'ATTENDRE') and PrecedenteSansEffet);
  PrecedenteSansEffet := False;

  if Cmd = 'ARRETESI' then
  begin
    // ARRETESI FENETRE <classe> 0|1 : si la condition est vraie, saute tout ce qui reste de la boucle REPETE
    Texte := Reste;
    if UpperCase(Mot(Texte)) = 'FENETRE' then
    begin
      Cmd := Mot(Texte);
      N := 0;
      for I := 0 to Screen.CustomFormCount - 1 do
        if Screen.CustomForms[I].Visible and SameText(Screen.CustomForms[I].ClassName, Cmd) then N := 1;
      if IntToStr(N) = Texte then
      begin
        I := Index;
        while (I < Lignes.Count) and (Lignes[I] <> '@FINBOUCLES') do Inc(I);
        Index := I;
        Sortie.Add('  (boucle terminee)');
      end;
    end
    else Sortie.Add('  ERREUR : ARRETESI ne connait que FENETRE');
    Exit;
  end;

  if Cmd = 'QUITTER' then begin Fin; Exit; end;
  if Cmd = 'OUVRELIVRE' then   // OUVRELIVRE <chemin du livre> : ouvre WinLivre sur ce livre (dans ce processus)
  begin
    try
      with WinLivre.TWinLivres.Create(Application) do
      begin
        ChargerXMLFile(Trim(Reste));
        Show;
      end;
      Application.ProcessMessages;
    except
      on E: Exception do Sortie.Add('  ERREUR : OUVRELIVRE ' + E.Message);
    end;
    Exit;
  end;
  if Cmd = 'MEMOPDF' then   // MEMOPDF <dossier> : retient le nombre de .PDF du dossier (avant un clic sur le bouton PDF)
  begin
    if PdfMemo = nil then PdfMemo := TStringList.Create;
    ListeFichiersPdf(Trim(Reste), PdfMemo);
    Exit;
  end;
  if Cmd = 'ARBRE' then  // ARBRE : ecrit l arbre de WinLivre (texte indente par niveau) pour preparer un script
  begin
    for I := 0 to Screen.CustomFormCount - 1 do
      if Screen.CustomForms[I] is TWinLivres then
        for N := 0 to TWinLivres(Screen.CustomForms[I]).TreeViewLivre.Items.Count - 1 do
          with TWinLivres(Screen.CustomForms[I]).TreeViewLivre.Items[N] do
            Sortie.Add('  NOEUD ' + StringOfChar(' ', Level * 2) + Text)
      else
        // autres fenetres (WinRace, WinMetier...) : chaque arbre de la fenetre visible
        for J := 0 to Screen.CustomForms[I].ComponentCount - 1 do
          if (Screen.CustomForms[I].Components[J] is TTreeView) and Screen.CustomForms[I].Visible then
            for N := 0 to TTreeView(Screen.CustomForms[I].Components[J]).Items.Count - 1 do
              with TTreeView(Screen.CustomForms[I].Components[J]).Items[N] do
                Sortie.Add('  NOEUD ' + StringOfChar(' ', Level * 2) + Text);
    Exit;
  end;
  if (Cmd = 'NOEUD') or ((Cmd = 'VERIFIE') and (UpperCase(Copy(Reste, 1, 5)) = 'NOEUD')) then
  begin
    // NOEUD <texte>                : selectionne dans l arbre de WinLivre le 1er noeud dont le texte commence par <texte>
    // VERIFIE NOEUD <texte> 0|1    : un tel noeud existe-t-il ?   VERIFIE NOEUDSMIN <n> : l arbre a au moins n noeuds
    Texte := Reste;
    if Cmd = 'VERIFIE' then Mot(Texte);
    Arbre := nil;
    for I := 0 to Screen.CustomFormCount - 1 do
      if Screen.CustomForms[I] is TWinLivres then Arbre := TWinLivres(Screen.CustomForms[I]).TreeViewLivre;
    if Arbre = nil then begin Sortie.Add('  ERREUR : WinLivre n est pas ouvert'); Exit; end;
    N := 0;
    if Cmd = 'VERIFIE' then
    begin
      Nom := Trim(Texte);
      if Pos('NOEUDSMIN', UpperCase(Reste)) = 1 then
      begin
        Verifie('NOEUDSMIN >= ' + Nom, IntToStr(Ord(Arbre.Items.Count >= StrToIntDef(Nom, 0))), '1');
        Exit;
      end;
      Cmd := Copy(Nom, Length(Nom), 1);   // 0|1 en fin de ligne
      Nom := Trim(Copy(Nom, 1, Length(Nom) - 1));
      for I := 0 to Arbre.Items.Count - 1 do
        if Pos(LowerCase(Nom), LowerCase(Arbre.Items[I].Text)) = 1 then N := 1;
      Verifie('NOEUD ' + Nom, IntToStr(N), Cmd);
      Exit;
    end;
    Nom := Trim(Texte);
    J := 1;   // NOEUD #n texte : le n-ieme noeud qui commence par texte (ex. les deux branches « Competence »)
    if (Nom <> '') and (Nom[1] = '#') then
    begin
      J := StrToIntDef(Copy(Nom, 2, Pos(' ', Nom + ' ') - 2), 1);
      Nom := Trim(Copy(Nom, Pos(' ', Nom + ' ') + 1, 200));
    end;
    for I := 0 to Arbre.Items.Count - 1 do
      if Pos(LowerCase(Nom), LowerCase(Arbre.Items[I].Text)) = 1 then
      begin
        Dec(J);
        if J > 0 then Continue;
        Arbre.Items[I].MakeVisible;
        Arbre.Selected := Arbre.Items[I];
        N := 1;
        Break;
      end;
    if N = 0 then Sortie.Add('  ERREUR : noeud introuvable : ' + Nom);
    Exit;
  end;
  if Cmd = 'MENU' then   // MENU <texte> : ouvre le menu contextuel de l arbre WinLivre et clique l entree dont le libelle commence par <texte>
  begin
    Arbre := nil;
    for I := 0 to Screen.CustomFormCount - 1 do
      if Screen.CustomForms[I] is TWinLivres then
      begin
        Arbre := TWinLivres(Screen.CustomForms[I]).TreeViewLivre;
        TWinLivres(Screen.CustomForms[I]).PopupMenuTreePopup(nil);
        Elem := nil;
        for N := 0 to TWinLivres(Screen.CustomForms[I]).PopupMenuTree.Items.Count - 1 do
          with TWinLivres(Screen.CustomForms[I]).PopupMenuTree.Items[N] do
            if (Elem = nil) and Visible and (Pos(LowerCase(Trim(Reste)), LowerCase(Caption)) = 1) then Elem := TWinLivres(Screen.CustomForms[I]).PopupMenuTree.Items[N];
        if Elem = nil then Sortie.Add('  ERREUR : MENU : entree introuvable ou masquee : ' + Trim(Reste))
        else if not Elem.Enabled then Sortie.Add('  ERREUR : MENU : entree inactive : ' + Trim(Reste))
        else Elem.Click;
      end;
    if Arbre = nil then Sortie.Add('  ERREUR : WinLivre n est pas ouvert');
    Exit;
  end;
  if (Cmd = 'DIALOGUE') or (Cmd = 'DCOMBO') or (Cmd = 'DCASE') or (Cmd = 'DVALIDE') or (Cmd = 'DANNULE') then
  begin
    // Boites de creation de WinLivre (controles sans Name) agissant sur la fenetre active :
    //   DIALOGUE texte  ecrit dans le 1er champ ;  DCOMBO n i  choisit l element i (1 = premier) de la n-ieme liste visible ;
    //   DVALIDE / DANNULE  clique le bouton Ok (Tag = mrOk) / Annuler (Tag = mrCancel)
    F := Screen.ActiveCustomForm;
    if F = nil then begin Sortie.Add('  ERREUR : ' + Cmd + ' : aucune fenetre active'); Exit; end;
    // SI DIALOGUE / SI DVALIDE : rien si la fenetre active n est pas modale (sinon le texte irait dans un champ de la fenetre de fond)
    if Silencieux and not (fsModal in F.FormState) then Exit;
    J := 1;
    N := 1;
    if Cmd = 'DCOMBO' then
    begin
      J := StrToIntDef(Trim(Copy(Reste, 1, Pos(' ', Reste + ' ') - 1)), 1);
      N := StrToIntDef(Trim(Copy(Reste, Pos(' ', Reste + ' ') + 1, 20)), 1);
    end;
    if Cmd = 'DIALOGUE' then Ctl := TrouveDialogue(F, 'E', 1)
    else if Cmd = 'DCOMBO' then Ctl := TrouveDialogue(F, 'C', J)
    else if Cmd = 'DCASE' then Ctl := TrouveDialogue(F, 'K', 1)   // DCASE : coche la 1re case de la boite
    else if Cmd = 'DVALIDE' then Ctl := TrouveDialogue(F, 'B', mrOk)
    else Ctl := TrouveDialogue(F, 'B', mrCancel);
    if Ctl = nil then begin Sortie.Add('  ERREUR : ' + Cmd + ' : controle introuvable'); Exit; end;
    if Cmd = 'DIALOGUE' then TEdit(Ctl).Text := Reste
    else if Cmd = 'DCASE' then TCheckBox(Ctl).Checked := True
    else if Cmd = 'DCOMBO' then
    begin
      if (N >= 1) and (N <= TComboBox(Ctl).Items.Count) then TComboBox(Ctl).ItemIndex := N - 1
      else Sortie.Add('  ERREUR : DCOMBO : liste de ' + IntToStr(TComboBox(Ctl).Items.Count) + ' elements');
    end
    else TControlOuvert(Ctl).Click;
    Exit;
  end;
  if Cmd = 'ATTENDRE' then begin Pause := StrToIntDef(Reste, 1) * 2; Exit; end;  // tick = 50 ms
  if Cmd = 'FENETRES' then
  begin
    for I := 0 to Screen.CustomFormCount - 1 do
    begin
      F := Screen.CustomForms[I];
      if F.Visible then
        Sortie.Add('  FENETRE ' + F.Name + ' (' + F.ClassName + ') "' + F.Caption + '"' +
          IfThen(fsModal in F.FormState, ' [modale]', ''));
    end;
    Exit;
  end;
  if Cmd = 'VERIFIE' then
  begin
    Texte := Reste;
    Nom := UpperCase(Mot(Texte));
    if Nom = 'FENETRE' then      // VERIFIE FENETRE <classe> 0|1 : cette fenetre est-elle visible ?
    begin
      Cmd := Mot(Texte);
      N := 0;
      for I := 0 to Screen.CustomFormCount - 1 do
        if Screen.CustomForms[I].Visible and SameText(Screen.CustomForms[I].ClassName, Cmd) then N := 1;
      Verifie('FENETRE ' + Cmd, IntToStr(N), Texte);
      Exit;
    end;
    if Nom = 'BOITE' then        // VERIFIE BOITE 0|1 : une boite de message est-elle apparue depuis la derniere verification ?
    begin
      Verifie('BOITE', IntToStr(Ord(BoitesVues > 0)), Texte);
      BoitesVues := 0;
      Exit;
    end;
    if (Nom = 'CONTIENT') or (Nom = 'ABSENT') then
    begin
      // VERIFIE CONTIENT|ABSENT <texte> : le contenu de la fenetre active (comme DUMP) contient / ne contient pas ce texte
      // (pour les champs crees en code, sans Name : VERIFIE CONTIENT CHAMP  = "Test Sword"  (lecture seule : False))
      F := Screen.ActiveCustomForm;
      if F = nil then begin Sortie.Add('  ERREUR : aucune fenetre active'); Exit; end;
      Tmp := TStringList.Create;
      try
        DumpControles(F, 1, Tmp);
        N := Ord(Pos(Texte, Tmp.Text) > 0);
      finally
        Tmp.Free;
      end;
      if Nom = 'ABSENT' then N := 1 - N;
      Verifie(Nom + ' ' + Texte, IntToStr(N), '1');
      Exit;
    end;
    if Nom = 'PLUSDEPDF' then    // VERIFIE PLUSDEPDF <dossier> : il y a plus de .PDF dans ce dossier que lors du dernier MEMOPDF
    begin
      Verifie('PLUSDEPDF ' + Texte, IntToStr(Ord(NouveauPdf(Trim(Texte)))), '1');
      Exit;
    end;
    if Nom = 'FICHIER' then    // VERIFIE FICHIER <chemin relatif au dossier courant> 0|1 : fichier ou dossier present ?
    begin
      Cmd := Mot(Texte);
      Verifie('FICHIER ' + Cmd, IntToStr(Ord(FileExists(Cmd) or DirectoryExists(Cmd))), Texte);
      Exit;
    end;
    // VERIFIE COMPTE|CASE|TEXTE <nom> <attendu>
    Cmd := Nom;
    Nom := Mot(Texte);
    Comp := Trouve(Nom);
    if Comp = nil then
    begin
      Sortie.Add('  ECHEC : composant introuvable : ' + Nom);
      Exit;
    end;
    if (Cmd = 'COMPTE') and (Comp is TStringGrid) then
      Verifie('COMPTE ' + Nom, IntToStr(TStringGrid(Comp).RowCount - TStringGrid(Comp).FixedRows), Texte)
    else if (Cmd = 'COMPTEMIN') and (Comp is TStringGrid) then
    begin
      // VERIFIE COMPTEMIN <grille> <n> : au moins n lignes de donnees
      N := TStringGrid(Comp).RowCount - TStringGrid(Comp).FixedRows;
      Verifie('COMPTEMIN ' + Nom + ' >= ' + Texte, IntToStr(Ord(N >= StrToIntDef(Texte, 0))), '1');
    end
    else if (Cmd = 'CELLULE') and (Comp is TStringGrid) then
    begin
      // VERIFIE CELLULE <grille> <ligne> <colonne> <attendu> ; attendu = rien pour une cellule vide
      N := StrToIntDef(Mot(Texte), -1);
      I := StrToIntDef(Mot(Texte), -1);
      if (N < 0) or (I < 0) or (N >= TStringGrid(Comp).RowCount) or (I >= TStringGrid(Comp).ColCount) then
        Sortie.Add('  ECHEC : cellule hors grille : ' + Nom)
      else
        Verifie('CELLULE ' + Nom + '[' + IntToStr(N) + ',' + IntToStr(I) + ']', Trim(TStringGrid(Comp).Cells[I, N]), Trim(Texte));   // certaines cellules d XP finissent par une espace
    end
    else if (Cmd = 'CELLULEPLUS') and (Comp is TStringGrid) then
    begin
      // VERIFIE CELLULEPLUS <grille> <ligne> <colonne> <n> : la cellule est un nombre >= n
      N := StrToIntDef(Mot(Texte), -1);
      I := StrToIntDef(Mot(Texte), -1);
      if (N < 0) or (I < 0) or (N >= TStringGrid(Comp).RowCount) or (I >= TStringGrid(Comp).ColCount) then
        Sortie.Add('  ECHEC : cellule hors grille : ' + Nom)
      else
        Verifie('CELLULEPLUS ' + Nom + '[' + IntToStr(N) + ',' + IntToStr(I) + '] >= ' + Texte + ' (vaut ' + TStringGrid(Comp).Cells[I, N] + ')',
                IntToStr(Ord(StrToIntDef(TStringGrid(Comp).Cells[I, N], -999999) >= StrToIntDef(Texte, 0))), '1');
    end
    else if (Cmd = 'CASE') and (Comp is TCheckBox) then
      Verifie('CASE ' + Nom, IntToStr(Ord(TCheckBox(Comp).Checked)), Texte)
    else if (Cmd = 'CASE') and (Comp is TRadioButton) then
      Verifie('CASE ' + Nom, IntToStr(Ord(TRadioButton(Comp).Checked)), Texte)
    else if (Cmd = 'CASE') and (Comp is TCheckListBox) and (TCheckListBox(Comp).Items.Count > 0) then   // case d une fiche WinLivre : 1re ligne
      Verifie('CASE ' + Nom, IntToStr(Ord(TCheckListBox(Comp).Checked[0])), Texte)
    else if (Cmd = 'TEXTE') and (Comp is TEdit) then
      Verifie('TEXTE ' + Nom, TEdit(Comp).Text, Texte)
    else if (Cmd = 'TEXTE') and (Comp is TComboBox) then
      Verifie('TEXTE ' + Nom, TComboBox(Comp).Text, Texte)
    else if (Cmd = 'TEXTE') and (Comp is TCustomFloatSpinEdit) then
      Verifie('TEXTE ' + Nom, IntToStr(Trunc(TCustomFloatSpinEdit(Comp).Value)), Texte)
    else if (Cmd = 'NBCHOIX') and (Comp is TComboBox) then   // VERIFIE NBCHOIX <liste> <n> : nombre d elements
      Verifie('NBCHOIX ' + Nom, IntToStr(TComboBox(Comp).Items.Count), Texte)
    else if (Cmd = 'TEXTE') and (Comp is TLabel) then
      Verifie('TEXTE ' + Nom, TLabel(Comp).Caption, Texte)
    else
      Sortie.Add('  ECHEC : VERIFIE ' + Cmd + ' ne s applique pas a ' + Nom + ' (' + Comp.ClassName + ')');
    Exit;
  end;
  if Cmd = 'ETAT' then
  begin
    // une ligne : onglet actif de chaque assistant (PageControl) de la fenetre active
    F := Screen.ActiveCustomForm;
    if F = nil then begin Sortie.Add('  ETAT : aucune fenetre active'); Exit; end;
    Texte := '';
    for I := 0 to F.ComponentCount - 1 do
      if (F.Components[I] is TPageControl) and TPageControl(F.Components[I]).Visible
         and (TPageControl(F.Components[I]).ActivePage <> nil) then
        Texte := Texte + ' ' + F.Components[I].Name + '=' + TPageControl(F.Components[I]).ActivePage.Name;
    Sortie.Add('  ETAT ' + F.ClassName + Texte);
    Exit;
  end;
  if Cmd = 'FERMER' then
  begin
    if Screen.ActiveCustomForm <> nil then Screen.ActiveCustomForm.Close
    else Sortie.Add('  ERREUR : aucune fenetre active');
    Exit;
  end;
  if Cmd = 'REPONDS' then   // REPONDS OUI|NON|FERME : reponse donnee aux boites Oui/Non qui suivent (jusqu a la prochaine REPONDS)
  begin
    if SameText(Trim(Reste), 'OUI') then ReponseBoite := 1
    else if SameText(Trim(Reste), 'NON') then ReponseBoite := 2
    else ReponseBoite := 0;
    SansPause := True;
    Exit;
  end;
  if Cmd = 'ACTIVE' then   // ACTIVE <classe> : declenche l activation de cette fenetre (ex. TMenu : rouvre la fiche apres MAJ Fiche)
  begin
    for I := 0 to Screen.CustomFormCount - 1 do
      if SameText(Screen.CustomForms[I].ClassName, Trim(Reste)) and Assigned(Screen.CustomForms[I].OnActivate) then
      begin
        Screen.CustomForms[I].OnActivate(Screen.CustomForms[I]);
        Break;
      end;
    Exit;
  end;
  if Cmd = 'FERMERSI' then // FERMERSI <classe> : ferme la fenetre active seulement si c est cette classe (ex. TWinCompetence)
  begin
    if (Screen.ActiveCustomForm <> nil) and SameText(Screen.ActiveCustomForm.ClassName, Trim(Reste)) then
      Screen.ActiveCustomForm.Close;
    Exit;
  end;
  if Cmd = 'DUMP' then
  begin
    F := Screen.ActiveCustomForm;
    if F = nil then begin Sortie.Add('  ERREUR : aucune fenetre active'); Exit; end;
    Sortie.Add('=== ' + F.ClassName + ' "' + F.Caption + '" ' + Reste);
    Tmp := TStringList.Create;
    try
      DumpControles(F, 1, Tmp);
      Sortie.AddStrings(Tmp);
    finally
      Tmp.Free;
    end;
    Exit;
  end;

  Nom := Mot(Reste);
  Comp := Trouve(Nom);
  if Comp = nil then
  begin
    SansPause := True;
    if not Silencieux and (Cmd <> 'CLICSI') then
      Sortie.Add('  ERREUR : composant introuvable : ' + Nom);
    Exit;
  end;
  Texte := Reste;

  if Cmd = 'CLIC' then
  begin
    if Comp is TControl then TControlOuvert(Comp).Click
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas cliquable');
  end
  else if Cmd = 'COCHE' then
  begin
    if Comp is TRadioButton then   // bouton radio : COCHE nom 1 le selectionne
      TRadioButton(Comp).Checked := (Texte <> '0')
    else if Comp is TCheckBox then
    begin
      if (Texte = '') or ((Texte = '1') <> TCheckBox(Comp).Checked) then
        TCheckBox(Comp).Checked := not TCheckBox(Comp).Checked;
    end
    else if (Comp is TCheckListBox) and (TCheckListBox(Comp).Items.Count > 0) then   // case d une fiche WinLivre : 1re ligne
    begin
      if (Texte = '') or ((Texte = '1') <> TCheckListBox(Comp).Checked[0]) then
      begin
        TCheckListBox(Comp).Checked[0] := not TCheckListBox(Comp).Checked[0];
        if Assigned(TCheckListBox(Comp).OnClickCheck) then TCheckListBox(Comp).OnClickCheck(Comp);   // le changement par code ne le declenche pas
      end;
    end
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas une case');
  end
  else if Cmd = 'SAISIE' then
  begin
    if Comp is TCustomFloatSpinEdit then   // champ numerique (ex. resultat d un lancer)
      TCustomFloatSpinEdit(Comp).Value := StrToFloatDef(Texte, 0)
    else if Comp is TEdit then TEdit(Comp).Text := Texte
    else if Comp is TMemo then TMemo(Comp).Text := Texte
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas un champ');
  end
  else if Cmd = 'SAISIETOUCHE' then
  begin
    // comme SAISIE, puis releve d une touche (OnKeyUp) : pour les champs qui se recalculent a la frappe (ex. EditTotalXp)
    if Comp is TEdit then
    begin
      TEdit(Comp).Text := Texte;
      if Assigned(TEdit(Comp).OnKeyUp) then
      begin
        Touche := 48;   // chiffre 0
        TEdit(Comp).OnKeyUp(Comp, Touche, []);
      end;
    end
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas un champ');
  end
  else if Cmd = 'CHOIX' then
  begin
    // SI CHOIX : rien si la liste n est pas affichee (sinon un OnChange / OnSelect refait un choix deja valide, ex. ComboBoxSigne)
    if Silencieux and (Comp is TControl) then
    begin
      Ctl := TControl(Comp);
      Vu  := Ctl.Enabled;
      while Vu and (Ctl <> nil) and not (Ctl is TCustomForm) do
      begin
        Vu  := Ctl.Visible;
        Ctl := Ctl.Parent;
      end;
      if not Vu then Exit;
    end;
    if Comp is TComboBox then
    begin
      if (Texte <> '') and (Texte[1] = '#') then   // CHOIX nom #n : n-ieme element (1 = premier)
        N := StrToIntDef(Copy(Texte, 2, MaxInt), 0) - 1
      else
        N := TComboBox(Comp).Items.IndexOf(Texte);
      if N >= TComboBox(Comp).Items.Count then N := -1;
      if N < 0 then Sortie.Add('  ERREUR : choix absent : ' + Texte)
      else
      begin
        TComboBox(Comp).ItemIndex := N;
        if Assigned(TComboBox(Comp).OnChange) then TComboBox(Comp).OnChange(Comp)
        else if Assigned(TComboBox(Comp).OnSelect) then TComboBox(Comp).OnSelect(Comp);   // liste a OnSelect seul (ex. ComboBoxSigne)
      end;
    end
    else if Comp is TListBox then
    begin
      // liste simple (fenetre de choix en code) : par le texte, le debut du texte, ou #n (1 = premier)
      if (Texte <> '') and (Texte[1] = '#') then
        N := StrToIntDef(Copy(Texte, 2, MaxInt), 0) - 1
      else
      begin
        N := TListBox(Comp).Items.IndexOf(Texte);
        if N < 0 then
          for I := 0 to TListBox(Comp).Items.Count - 1 do
            if Pos(Texte, TListBox(Comp).Items[I]) = 1 then
            begin
              N := I;
              Break;
            end;
      end;
      if (N < 0) or (N >= TListBox(Comp).Items.Count) then Sortie.Add('  ERREUR : choix absent : ' + Texte)
      else TListBox(Comp).ItemIndex := N;
    end
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas une liste');
  end
  else if Cmd = 'CLICSI' then
  begin
    // clique seulement si le composant est visible (parents compris) et actif ; sinon ne fait rien, sans erreur.
    // Sert a rejouer un meme geste a chaque phase d un assistant (ex. boutons Hasard de la creation).
    if Comp is TControl then
    begin
      Ctl := TControl(Comp);
      Vu := Ctl.Enabled;
      while Vu and (Ctl <> nil) and not (Ctl is TCustomForm) do
      begin
        Vu := Ctl.Visible;
        // un onglet inactif garde Visible = True : seul Showing dit s il est vraiment affiche
        if Vu and (Ctl is TWinControl) then Vu := TWinControl(Ctl).Showing;
        // Showing reste vrai pour un onglet qui n est plus la page active (constate : ButtonRaceHasard
        // recliquee depuis la page Metier, la race changeait sans recalcul des metiers) : on teste la page active
        if Vu and (Ctl is TTabSheet) and (TTabSheet(Ctl).PageControl <> nil) then
          Vu := (TTabSheet(Ctl).PageControl.ActivePage = Ctl);
        Ctl := Ctl.Parent;
      end;
      if Vu then TControlOuvert(Comp).Click
      else SansPause := True;
    end;
  end
  else if Cmd = 'DBLCLIC' then
  begin
    // double-clic : dans les grilles de WinFiltre, coche / decoche toute la grille
    if Comp is TControl then TControlOuvert(Comp).DblClick
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas cliquable');
  end
  else if Cmd = 'COMPTE' then
  begin
    // une seule ligne dans la sortie : nombre de lignes de donnees de la grille (sans l en-tete)
    if Comp is TStringGrid then
      Sortie.Add('  COMPTE ' + Nom + ' = ' + IntToStr(TStringGrid(Comp).RowCount - TStringGrid(Comp).FixedRows))
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas une grille');
  end
  else if Cmd = 'CLICGRILLE' then
  begin
    // vrai clic souris sur la ligne n (colonne 1) : passe par OnMouseDown comme l utilisateur
    if Comp is TStringGrid then
    begin
      N := StrToIntDef(Texte, -1);
      if N < 0 then   // pas un nombre : on cherche la ligne dont une cellule vaut ce texte
        for I := 1 to TStringGrid(Comp).RowCount - 1 do
          if (TStringGrid(Comp).Cells[2, I] = Texte) or (TStringGrid(Comp).Cells[1, I] = Texte) then
          begin
            N := I;
            Break;
          end;
      if (N < 1) or (N >= TStringGrid(Comp).RowCount) then
        Sortie.Add('  ERREUR : ligne introuvable : ' + Texte)
      else if Assigned(TStringGrid(Comp).OnMouseDown) then
      begin
        R := TStringGrid(Comp).CellRect(1, N);
        TStringGrid(Comp).OnMouseDown(Comp, mbLeft, [], (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
      end
      else Sortie.Add('  ERREUR : ' + Nom + ' n a pas de OnMouseDown');
    end
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas une grille');
  end
  else if Cmd = 'ECRIT' then
  begin
    // ECRIT grille ligne colonne valeur : ecrit la cellule comme une saisie finie (selection, texte, OnEditingDone)
    if Comp is TStringGrid then
    begin
      N := StrToIntDef(Mot(Texte), -1);
      I := StrToIntDef(Mot(Texte), -1);
      if (N < 1) or (N >= TStringGrid(Comp).RowCount) or (I < 0) or (I >= TStringGrid(Comp).ColCount) then
        Sortie.Add('  ERREUR : cellule hors grille : ' + Nom)
      else
      begin
        TStringGrid(Comp).Col := I;
        TStringGrid(Comp).Row := N;
        TStringGrid(Comp).Cells[I, N] := Texte;
        if Assigned(TStringGrid(Comp).OnEditingDone) then TStringGrid(Comp).OnEditingDone(Comp);
      end;
    end
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas une grille');
  end
  else if Cmd = 'CLICCOL' then
  begin
    // CLICCOL grille ligne colonne : vrai clic souris sur cette cellule (ex. colonne +5 de TabAugmentationAttribut)
    if Comp is TStringGrid then
    begin
      N := StrToIntDef(Mot(Texte), -1);
      I := StrToIntDef(Texte, -1);
      if (N < 1) or (N >= TStringGrid(Comp).RowCount) or (I < 0) or (I >= TStringGrid(Comp).ColCount) then
        Sortie.Add('  ERREUR : cellule hors grille : ' + Nom)
      else if Assigned(TStringGrid(Comp).OnMouseDown) then
      begin
        R := TStringGrid(Comp).CellRect(I, N);
        TStringGrid(Comp).OnMouseDown(Comp, mbLeft, [], (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
      end
      else Sortie.Add('  ERREUR : ' + Nom + ' n a pas de OnMouseDown');
    end
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas une grille');
  end
  else if Cmd = 'CELLULE' then
  begin
    // CELLULE nom ligne colonne : ecrit le texte brut de la cellule (meme colonne cachee) et la ligne courante
    if Comp is TStringGrid then
    begin
      N := StrToIntDef(Mot(Texte), -1);
      I := StrToIntDef(Texte, -1);
      if (N < 0) or (I < 0) or (N >= TStringGrid(Comp).RowCount) or (I >= TStringGrid(Comp).ColCount) then
        Sortie.Add('  ERREUR : cellule hors grille : ' + Nom)
      else
        Sortie.Add('  CELLULE ' + Nom + '[' + IntToStr(N) + ',' + IntToStr(I) + '] = ' + TStringGrid(Comp).Cells[I, N]
                   + '  (ligne courante ' + IntToStr(TStringGrid(Comp).Row) + ')');
    end
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas une grille');
  end
  else if Cmd = 'REMPLIT' then
  begin
    // REMPLIT grille ligne col colMarque valeur : si la grille est affichee et que la cellule (colMarque, ligne)
    // vaut 1, ecrit la valeur dans (col, ligne) comme une saisie finie (OnSetEditText puis OnEditingDone).
    // Sert a repartir le bonus de carriere V5 ; sinon ne fait rien.
    if (Comp is TStringGrid) and TStringGrid(Comp).Showing then
    begin
      N := StrToIntDef(Mot(Texte), -1);
      I := StrToIntDef(Mot(Texte), -1);
      J := StrToIntDef(Mot(Texte), -1);
      if (N >= 1) and (N < TStringGrid(Comp).RowCount) and (I >= 0) and (I < TStringGrid(Comp).ColCount)
         and (J >= 0) and (J < TStringGrid(Comp).ColCount) and (TStringGrid(Comp).Cells[J, N] = '1') then
      begin
        TStringGrid(Comp).Col := I;
        TStringGrid(Comp).Row := N;
        TStringGrid(Comp).Cells[I, N] := Texte;
        if Assigned(TStringGrid(Comp).OnEditingDone) then TStringGrid(Comp).OnEditingDone(Comp);
      end;
    end;
  end
  else if Cmd = 'SPECIALISE' then
  begin
    // SPECIALISE grille n : si la grille est affichee et que le code de sa ligne n est encore « au choix »
    // (contient / ou _*), selectionne la ligne et double-clique. Sinon ne fait rien (rejouable a chaque phase).
    if (Comp is TStringGrid) and TStringGrid(Comp).Showing and (TStringGrid(Comp).ColCount > 1) then
    begin
      N := StrToIntDef(Texte, -1);
      if (N >= 1) and (N < TStringGrid(Comp).RowCount) and
         ((Pos('/', TStringGrid(Comp).Cells[1, N]) > 0) or (Pos('_*', TStringGrid(Comp).Cells[1, N]) > 0)) then
      begin
        for I := TStringGrid(Comp).FixedCols to TStringGrid(Comp).ColCount - 1 do
          if TStringGrid(Comp).ColWidths[I] > 0 then
          begin
            TStringGrid(Comp).Col := I;
            Break;
          end;
        TStringGrid(Comp).Row := N;
        TControlOuvert(Comp).DblClick;
      end;
    end;
  end
  else if Cmd = 'LIGNE' then
  begin
    if Comp is TStringGrid then
    begin
      N := StrToIntDef(Texte, -1);
      if (Texte <> '') and (Texte[1] = '=') then   // « =3 » : texte, meme s il ressemble a un nombre
      begin
        Texte := Copy(Texte, 2, MaxInt);
        N := -1;
      end;
      if N < 0 then   // pas un nombre : ligne dont la colonne 1 vaut ce texte, sinon la colonne 2 (ex. nom d un personnage)
      begin
        for I := 1 to TStringGrid(Comp).RowCount - 1 do
          if TStringGrid(Comp).Cells[1, I] = Texte then
          begin
            N := I;
            Break;
          end;
        if (N < 0) and (TStringGrid(Comp).ColCount > 2) then
          for I := 1 to TStringGrid(Comp).RowCount - 1 do
            if TStringGrid(Comp).Cells[2, I] = Texte then
            begin
              N := I;
              Break;
            end;
        if N < 0 then   // en dernier recours la colonne 0 (ex. race « Mutant » : texte en colonne 0, colonne 1 vide)
          for I := 1 to TStringGrid(Comp).RowCount - 1 do
            if TStringGrid(Comp).Cells[0, I] = Texte then
            begin
              N := I;
              Break;
            end;
      end;
      if (N < 0) or (N >= TStringGrid(Comp).RowCount) then
      begin
        if not Silencieux then Sortie.Add('  ERREUR : ligne hors grille : ' + Texte);   // SI LIGNE : ligne absente = on ignore
      end
      else
      begin
        // colonne courante dans une colonne fixe ou cachee : la grille refuse alors de changer de ligne
        if (TStringGrid(Comp).Col < TStringGrid(Comp).FixedCols) or (TStringGrid(Comp).ColWidths[TStringGrid(Comp).Col] = 0) then
          for I := TStringGrid(Comp).FixedCols to TStringGrid(Comp).ColCount - 1 do
            if TStringGrid(Comp).ColWidths[I] > 0 then
            begin
              TStringGrid(Comp).Col := I;
              Break;
            end;
        TStringGrid(Comp).Row := N;
        if TStringGrid(Comp).Row <> N then
          Sortie.Add('  ERREUR : la grille ' + Nom + ' refuse la ligne ' + Texte);
        if Assigned(TStringGrid(Comp).OnSelection) then
          TStringGrid(Comp).OnSelection(Comp, TStringGrid(Comp).Col, N);
      end;
    end
    else Sortie.Add('  ERREUR : ' + Nom + ' n est pas une grille');
  end
  else
    Sortie.Add('  ERREUR : commande inconnue : ' + Cmd);
end;

var
  TexteBoite: String = '';

function LitEnfant(H: HWND; Dummy: LPARAM): WINBOOL; stdcall;
var
  Buf: array[0..1023] of WideChar;
  N: Integer;
begin
  N := GetWindowTextW(H, @Buf[0], 1023);
  if N > 0 then
  begin
    Buf[N] := #0;
    if TexteBoite <> '' then TexteBoite := TexteBoite + ' | ';
    TexteBoite := TexteBoite + UTF8Encode(WideString(PWideChar(@Buf[0])));
  end;
  Result := True;
end;

function FermeBoitesSysteme: Integer;
// Ferme les boites de message systeme (MessageDlg) de ce processus : elles bloqueraient le script.
// Renvoie leur nombre. Le texte n est pas lisible (boite native), seul le fait est note.
var
  H: HWND;
  Pid: DWORD;
begin
  Result := 0;
  H := 0;
  repeat
    H := FindWindowExW(0, H, '#32770', nil);
    if H = 0 then Break;
    GetWindowThreadProcessId(H, @Pid);
    if (Pid = GetCurrentProcessId) and IsWindowVisible(H) then
    begin
      TexteBoite := '';
      EnumChildWindows(H, @LitEnfant, 0);
      // REPONDS OUI / NON : seulement si la boite a ce bouton (une boite OK simple se ferme comme avant)
      if (ReponseBoite = 1) and (GetDlgItem(H, IDYES) <> 0) then PostMessage(H, WM_COMMAND, IDYES, 0)
      else if (ReponseBoite = 2) and (GetDlgItem(H, IDNO) <> 0) then PostMessage(H, WM_COMMAND, IDNO, 0)
      else PostMessage(H, WM_CLOSE, 0, 0);
      Inc(Result);
    end;
  until False;
end;

procedure RangeFenetresHorsEcran;
// Les tests ne doivent pas gener la personne qui travaille a cote : chaque fenetre du programme est
// repoussee hors de l ecran (sans activation, sans changer l ordre), toujours « visible » pour la VCL,
// donc les clics, les tests de visibilite et les captures de contenu fonctionnent comme avant.
// WH_SCRIPT_VISIBLE=1 : garde les fenetres a l ecran (pour regarder un test).
var
  I: Integer;
  F: TCustomForm;
  R: TRect;
begin
  if GetEnvironmentVariable('WH_SCRIPT_VISIBLE') = '1' then Exit;
  for I := 0 to Screen.CustomFormCount - 1 do
  begin
    F := Screen.CustomForms[I];
    // pas -32000 : c est la position des fenetres REDUITES, la fenetre modale n etait plus reconnue
    // comme active et le script restait bloque (constate : WFRP4 graine 1, page Talent).
    // On la place juste a droite du bureau virtuel (tous ecrans).
    if F.HandleAllocated and F.Visible and GetWindowRect(F.Handle, R)
       and (R.Left < GetSystemMetrics(SM_XVIRTUALSCREEN) + GetSystemMetrics(SM_CXVIRTUALSCREEN)) then
      SetWindowPos(F.Handle, 0, GetSystemMetrics(SM_XVIRTUALSCREEN) + GetSystemMetrics(SM_CXVIRTUALSCREEN) + 100,
                   R.Top, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
  end;
end;

procedure TPilote.SurException(Sender: TObject; E: Exception);
var
  I: Integer;
begin
  Sortie.Add('  EXCEPTION : ' + E.ClassName + ' : ' + E.Message);
  // Pile d appel (infos de ligne -gl) : sans elle on ne sait pas d ou vient l exception
  Sortie.Add('    a ' + BackTraceStrFunc(ExceptAddr));
  for I := 0 to ExceptFrameCount - 1 do
    Sortie.Add('    a ' + BackTraceStrFunc(ExceptFrames[I]));
end;

procedure TPilote.Tick(Sender: TObject);
var
  Ligne: String;
  FormAvant: TCustomForm;
  Modale: Boolean;
begin
  RangeFenetresHorsEcran;
  if FermeBoitesSysteme > 0 then
  begin
    Inc(BoitesVues);
    Sortie.Add('  BOITE SYSTEME FERMEE : ' + TexteBoite);
  end;
  if Pause > 0 then begin Dec(Pause); Exit; end;
  // Une commande deja en cours ne laisse la place qu a une fenetre modale qu elle a ouverte.
  Modale := (Screen.ActiveCustomForm <> nil) and (Screen.ActiveCustomForm <> FormCmd)
            and (fsModal in Screen.ActiveCustomForm.FormState);
  if Occupe and not Modale then Exit;
  if Index >= Lignes.Count then begin Fin; Exit; end;

  Ligne := Trim(Lignes[Index]);
  Inc(Index);
  if (Ligne = '') or (Ligne[1] = '#') or (Ligne[1] = '@') then Exit;

  FormAvant := FormCmd;
  SansPause := False;
  Occupe := True;
  FormCmd := Screen.ActiveCustomForm;
  try
    try
      Execute(Ligne);
    except
      on E: Exception do Sortie.Add('  EXCEPTION : ' + E.Message);
    end;
  finally
    FormCmd := FormAvant;
    Occupe := (FormAvant <> nil);
  end;
  try
    Sortie.SaveToFile(Fichier + '.sortie.txt');   // ecrite au fil de l eau : lisible meme si le script se bloque
  except
  end;
  PrecedenteSansEffet := SansPause;
  if SansPause then Pause := 0
  else Pause := 2;   // laisse l ecran se mettre a jour (100 ms)
end;

procedure DeroulerRepetitions(L: TStringList);
// REPETE n ... FINREPETE : recopie le bloc n fois (pas d imbrication).
var
  Res, Bloc: TStringList;
  I, K, N: Integer;
  S: String;
  Dans: Boolean;
begin
  Res := TStringList.Create;
  Bloc := TStringList.Create;
  try
    Dans := False;
    N := 0;
    for I := 0 to L.Count - 1 do
    begin
      S := Trim(L[I]);
      if (not Dans) and (UpperCase(Copy(S, 1, 7)) = 'REPETE ') then
      begin
        Dans := True;
        N := StrToIntDef(Trim(Copy(S, 8, MaxInt)), 1);
        Bloc.Clear;
      end
      else if Dans and (UpperCase(S) = 'FINREPETE') then
      begin
        for K := 1 to N do Res.AddStrings(Bloc);
        Res.Add('@FINBOUCLES');   // repere pour ARRETESI
        Dans := False;
      end
      else if Dans then Bloc.Add(S)
      else Res.Add(L[I]);
    end;
    L.Assign(Res);
  finally
    Res.Free;
    Bloc.Free;
  end;
end;

procedure LancerScript(const Fichier: String);
begin
  PdfSansOuverture := True;   // un clic sur le bouton PDF ecrit le fichier sans ouvrir le lecteur
  Pilote := TPilote.Create;
  Pilote.Fichier := Fichier;
  Pilote.Lignes := TStringList.Create;
  Pilote.Lignes.LoadFromFile(Fichier);
  DeroulerRepetitions(Pilote.Lignes);
  Pilote.Sortie := TStringList.Create;
  JournalMessages := Pilote.Sortie;   // WinCreation y note le texte de ses messages
  Application.OnException := @Pilote.SurException;
  Pilote.Pause := 20;   // 1 s : laisse l application finir de demarrer
  Pilote.Minuterie := TTimer.Create(Application);
  Pilote.Minuterie.Interval := 50;
  Pilote.Minuterie.OnTimer := @Pilote.Tick;
  Pilote.Minuterie.Enabled := True;
end;

end.

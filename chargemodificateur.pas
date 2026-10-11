unit ChargeModificateur;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections, ChargeConstantes;

Type
  // Fondation du moteur generique de bonus/malus (CONTEXT.md, chantier "inversion des
  // recherches"). Avant ce moteur, savoir si une arme a un bonus de competence obligeait a
  // interroger une fonction differente par source (PersonnageCareerBonusArmeModif,
  // PersonnageMutationTalent...) - une fonction de plus a chaque nouveau croisement
  // source x cible.
  //
  // Avec cette structure, chaque source (Talent, Mutation, CareerBonus, equipement...)
  // porte sa propre liste de StructureModificateur, mais TOUTES au meme format : le
  // calcul boucle sur ce que le PERSONNAGE possede reellement (quelques dizaines
  // d'elements) plutot que d'interroger le catalogue complet, donc balayer plusieurs
  // sources a chaque recherche n'a pas d'impact mesurable.
  StructureModificateur = Record
        // Vocabulaire ferme : ModifyCarac / ModifySkill / ModifyWeapon / ModifArmour /
        // ModifyDamage. Distingue quel calcul (competence, arme, armure...) ce
        // modificateur alimente.
        TypeModif:  String;
        // Code de l'element vise : CodeAttribut, CodeCompetence, TypeArme,
        // CodeLocalisation selon TypeModif.
        Cible:      String;
        // Filtre optionnel restreignant Cible (ex. skill= de ModifyWeapon, qui limite
        // un TypeArme a une seule competence). Vide si non utilise.
        Filtre:     String;
        // Additif pour commencer (Cible += Facteur). Proportionnel/Drapeau si un cas
        // reel l'exige, meme vocabulaire que ConstFormeEffet* (chargeconstantes.pas).
        Forme:      String;
        Facteur:    Integer;
        // Code du Talent/Mutation/CareerBonus qui porte ce modificateur, pour
        // affichage/debug - pas utilise par le calcul lui-meme.
        CodeSource: String;
        // Palier minimum requis pour que ce modificateur s'applique (CareerBonus,
        // <LevelN>) - 0 = pas de condition de palier, valeur par defaut pour les
        // sources qui n'en ont pas besoin (Talent).
        Niveau:     Integer;
        // Vrai si Facteur porte une face de de (ex. 10 pour 1d10) plutot qu'une valeur fixe -
        // <ModifyCaracAleatoire>, ChargeAfflictionModificateur/ChargeDiseaseModificateur
        // uniquement pour l'instant. Le tirage effectif est fait UNE FOIS a l'ajout de
        // l'entree sur la fiche et memorise a part (StructurePersonnagePathologie.
        // ValeurAleatoire) - le calcul du personnage ignore alors ce Facteur et lit la valeur
        // memorisee. Faux (valeur par defaut) pour toutes les autres sources. Ajout du
        // 27/09/2026, a la demande de Nono.
        Aleatoire:  Boolean;
        // Type d'element qui porte ce modificateur (SourceModif* ci-dessous). Renseigne
        // seulement dans ListModificateur (liste unique) ; reste vide dans les listes par
        // source, en cours de retrait (CONTEXT.md, chantier modificateurs generiques).
        TypeSource: String;
        // Libelle du livre dont l'import a ajoute l'entree (LivreImportEnCours), pour retirer
        // un livre des listes sans tout recharger (XmlRetireLivre). Vide hors import.
        Livre:      String;
end;

  TListModificateur = Specialize TList<StructureModificateur>;

  // Condition declaree par un livre (<Condition id><Kind> de DATA_CONDITION). Le moteur ne s'en
  // sert pas (les modificateurs citent le code dans if=/Filtre=, le libelle vient de DATA_LABEL) :
  // la liste n'existe que pour que l'export reecrive le chapitre (CONTEXT.md 2.106).
  StructureConditionDonnee = Record
        Livre: String;
        Code:  String;
        Genre: String;
  end;

  TListConditionDonnee = Specialize TList<StructureConditionDonnee>;

Const
  ConstXmlDataCondition = 'DATA_CONDITION';
  ConstXmlCondition     = 'Condition';
  ConstXmlConditionKind = 'Kind';

Const
  SourceModifTalent       = 'Talent';
  SourceModifArme         = 'Weapon';
  SourceModifQualiteArme  = 'WeaponBonus';
  SourceModifArmureBonus  = 'ArmorBonus';
  SourceModifCareerBonus  = 'CareerBonus';
  SourceModifMutation     = 'Mutation';
  SourceModifAffliction   = 'Affliction';
  SourceModifMaladie      = 'Disease';
  SourceModifFabrication  = 'Craftsmanship';
  SourceModifTrapping     = 'Trapping';

Type
  // Nature de la Cible d'un type d'effet : decide l'editeur de la cellule Cible (liste de
  // caracteristiques, liste de competences, saisie libre) et le libelle affiche.
  // ncDegat : liste fermee de categories d'arme (CC/CT), affichee par libelle.
  NatureCibleModif = (ncCarac, ncCompetence, ncArme, ncLibre, ncFixe, ncDegat, ncEmplacement);
  // ncEmplacement : liste fermee des emplacements d'armure (RULES-ARMOL_*).

  // Un type d'effet connu : sa balise XML historique, le libelle (RULES-LAB_*) affiche a sa
  // place, la nature de sa Cible, et si un Filtre (attribut skill=) est admis. Table unique
  // pour le chargement, l'export, le schema et le tableau de WinLivre (CONTEXT.md 2.105, e1).
  StructureTypeEffet = Record
        Balise:       String;
        CodeLibelle:  String;
        Nature:       NatureCibleModif;
        AccepteFiltre: Boolean;
        // Cible imposee des types sans cible a choisir (ncFixe) : ACCURATE, RELOAD, '*'.
        CibleFixe:    String;
        // Valeur entiere obligatoire, et non nulle sauf ligne a condition (if=) : 0 est sans effet.
        ValeurNonNulle: Boolean;
  end;

Const
  NbTypesEffet = 18;
  // L'ordre est celui de la liste deroulante de WinLivre ; ModifyCarac..Modificateur gardent
  // les libelles RULES-LAB_443 a 449 deja utilises par la grille des bonus de talent.
  TypesEffet: array[0..NbTypesEffet - 1] of StructureTypeEffet = (
    (Balise: ConstXmlModifieAttribut;           CodeLibelle: 'RULES-LAB_443'; Nature: ncCarac;      AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieAttributAleatoire;  CodeLibelle: 'RULES-LAB_444'; Nature: ncCarac;      AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieCompetence;         CodeLibelle: 'RULES-LAB_445'; Nature: ncCompetence; AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieCompetenceAttribut; CodeLibelle: 'RULES-LAB_446'; Nature: ncCarac; AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieArme;               CodeLibelle: 'RULES-LAB_447'; Nature: ncArme;       AccepteFiltre: True; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieDegat;              CodeLibelle: 'RULES-LAB_448'; Nature: ncDegat;     AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModificateur;              CodeLibelle: 'RULES-LAB_449'; Nature: ncLibre;      AccepteFiltre: True; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieArmure;             CodeLibelle: 'RULES-LAB_076'; Nature: ncEmplacement;     AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieBateau;             CodeLibelle: 'RULES-LAB_468'; Nature: ncLibre;      AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieTestSL;             CodeLibelle: 'RULES-LAB_334'; Nature: ncLibre; AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieCN;                 CodeLibelle: 'RULES-LAB_335'; Nature: ncLibre;      AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieDegatRecu;          CodeLibelle: 'RULES-LAB_336'; Nature: ncFixe;       AccepteFiltre: False; CibleFixe: '*'; ValeurNonNulle: True),
    (Balise: ConstXmlModifieAccuracy;           CodeLibelle: 'RULES-LAB_337'; Nature: ncFixe;       AccepteFiltre: False; CibleFixe: ConstCibleModifieAccuracy; ValeurNonNulle: True),
    (Balise: ConstXmlModifieRechargement;       CodeLibelle: 'RULES-LAB_338'; Nature: ncFixe;       AccepteFiltre: False; CibleFixe: ConstCibleModifieRechargement; ValeurNonNulle: True),
    (Balise: ConstXmlModifieRechargementMin;    CodeLibelle: 'RULES-LAB_467'; Nature: ncFixe;       AccepteFiltre: False; CibleFixe: ConstCibleModifieRechargement; ValeurNonNulle: True),
    (Balise: ConstXmlModifieMains;              CodeLibelle: 'RULES-LAB_053'; Nature: ncFixe;       AccepteFiltre: False; CibleFixe: ConstCibleModifieMains; ValeurNonNulle: True),
    (Balise: ConstXmlModifieCompetenceEquip;    CodeLibelle: 'RULES-LAB_474'; Nature: ncCompetence; AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True),
    (Balise: ConstXmlModifieCompetenceCarriere; CodeLibelle: 'RULES-LAB_486'; Nature: ncCompetence; AccepteFiltre: False; CibleFixe: ''; ValeurNonNulle: True)
  );

Var
  // Liste unique de tous les modificateurs du catalogue, quelle que soit leur source :
  // alimentee par les chargeurs en parallele des listes par source, le temps de migrer les
  // calculs vers un collecteur unique.
  ListModificateur: TListModificateur;
  ListConditionDonnee: TListConditionDonnee;
  // Libelle du livre en cours d'import, pose par XmlImport (lu par AjouteModificateurUnique).
  LivreImportEnCours: String;

Procedure AjouteModificateurUnique(Const Source: String; Modif: StructureModificateur);
// Vrai si l'entree vient d'une qualite de fabrication (fabrication, qualite d'arme, trapping) :
// remplace la liste a part ListFabricationModificateur.
Function EntreeFabrication(Const Entree: StructureModificateur): Boolean;
// Vrai si l'entree est un modificateur de competence d'une piece portee (ModifySkillGear d'une
// qualite d'armure) : colonne "avec equipement" du PDF, hors Total.
Function EntreeCompetenceEquip(Const Entree: StructureModificateur): Boolean;
// Indice de Balise dans TypesEffet, -1 si la balise n'est pas un type d'effet connu.
Function IndiceTypeEffet(Const Balise: String): Integer;
// Vrai si un modificateur de ce type et de ce filtre s'ecrit au format generique
// <Modificateur Type= Cible= Facteur= Filtre=/> plutot qu'a la balise historique : seul
// ModifyWeapon porte son filtre en attribut (skill=). Commun a l'export et a WinLivre.
Function EcritureGenerique(Const TypeModif, Filtre: String): Boolean;

implementation

Procedure AjouteModificateurUnique(Const Source: String; Modif: StructureModificateur);
begin
  Modif.TypeSource := Source;
  Modif.Livre      := LivreImportEnCours;
  ListModificateur.Add(Modif);
end;

Function EntreeFabrication(Const Entree: StructureModificateur): Boolean;
begin
  Result := (Entree.TypeSource = SourceModifFabrication) or (Entree.TypeSource = SourceModifQualiteArme)
            or (Entree.TypeSource = SourceModifTrapping);
end;

Function EntreeCompetenceEquip(Const Entree: StructureModificateur): Boolean;
begin
  Result := (Entree.TypeSource = SourceModifArmureBonus) and (Entree.TypeModif = ConstXmlModifieCompetenceEquip);
end;

Function IndiceTypeEffet(Const Balise: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to NbTypesEffet - 1 do
    if TypesEffet[I].Balise = Balise then Exit(I);
end;

Function EcritureGenerique(Const TypeModif, Filtre: String): Boolean;
begin
  Result := (Filtre <> '') and (TypeModif <> ConstXmlModifieArme);
end;

initialization
  ListModificateur := TListModificateur.Create;
  ListConditionDonnee := TListConditionDonnee.Create;

finalization
  ListModificateur.Free;
  ListConditionDonnee.Free;


end.

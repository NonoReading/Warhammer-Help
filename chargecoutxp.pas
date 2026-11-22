unit ChargeCoutXp;

// Cout en XP d'une avance, SANS ecran : table des caracteristiques et competences (paliers de 5 de la V4),
// talents (100 XP + 100 par talent deja pris), regles V1 / V2. Les surcouts du MJ (CalculXpMj) et l'option XP / 25
// restent dans WinPersonnage (CalculExperience), qui appelle cette fonction. Testee par --testcreation (fonction « cout »).

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ChargeConstantes;

// TypeXp : ConstXmlCarac / ConstXmlCompetence / ConstXmlTalent ; Gratuit = valeur de depart ; Total = valeur visee.
// Code : code de l'attribut (V1 / V2 : pas d'une avance) ; peut etre vide pour une competence ou un talent.
Function CoutXpBase(TypeXp: String; Gratuit: Integer; Total: Integer; Code: String): Integer;

// Cout reel d'un talent : double hors carriere (V1 / V4) ; en V2 double seulement si le MJ l'a ajoute (AjoutMj).
Function CoutReelTalent(Cout: Integer; HorsCarriere: Boolean; AjoutMj: Boolean): Integer;

implementation

uses
  ChargeAttributAugmentation, ChargeCompetenceAugmentation, ChargeMetierAttribut;

Function CoutReelTalent(Cout: Integer; HorsCarriere: Boolean; AjoutMj: Boolean): Integer;
  begin
    // V5 : seuls les talents de la carriere (niveau actuel ou inferieur) s'achetent, pas de double cout (p.191)
    if (ValVersion = 'WFRP5') and not AjoutMj then
      Result := Cout
    else if ((ValVersion <> 'WFRP2') and HorsCarriere) or ((ValVersion = 'WFRP2') and AjoutMj) then
      Result := Cout * 2
    else
      Result := Cout;
  end;

// V5 (Rulebook p.191) : le tableau donne le cout de CHAQUE avance de +5 (name = +5, +10, ... = rang de l'avance x 5),
// pas des paliers. Au-dela de la derniere ligne du livre, on garde le dernier cout.
Function CoutAvanceV5(TypeXp: String; Increase: Integer): Integer;
  var
    PAttr:    StructureAttributAugmentation;
    PComp:    StructureCompetenceAugmentation;
    Dernier:  Integer = 0;
    Meilleur: Integer = 0;
    Valeur:   Integer;
  begin
    Result := 0;
    if TypeXp = ConstXmlCarac then
      begin
        for PAttr in ListeAttributAugmentation do
          begin
            Valeur := StrToIntDef(PAttr.MinMax, 0);
            if Valeur = Increase then
              Exit(PAttr.Cout);
            if Valeur > Dernier then
              begin
                Dernier  := Valeur;
                Meilleur := PAttr.Cout;
              end;
          end;
      end
    else
      for PComp in ListeCompetenceAugmentation do
        begin
          Valeur := StrToIntDef(PComp.MinMax, 0);
          if Valeur = Increase then
            Exit(PComp.Cout);
          if Valeur > Dernier then
            begin
              Dernier  := Valeur;
              Meilleur := PComp.Cout;
            end;
        end;
    Result := Meilleur;
  end;

Function CoutXpBase(TypeXp: String; Gratuit: Integer; Total: Integer; Code: String): Integer;
  var
    Xp:                      Integer = 0;
    AffecteBonus:            Integer;
    AffecteGratuit:          Integer;
    RestantBonus:            Integer;
    RestantGratuit:          Integer;
    Min:                     Integer = 0;
    Max:                     Integer = 5;
    PAttributAugmentation:   StructureAttributAugmentation;
    PCompetenceAugmentation: StructureCompetenceAugmentation;
    i:                       Integer;
  begin
    // V2 : une competence monte par paliers de +10 % (Skill Mastery), 100 XP par palier
    if (ValVersion = 'WFRP2') and (TypeXp = ConstXmlCompetence) then
      begin
        if Total > Gratuit then
          Xp := 100 * ((Total - Gratuit) div 10);
      end
    // V1 / V2 : une caracteristique monte par avances de 100 XP (pas selon l'attribut) ; la table V4 n'a pas de lignes V1 / V2.
    else if AvanceParSchema() and (TypeXp = ConstXmlCarac) then
      begin
        if (Total > Gratuit) and (Code <> '') then
          Xp := 100 * ((Total - Gratuit) div PasAvance(Code));
      end
    // V5 : avances de +5, cout de l'avance numero n lu dans le tableau (n = valeur atteinte / 5)
    else if (ValVersion = 'WFRP5') and ((TypeXp = ConstXmlCarac) or (TypeXp = ConstXmlCompetence)) then
      begin
        for i := (Gratuit div 5) + 1 to (Total div 5) do
          Xp := Xp + CoutAvanceV5(TypeXp, 5 * i);
      end
    else if TypeXp = ConstXmlTalent then
      begin
        // V5 (Rulebook p.191) : chaque talent coute 100 XP, repris autant de fois que voulu a 100 XP chacune ;
        // V1 / V2 / V4 : 100 XP le premier, puis 100 de plus par talent deja pris
        if Total > Gratuit then
          for i := Gratuit to (Total - 1) do
            if ValVersion = 'WFRP5' then
              Xp := Xp + 100
            else
              Xp := Xp + 100 + (100 * i);
      end
    else
      begin
        // calcul du restant total
        RestantGratuit := Gratuit;
        RestantBonus   := Total - RestantGratuit;

        // boucle 5 par 5
        while (RestantBonus > 0) or (RestantGratuit > 0) do
          begin
            // affectation en gratuit
            if RestantGratuit > 0 then
              begin
                if RestantGratuit >= 5 then
                  AffecteGratuit := 5
                else
                  AffecteGratuit := RestantGratuit;
                RestantGratuit := RestantGratuit - AffecteGratuit;
              end
            else
              AffecteGratuit := 0;

            // affectation en payant
            if AffecteGratuit < 5 then
              begin
                // la place restante du palier : si le depart n'est pas un multiple de 5, le palier est deja
                // entame par les avances prises (3 avances prises = 2 places, pas 5 ; Rulebook p.44)
                if RestantBonus <= (5 - AffecteGratuit) then
                  AffecteBonus := RestantBonus
                else
                  AffecteBonus := 5 - AffecteGratuit;
                RestantBonus := RestantBonus - AffecteBonus;
              end
            else
              AffecteBonus := 0;

            // cout en XP du palier
            if AffecteBonus > 0 then
              begin
                case TypeXp of
                  ConstXmlCarac:
                    begin
                      PAttributAugmentation := ChercheAttributAugmentation(Min, Max);
                      Xp := Xp + (AffecteBonus * PAttributAugmentation.Cout);
                    end;
                  ConstXmlCompetence:
                    begin
                      PCompetenceAugmentation := ChercheCompetenceAugmentation(Min, Max);
                      Xp := Xp + (AffecteBonus * PCompetenceAugmentation.Cout);
                    end;
                end;
              end;

            // bornes suivantes
            if Min = 0 then
              Min := 1;
            Min := Min + 5;
            Max := Max + 5;
          end;
      end;
    Result := Xp;
  end;

end.

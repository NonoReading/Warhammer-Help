unit PanelRaceExtra;

{$mode ObjFPC}{$H+}

// Bloc glisse sous les champs de la fiche d'une RACE (propriete Extra de TPanelFiche, qui n'en accepte qu'un) :
// les opinions (TPanelOpinions) puis les details physiques (TPanelPhysique), l'un sous l'autre. Chaque panneau garde
// son propre chargement, controle et ecriture ; celui-ci ne fait que les empiler et les appeler dans l'ordre du schema
// de DATA_RACE : Description, OPINIONS, SUBCHAPTER_PHYSICAL.

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, DOM, BCButton,
  PanelFiche, PanelOpinions, PanelPhysique;

type
  TPanelRaceExtra = class(TPanelExtraFiche)
  private
    FOpinions: TPanelOpinions;
    FPhysique: TPanelPhysique;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Initialiser(Modele: TBCButton);
    // A appeler avant chaque Charger : les races proposees comme cible d'une opinion.
    procedure Configurer(Codes, Libelles: TStrings);
    procedure Charger(Element: TDOMElement); override;
    function  Controler: Boolean; override;
    procedure Ecrire(Element: TDOMElement); override;
    function  Signature(const Sep: String): String; override;
    procedure MettreLectureSeule(Valeur: Boolean); override;
  end;

implementation

constructor TPanelRaceExtra.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  FOpinions := TPanelOpinions.Create(Self);
  FOpinions.Parent := Self;
  FPhysique := TPanelPhysique.Create(Self);
  FPhysique.Parent := Self;
  Visible := False;
end;

procedure TPanelRaceExtra.Initialiser(Modele: TBCButton);
begin
  FOpinions.Initialiser(Modele);
  FPhysique.Initialiser(Modele);
  FOpinions.SetBounds(0, 0, 1000, FOpinions.Height);
  FPhysique.SetBounds(0, FOpinions.Height + 10, 1000, FPhysique.Height);
  Height := FOpinions.Height + 10 + FPhysique.Height;
end;

procedure TPanelRaceExtra.Configurer(Codes, Libelles: TStrings);
begin
  FOpinions.Configurer(Codes, Libelles);
end;

procedure TPanelRaceExtra.Charger(Element: TDOMElement);
begin
  FOpinions.Charger(Element);
  FPhysique.Charger(Element);
  FOpinions.Visible := True;
  FPhysique.Visible := True;
end;

function TPanelRaceExtra.Controler: Boolean;
begin
  Result := FOpinions.Controler and FPhysique.Controler;
end;

// Ordre du schema : les opinions d'abord, puis le physique (chacun se range en fin d'element).
procedure TPanelRaceExtra.Ecrire(Element: TDOMElement);
begin
  FOpinions.Ecrire(Element);
  FPhysique.Ecrire(Element);
end;

function TPanelRaceExtra.Signature(const Sep: String): String;
begin
  Result := FOpinions.Signature(Sep) + FPhysique.Signature(Sep);
end;

procedure TPanelRaceExtra.MettreLectureSeule(Valeur: Boolean);
begin
  FOpinions.MettreLectureSeule(Valeur);
  FPhysique.MettreLectureSeule(Valeur);
end;

end.

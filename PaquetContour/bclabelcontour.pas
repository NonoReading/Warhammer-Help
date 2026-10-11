unit BCLabelContour;

{$mode objfpc}{$H+}

// TBCLabel dont le texte est dessine avec un contour net (ex. texte blanc cerne de rouge,
// comme les titres des livres Warhammer). Le contour est obtenu en dessinant le texte
// plusieurs fois decale sur un cercle, puis une derniere fois au centre. FontEx.Color est
// la couleur du texte ; ContourCouleur / ContourEpaisseur regle le contour.

interface

uses
  Classes, SysUtils, Types, Math, Controls, Graphics, StdCtrls, LCLIntf, BCLabel, BCButton, BCButtonFocus, BCBaseCtrls, BCTypes, BCTools, BGRABitmap, BGRABitmapTypes;

type

  { TBCLabelContour }

  TBCLabelContour = class(TBCLabel)
  private
    FBmp: TBGRABitmap;
    FContourCouleur: TColor;
    FContourEpaisseur: Integer;
    procedure SetContourCouleur(AValue: TColor);
    procedure SetContourEpaisseur(AValue: Integer);
  protected
    procedure DrawControl; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ContourCouleur: TColor read FContourCouleur write SetContourCouleur default TColor($002818E0);
    property ContourEpaisseur: Integer read FContourEpaisseur write SetContourEpaisseur default 2;
  end;

  { TLabelContour : TLabel standard dont le texte est cerne (blanc cerne de rouge par defaut).
    Meme principe : le texte est redessine decale sur un cercle avec ContourCouleur, puis
    au centre avec Font.Color. Transparent est force pour ne pas effacer les passes. }
  TLabelContour = class(TLabel)
  private
    FCouleurTexte: TColor;
    FContourCouleur: TColor;
    FContourEpaisseur: Integer;
    procedure SetCouleurTexte(AValue: TColor);
    procedure SetContourCouleur(AValue: TColor);
    procedure SetContourEpaisseur(AValue: Integer);
  protected
    procedure Paint; override;
    procedure Loaded; override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: integer;
      WithThemeSpace: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    // Couleur du texte au centre. Font.Color n'est volontairement pas utilisee : y toucher
    // faisait mal s'afficher les autres controles de la fenetre au premier affichage.
    property CouleurTexte: TColor read FCouleurTexte write SetCouleurTexte default clWhite;
    property ContourCouleur: TColor read FContourCouleur write SetContourCouleur default TColor($002818E0);
    property ContourEpaisseur: Integer read FContourEpaisseur write SetContourEpaisseur default 2;
  end;

  { TBCButtonContour / TBCButtonFocusContour : boutons dont le texte de l etat normal est
    dessine avec un contour net (jaune cerne de rouge) a la place de l ombre. Les etats
    survol et clic restent dessines comme avant. Le contour est ajoute apres le rendu du
    bouton, par le crochet OnAfterRenderBCButton (reserve a cet usage). }
  TBCButtonContour = class(TBCButton)
  private
    FContourCouleur: TColor;
    FContourEpaisseur: Integer;
    FEtatNormal: Boolean;
    procedure ApresRendu(Sender: TObject; const ABGRA: TBGRABitmap;
      AState: TBCButtonState; ARect: TRect);
  protected
    procedure Render(ABGRA: TBGRABitmapEx; AState: TBCButtonState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ContourCouleur: TColor read FContourCouleur write FContourCouleur default TColor($002818E0);
    property ContourEpaisseur: Integer read FContourEpaisseur write FContourEpaisseur default 2;
  end;

  TBCButtonFocusContour = class(TBCButtonFocus)
  private
    FContourCouleur: TColor;
    FContourEpaisseur: Integer;
    FEtatNormal: Boolean;
    procedure ApresRendu(Sender: TObject; const ABGRA: TBGRABitmap;
      AState: TBCButtonFocusState; ARect: TRect);
  protected
    procedure Render(ABGRA: TBGRABitmapEx; AState: TBCButtonFocusState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ContourCouleur: TColor read FContourCouleur write FContourCouleur default TColor($002818E0);
    property ContourEpaisseur: Integer read FContourEpaisseur write FContourEpaisseur default 2;
  end;

procedure Register;

implementation

const
  NbDirections = 16;

procedure Register;
begin
  RegisterComponents('BGRA Controls', [TBCLabelContour, TLabelContour, TBCButtonContour, TBCButtonFocusContour]);
end;

// Redessine le texte du bouton avec un contour : ContourCouleur decale sur un cercle, puis
// la couleur du texte (sans ombre) au centre. Echelle = rapport de mise a l echelle du rendu.
procedure DessinerTexteContour(const ABGRA: TBGRABitmap; ARect: TRect; AFont: TBCFont;
  const ACaption: string; AEnabled: Boolean; ACouleur: TColor; AEpaisseur: Integer;
  AEchelle: Double);
var
  Police: TBCFont;
  RDecale: TRect;
  I: Integer;
  Angle: Double;
begin
  if ACaption = '' then Exit;
  Police := TBCFont.Create(nil);
  try
    Police.Assign(AFont);
    Police.Shadow := False;
    Police.Color  := ACouleur;
    for I := 0 to NbDirections - 1 do
      begin
        Angle := 2 * Pi * I / NbDirections;
        RDecale := ARect;
        Types.OffsetRect(RDecale, Round(AEpaisseur * AEchelle * Cos(Angle)),
                                  Round(AEpaisseur * AEchelle * Sin(Angle)));
        RenderText(RDecale, Police, ACaption, ABGRA, AEnabled);
      end;
    Police.Assign(AFont);
    Police.Shadow := False;
    RenderText(ARect, Police, ACaption, ABGRA, AEnabled);
  finally
    Police.Free;
  end;
end;

{ TBCButtonContour }

constructor TBCButtonContour.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContourCouleur   := TColor($002818E0);
  FContourEpaisseur := 2;
  OnAfterRenderBCButton := @ApresRendu;
end;

procedure TBCButtonContour.Render(ABGRA: TBGRABitmapEx; AState: TBCButtonState);
begin
  FEtatNormal := AState = StateNormal;
  inherited Render(ABGRA, AState);
end;

procedure TBCButtonContour.ApresRendu(Sender: TObject; const ABGRA: TBGRABitmap;
  AState: TBCButtonState; ARect: TRect);
begin
  if not FEtatNormal then Exit;
  DessinerTexteContour(ABGRA, ARect, AState.FontEx, Caption, Enabled, FContourCouleur,
    FContourEpaisseur, ABGRA.Width / Max(Width, 1));
end;

{ TBCButtonFocusContour }

constructor TBCButtonFocusContour.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContourCouleur   := TColor($002818E0);
  FContourEpaisseur := 2;
  OnAfterRenderBCButton := @ApresRendu;
end;

procedure TBCButtonFocusContour.Render(ABGRA: TBGRABitmapEx; AState: TBCButtonFocusState);
begin
  FEtatNormal := AState = StateNormal;
  inherited Render(ABGRA, AState);
end;

procedure TBCButtonFocusContour.ApresRendu(Sender: TObject; const ABGRA: TBGRABitmap;
  AState: TBCButtonFocusState; ARect: TRect);
begin
  if not FEtatNormal then Exit;
  DessinerTexteContour(ABGRA, ARect, AState.FontEx, Caption, Enabled, FContourCouleur,
    FContourEpaisseur, ABGRA.Width / Max(Width, 1));
end;

{ TBCLabelContour }

constructor TBCLabelContour.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContourCouleur   := TColor($002818E0);
  FContourEpaisseur := 2;
  FBmp := TBGRABitmap.Create(Width, Height);
end;

destructor TBCLabelContour.Destroy;
begin
  FBmp.Free;
  inherited Destroy;
end;

procedure TBCLabelContour.SetContourCouleur(AValue: TColor);
begin
  if FContourCouleur = AValue then Exit;
  FContourCouleur := AValue;
  Invalidate;
end;

procedure TBCLabelContour.SetContourEpaisseur(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FContourEpaisseur = AValue then Exit;
  FContourEpaisseur := AValue;
  Invalidate;
end;

procedure TBCLabelContour.DrawControl;
var
  R, RDecale: TRect;
  PoliceContour: TBCFont;
  I: Integer;
  Angle: Double;
begin
  if (csCreating in ControlState) or (Width <= 0) or (Height <= 0) then Exit;

  FBmp.SetSize(Width, Height);
  FBmp.Fill(BGRAPixelTransparent);
  R := Rect(0, 0, Width, Height);

  PoliceContour := TBCFont.Create(Self);
  try
    PoliceContour.Assign(FontEx);
    PoliceContour.Color  := FContourCouleur;
    PoliceContour.Shadow := False;
    for I := 0 to NbDirections - 1 do
      begin
        Angle := 2 * Pi * I / NbDirections;
        RDecale := R;
        OffsetRect(RDecale, Round(FContourEpaisseur * Cos(Angle)),
                            Round(FContourEpaisseur * Sin(Angle)));
        RenderText(RDecale, PoliceContour, Caption, FBmp, Enabled);
      end;
  finally
    PoliceContour.Free;
  end;

  // Texte au centre, par-dessus le contour (sans ombre pour ne pas salir le trait)
  PoliceContour := TBCFont.Create(Self);
  try
    PoliceContour.Assign(FontEx);
    PoliceContour.Shadow := False;
    RenderText(R, PoliceContour, Caption, FBmp, Enabled);
  finally
    PoliceContour.Free;
  end;

  FBmp.Draw(Canvas, 0, 0, False);
end;

{ TLabelContour }

constructor TLabelContour.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCouleurTexte     := clWhite;
  FContourCouleur   := TColor($002818E0);
  FContourEpaisseur := 2;
  Transparent := True;
end;

procedure TLabelContour.Loaded;
begin
  inherited Loaded;
  Transparent := True;
end;

procedure TLabelContour.SetCouleurTexte(AValue: TColor);
begin
  if FCouleurTexte = AValue then Exit;
  FCouleurTexte := AValue;
  Invalidate;
end;

procedure TLabelContour.SetContourCouleur(AValue: TColor);
begin
  if FContourCouleur = AValue then Exit;
  FContourCouleur := AValue;
  Invalidate;
end;

procedure TLabelContour.SetContourEpaisseur(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if FContourEpaisseur = AValue then Exit;
  FContourEpaisseur := AValue;
  Invalidate;
end;

procedure TLabelContour.CalculatePreferredSize(var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  inherited CalculatePreferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
  // Marge pour que le contour ne soit pas rogne sur les bords (le texte est decale de
  // ContourEpaisseur dans Paint)
  if PreferredWidth > 0 then Inc(PreferredWidth, 2 * FContourEpaisseur);
  if PreferredHeight > 0 then Inc(PreferredHeight, 2 * FContourEpaisseur);
end;

procedure TLabelContour.Paint;
var
  I: Integer;
  Angle: Double;
  CouleurOrigine: TColor;
  Origine, OrigineReelle: TPoint;
  SurChangementPolice: TNotifyEvent;
begin
  // LCL place deja l'origine du DC a la position du libelle : on decale par rapport
  // a elle et on la restaure exactement, sinon les controles suivants sont decales.
  // Changer Font.Color pendant le dessin ferait demander un nouvel affichage a LCL
  // (cascade de rafraichissements au premier affichage) : on coupe la notification.
  CouleurOrigine := Font.Color;
  SurChangementPolice := Font.OnChange;
  Font.OnChange := nil;
  GetViewPortOrgEx(Canvas.Handle, @Origine);
  OrigineReelle := Origine;
  Origine.X := Origine.X + FContourEpaisseur;
  Origine.Y := Origine.Y + FContourEpaisseur;
  try
    Font.Color := FContourCouleur;
    for I := 0 to NbDirections - 1 do
      begin
        Angle := 2 * Pi * I / NbDirections;
        SetViewPortOrgEx(Canvas.Handle, Origine.X + Round(FContourEpaisseur * Cos(Angle)),
                         Origine.Y + Round(FContourEpaisseur * Sin(Angle)), nil);
        inherited Paint;
      end;
  finally
    SetViewPortOrgEx(Canvas.Handle, Origine.X, Origine.Y, nil);
    Font.OnChange := nil;
    Font.Color := FCouleurTexte;
  end;
  try
    inherited Paint;
  finally
    SetViewPortOrgEx(Canvas.Handle, OrigineReelle.X, OrigineReelle.Y, nil);
    Font.Color := CouleurOrigine;
    Font.OnChange := SurChangementPolice;
  end;
end;

initialization
  RegisterClass(TBCLabelContour);
  RegisterClass(TLabelContour);
  RegisterClass(TBCButtonContour);
  RegisterClass(TBCButtonFocusContour);

end.

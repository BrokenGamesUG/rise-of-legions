unit Engine.ParticleEffects.Types;

interface

uses
  Engine.GFXApi,
  Engine.Serializer.Types,
  Engine.Helferlein.VCLUtils,
  Engine.Math;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  EnumParticleTypes = (ptPointsprite, ptQuad, ptLight, ptEffect, ptTrace);
  EnumParticleBlendMode = (pbAdditive, pbShaded, pbSubtractive, pbLinear, pbGlow, pbDistortion);

  [XMLIncludeAll([XMLIncludeFields])]
  TDiffuseNormalTexture = class
    Diffuse, Normal : TTexture;
    destructor Destroy; override;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  RParticleTexture = record
  [VCLEnumField]
    BlendMode : EnumParticleBlendMode;
    [VCLBooleanField]
    IgnoreZ : boolean;
    [VCLBooleanField]
    Softparticle : boolean;
    [VCLBooleanField]
    AlphaSubtraction : boolean;
    [VCLFileField]
    TextureFileName : string;
    [VCLFileField]
    NormalMapFileName : string;
    [VCLIntegerField(-10000, 10000, icSpinEdit)]
    DrawOrder : integer;
    constructor Create(BlendMode : EnumParticleBlendMode; TextureFileName : string; IgnoreZ, Softparticle, AlphaSubtraction : boolean; DrawOrder : integer); overload;
    constructor Create(BlendMode : EnumParticleBlendMode; TextureFileName, NormalMapFileName : string; IgnoreZ, Softparticle, AlphaSubtraction : boolean; DrawOrder : integer); overload;
    class operator equal(const a, b : RParticleTexture) : boolean;
    function Hash : integer;
  end;

  /// <summary> Connects two classes with each other regarding that the parent class could stop existing, but
  /// don't now its children to notify them. (monodirectional connection) </summary>
  IParentConnector = interface
    procedure SetIsAlive(State : boolean);
    function IsAlive : boolean;
    procedure SetVisible(State : boolean);
    function IsVisible : boolean;
    procedure SetBase(const Position : RMatrix);
    function GetBase : RMatrix;
  end;

  TParentConnector = class(TInterfacedObject, IParentConnector)
    protected
      FBase : RMatrix;
      FIsAlive, FVisible : boolean;
    public
      constructor Create;
      procedure SetBase(const Base : RMatrix);
      function GetBase : RMatrix;
      procedure SetVisible(State : boolean);
      function IsVisible : boolean;
      procedure SetIsAlive(State : boolean);
      function IsAlive : boolean;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

{ RParticleTexture }

constructor RParticleTexture.Create(BlendMode : EnumParticleBlendMode; TextureFileName, NormalMapFileName : string; IgnoreZ, Softparticle, AlphaSubtraction : boolean; DrawOrder : integer);
begin
  self.BlendMode := BlendMode;
  self.TextureFileName := TextureFileName;
  self.NormalMapFileName := NormalMapFileName;
  self.IgnoreZ := IgnoreZ;
  self.AlphaSubtraction := AlphaSubtraction;
  self.Softparticle := Softparticle;
  self.DrawOrder := DrawOrder;
end;

class operator RParticleTexture.equal(const a, b : RParticleTexture) : boolean;
begin
  Result := (a.BlendMode = b.BlendMode) and (a.TextureFileName = b.TextureFileName) and (a.NormalMapFileName = b.NormalMapFileName) and (a.IgnoreZ = b.IgnoreZ) and (a.Softparticle = b.Softparticle) and (a.AlphaSubtraction = b.AlphaSubtraction) and (a.DrawOrder = b.DrawOrder);
end;

function RParticleTexture.Hash : integer;
begin
  Result := Length(TextureFileName) + Length(NormalMapFileName) + ord(BlendMode) + ord(IgnoreZ) + ord(Softparticle) + ord(AlphaSubtraction) + DrawOrder;
end;

constructor RParticleTexture.Create(BlendMode : EnumParticleBlendMode; TextureFileName : string; IgnoreZ, Softparticle, AlphaSubtraction : boolean; DrawOrder : integer);
begin
  Create(BlendMode, TextureFileName, '', IgnoreZ, Softparticle, AlphaSubtraction, DrawOrder);
end;

{ TDiffuseNormalTexture }

destructor TDiffuseNormalTexture.Destroy;
begin
  Diffuse.Free;
  Normal.Free;
  inherited;
end;

{ TSharedPosition }

constructor TParentConnector.Create;
begin
  FIsAlive := True;
  FVisible := True;
end;

function TParentConnector.GetBase : RMatrix;
begin
  Result := FBase;
end;

function TParentConnector.IsAlive : boolean;
begin
  Result := FIsAlive;
end;

function TParentConnector.IsVisible : boolean;
begin
  Result := FVisible;
end;

procedure TParentConnector.SetBase(const Base : RMatrix);
begin
  FBase := Base;
end;

procedure TParentConnector.SetIsAlive(State : boolean);
begin
  FIsAlive := State;
end;

procedure TParentConnector.SetVisible(State : boolean);
begin
  FVisible := State;
end;

end.

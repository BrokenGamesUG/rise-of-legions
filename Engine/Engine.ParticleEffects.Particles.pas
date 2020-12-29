unit Engine.ParticleEffects.Particles;

interface

uses
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.ParticleEffects.Types,
  Engine.Vertex,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Core,
  Engine.Core.Types,
  Engine.Core.Lights,
  Engine.Math.Collision2D,
  SysUtils;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  CParticle = class of TParticle;

  TParticle = class
    protected
      FOrigin : RMatrix;
    public
      Position, Front, Up, Rotation : RVector3;
      Scaling : RVector3;
      Color : RVector4;
      SimulationData : TObject;
      EmitterPosition : IParentConnector;
      DieWithEmitter : boolean;
      TimeOffset : integer;
      FixedRandomFactor : single;
      constructor Create; overload;
      constructor Create(Position, Front, Up, Scaling : RVector3); overload;
      /// <summary> Should be called each time the particle gets simulated. </summary>
      procedure AfterSimulation; virtual;
      procedure AfterInitialization; virtual;
      property Origin : RMatrix read FOrigin write FOrigin;
      function IsVisible : boolean;
      destructor Destroy; override;
  end;

  TGeometrieParticle = class(TParticle)
    protected
      FScreenAlignedOverride : boolean;
    public
      Texture : RParticleTexture;
      TextureRect : RRectFloat;
      function getTexture : RParticleTexture;
      function GetVertexFormat : TVertexdeclaration; virtual; abstract;
      function GetVertexCount : cardinal; virtual; abstract;
      function WriteToBuffer(var Target : Pointer) : cardinal; virtual; abstract;
      constructor Create(ScreenAlignedOverride : boolean = False); overload;
      constructor Create(Position, Front, Up, Scaling : RVector3; Texture : RParticleTexture); overload;
  end;

  TQuadParticle = class(TGeometrieParticle)
    public
      function GetVertexFormat : TVertexdeclaration; override;
      function GetVertexCount : cardinal; override;
      function WriteToBuffer(var Target : Pointer) : cardinal; override;
  end;

  TLightParticle = class(TParticle)
    protected
      Light : TPointLight;
      FRenderContext : TRenderContext;
    public
      IsSubtractive : boolean;
      constructor Create(RenderContext : TRenderContext); overload;
      procedure AfterSimulation; override;
      destructor Destroy; override;
  end;

  TTraceParticle = class(TParticle)
    private
      procedure SetParticleTexture(const Value : RParticleTexture);
    protected
      FTrace : TVertexTrace;
    public
      property Texture : RParticleTexture write SetParticleTexture;
      constructor Create;
      procedure AfterInitialization; override;
      procedure AfterSimulation; override;
      destructor Destroy; override;
  end;

  TParticleEffectParticle = class(TParticle)
    protected
      FParticleEffect : TObject;
      FFirst : boolean; // Emission starts after first simulation
    public
      constructor Create; overload;
      /// <summary> Expects relative path and filename to pfx path. </summary>
      constructor Create(EffectFileName : string); overload;
      procedure AfterSimulation; override;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

uses
  Engine.ParticleEffects;

{ TParticle }

procedure TParticle.AfterInitialization;
begin

end;

procedure TParticle.AfterSimulation;
begin

end;

constructor TParticle.Create(Position, Front, Up, Scaling : RVector3);
begin
  self.Position := Position;
  self.Front := Front;
  self.Up := Up;
  self.Color := RColor.LerpArray(RColor.COLORSPECTRUMARRAY, random);
  self.Scaling := Scaling;
end;

constructor TParticle.Create;
begin
  self.Front := RVector3.UNITZ;
  self.Up := RVector3.UNITY;
  self.Color := RColor(RColor.CWHITE);
  self.Scaling := RVector3(1.0);
end;

destructor TParticle.Destroy;
begin
  SimulationData.Free;
end;

function TParticle.IsVisible : boolean;
begin
  Result := not assigned(EmitterPosition) or EmitterPosition.IsVisible;
end;

{ TQuadParticle }

function TQuadParticle.WriteToBuffer(var Target : Pointer) : cardinal;
var
  Vertex : PVertexPositionNormalColorTextureData;
  Normal, tFront, tUp : RVector3;
begin
  if Scaling.Y < 0 then Scaling.Y := Scaling.X;
  if FScreenAlignedOverride or (Front.isZeroVector and Up.isZeroVector) then
  begin
    tFront := ParticleCameraData.ScreenLeft * (Scaling.Y / 2);
    tUp := ParticleCameraData.ScreenUp * (Scaling.X / 2);
  end
  else
    if Front.isZeroVector then
  begin
    tUp := Up.Normalize * (Scaling.X / 2);
    tFront := ParticleCameraData.CameraDirection.Cross(tUp).Normalize * (Scaling.Y / 2);
  end
  else
    if Up.isZeroVector then
  begin
    tFront := Front.Normalize * (Scaling.Y / 2);
    tUp := ParticleCameraData.CameraDirection.Cross(tFront).Normalize * (Scaling.X / 2);
  end
  else
  begin
    tFront := Front.Normalize * (Scaling.Y / 2);
    tUp := Up.Normalize * (Scaling.X / 2);
  end;

  Normal := tFront.Cross(tUp).Normalize;
  // apply rotation
  if Rotation.Z <> 0 then
  begin
    tFront := tFront.RotateAxis(Normal, Rotation.Z);
    tUp := tUp.RotateAxis(Normal, Rotation.Z);
  end;
  if Rotation.Y <> 0 then
  begin
    tFront := tFront.RotateAxis(tUp, Rotation.Y);
    Normal := Normal.RotateAxis(tUp, Rotation.Y);
  end;
  if Rotation.X <> 0 then
  begin
    Normal := Normal.RotateAxis(tFront, Rotation.X);
    tUp := tUp.RotateAxis(tFront, Rotation.X);
  end;

  Vertex := PVertexPositionNormalColorTextureData(Target);
  Vertex^.Position := Position + tFront + tUp;
  Vertex^.TextureCoordinate := TextureRect.LeftTop;
  Vertex^.Color := Color;
  Vertex^.Normal := Normal;
  Vertex^.Data := Scaling;
  inc(Vertex, 1);
  Vertex^.Position := Position - tFront + tUp;
  Vertex^.TextureCoordinate := TextureRect.RightTop;
  Vertex^.Color := Color;
  Vertex^.Normal := Normal;
  Vertex^.Data := Scaling;
  inc(Vertex, 1);
  Vertex^.Position := Position + tFront - tUp;
  Vertex^.TextureCoordinate := TextureRect.LeftBottom;
  Vertex^.Color := Color;
  Vertex^.Normal := Normal;
  Vertex^.Data := Scaling;
  inc(Vertex, 1);

  Vertex^.Position := Position + tFront - tUp;
  Vertex^.TextureCoordinate := TextureRect.LeftBottom;
  Vertex^.Color := Color;
  Vertex^.Normal := Normal;
  Vertex^.Data := Scaling;
  inc(Vertex, 1);
  Vertex^.Position := Position - tFront + tUp;
  Vertex^.TextureCoordinate := TextureRect.RightTop;
  Vertex^.Color := Color;
  Vertex^.Normal := Normal;
  Vertex^.Data := Scaling;
  inc(Vertex, 1);
  Vertex^.Position := Position - tFront - tUp;
  Vertex^.TextureCoordinate := TextureRect.RightBottom;
  Vertex^.Color := Color;
  Vertex^.Normal := Normal;
  Vertex^.Data := Scaling;
  inc(Vertex, 1);
  Target := Vertex;
  Result := GetVertexCount;
end;

function TQuadParticle.GetVertexCount : cardinal;
begin
  Result := 6;
end;

function TQuadParticle.GetVertexFormat : TVertexdeclaration;
begin
  Result := RVertexPositionNormalColorTextureData.BuildVertexdeclaration();
end;

{ TLightParticle }

procedure TLightParticle.AfterSimulation;
begin
  inherited;
  Light.Position := Position;
  Light.Color := Color;
  Light.Range := Scaling;
  if IsSubtractive then
  begin
    Light.Color.A := -Light.Color.A;
  end;
end;

constructor TLightParticle.Create(RenderContext : TRenderContext);
begin
  inherited Create;
  FRenderContext := RenderContext;
  Light := TPointLight.Create(RColor.CWHITE, Position, Scaling);
  RenderContext.Lights.Add(Light);
end;

destructor TLightParticle.Destroy;
begin
  FRenderContext.Lights.Remove(Light);
  inherited;
end;

{ TTraceParticle }

procedure TTraceParticle.AfterInitialization;
begin
  inherited;
  FTrace.StartTracking;
end;

procedure TTraceParticle.AfterSimulation;
begin
  inherited;
  FTrace.Color := Color;
  FTrace.Trackwidth := Scaling.X;
  FTrace.MaxLength := Scaling.Y;
  FTrace.FadeLength := Scaling.Z;

  FTrace.TrackSetDistance := abs(Rotation.X);
  FTrace.TexturePerDistance := abs(Rotation.Y);

  if assigned(EmitterPosition) then
      FTrace.BasePosition := EmitterPosition.GetBase.Translation;
  FTrace.Position := Position;
  FTrace.Up := Up;
  FTrace.AddRenderJob;
end;

constructor TTraceParticle.Create;
begin
  inherited Create;
  FTrace := TVertexTrace.Create(VertexEngine);
  FTrace.OwnsTexture := False;
end;

destructor TTraceParticle.Destroy;
begin
  FTrace.Free;
  inherited;
end;

procedure TTraceParticle.SetParticleTexture(const Value : RParticleTexture);
var
  NormalMap : TTexture;
begin
  if Value.TextureFileName <> '' then
      FTrace.Texture := ParticleEffectEngine.getTexture(Value, NormalMap);
  FTrace.BlendMode := BlendLinear;
  case Value.BlendMode of
    pbAdditive : FTrace.BlendMode := BlendAdditive;
    pbSubtractive : FTrace.BlendMode := BlendSubtractive;
    pbShaded, pbLinear : FTrace.BlendMode := BlendLinear;
    pbGlow : FTrace.DrawsAtStage := rsGlow;
    pbDistortion : FTrace.DrawsAtStage := rsDistortion;
  end;
  FTrace.DrawOrder := Value.DrawOrder;
end;

{ TGeometrieParticle }

constructor TGeometrieParticle.Create(Position, Front, Up, Scaling : RVector3; Texture : RParticleTexture);
begin
  inherited Create(Position, Front, Up, Scaling);
  self.Texture := Texture;
  self.TextureRect := RRectFloat.DEFAULT;
end;

constructor TGeometrieParticle.Create(ScreenAlignedOverride : boolean);
begin
  inherited Create;
  FScreenAlignedOverride := ScreenAlignedOverride;
  self.TextureRect := RRectFloat.DEFAULT;
end;

function TGeometrieParticle.getTexture : RParticleTexture;
begin
  Result := Texture;
end;

{ TParticleEffectParticle }

procedure TParticleEffectParticle.AfterSimulation;
begin
  inherited;
  if assigned(FParticleEffect) then
  begin
    TParticleEffect(FParticleEffect).Position := Position;
    TParticleEffect(FParticleEffect).Front := Front;
    TParticleEffect(FParticleEffect).Up := Up;
    TParticleEffect(FParticleEffect).Size := Scaling.MaxValue;
    if FFirst then
    begin
      TParticleEffect(FParticleEffect).StartEmission;
      FFirst := False;
    end;
  end;
end;

constructor TParticleEffectParticle.Create;
begin
  assert(False, 'TParticleEffectParticle.Create: This constructor shouldn''t be used');
end;

constructor TParticleEffectParticle.Create(EffectFileName : string);
begin
  FParticleEffect := ParticleEffectEngine.CreateParticleEffectFromFile(HFilepathManager.RelativeToAbsolute(ParticleEffectEngine.AssetPath + '\' + EffectFileName));
  FFirst := True;
end;

destructor TParticleEffectParticle.Destroy;
begin
  FParticleEffect.Free;
  inherited;
end;

end.

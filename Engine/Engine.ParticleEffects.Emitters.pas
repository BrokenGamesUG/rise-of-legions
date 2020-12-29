unit Engine.ParticleEffects.Emitters;

interface

uses
  Generics.Collections,
  Math,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Vertex,
  Engine.Serializer.Types,
  Engine.ParticleEffects.Types,
  Engine.ParticleEffects.Particles,
  Engine.ParticleEffects.Simulators,
  Engine.Helferlein.VCLUtils;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  [XMLIncludeAll([XMLIncludeFields])]
  TParticleEmitter = class
    protected
      FPosition, FFront, FUp : RVector3;
      FTextureAtlasSize : RIntVector2;
      FSize : single;
      FRotation : RVariedVector3;
      FParticleType : EnumParticleTypes;
      FEmissionCount, FTimes : integer;
      FStartingOffset : RVariedInteger;
      FSimulationData : TPatternSimulationData;
      FStickToEmitter, FDieWithEmitter : boolean;
      FEmittedEffect : string;
      [VCLEditInstance]
      FParticleTexture : RParticleTexture;
      function GetBase : RMatrix;
      procedure Emit(CurrentBase : RMatrix; Base : IParentConnector);
      procedure setFront(const Value : RVector3);
      procedure setPosition(const Value : RVector3); virtual;
      procedure setUp(const Value : RVector3);
      procedure setSize(const Value : single);
    public
      [VCLListChoiceField('inherited.SimulationData')]
      property SimulationData : TPatternSimulationData read FSimulationData write FSimulationData;
      [VCLEnumField]
      property ParticleType : EnumParticleTypes read FParticleType write FParticleType;
      [VCLIntegerField(0, 1000, icSpinEdit)]
      property EmissionCount : integer read FEmissionCount write FEmissionCount;
      [VCLIntegerField(0, 1000, icSpinEdit)]
      property Times : integer read FTimes write FTimes;
      [VCLRVector3Field(1000, 1000, 1000, isEdit)]
      property Position : RVector3 read FPosition write setPosition;
      [VCLRVector3Field(1000, 1000, 1000, isEdit)]
      property Front : RVector3 read FFront write setFront;
      [VCLRVector3Field(1000, 1000, 1000, isEdit)]
      property Up : RVector3 read FUp write setUp;
      [VCLVariedRVector3Field()]
      property Rotation : RVariedVector3 read FRotation write FRotation;
      [VCLVariedIntegerField(0, 1000, 0, icEdit)]
      property TimeOffset : RVariedInteger read FStartingOffset write FStartingOffset;
      [VCLRIntVector2Field(32, 32)]
      property TextureAtlasSize : RIntVector2 read FTextureAtlasSize write FTextureAtlasSize;
      [VCLBooleanField()]
      property StickToEmitter : boolean read FStickToEmitter write FStickToEmitter;
      [VCLBooleanField()]
      property DieWithEmitter : boolean read FDieWithEmitter write FDieWithEmitter;
      [VCLFileField]
      property EmittedEffect : string read FEmittedEffect write FEmittedEffect;
      property ParticleTexture : RParticleTexture read FParticleTexture write FParticleTexture;
      constructor Create; overload;
      constructor Create(Position, Front, Up : RVector3; Rotation : RVariedVector3); overload;
      procedure DrawDebug;
      destructor Destroy; override;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TParticleEmissionTrigger = class
    protected
      [XMLExcludeElement]
      FParentConnector : IParentConnector;
      FEmitter : TParticleEmitter;
      procedure Emit;
    public
      [VCLListChoiceField('inherited.Emitter')]
      property Emitter : TParticleEmitter read FEmitter write FEmitter;
      constructor Create; overload;
      constructor Create(TriggeredEmitter : TParticleEmitter); overload;
      function Copy : TParticleEmissionTrigger; virtual; abstract;
      procedure SetParentConnector(ParentConnector : IParentConnector);
      procedure Idle; virtual;
      procedure StartEmission; virtual; abstract;
      procedure StopEmission; virtual; abstract;
      destructor Destroy; override;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TInstantEmissionTrigger = class(TParticleEmissionTrigger)
    public
      constructor Create;
      function Copy : TParticleEmissionTrigger; override;
      procedure StartEmission; override;
      procedure StopEmission; override;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TIntervalEmissionTrigger = class(TParticleEmissionTrigger)
    private
      function getInterval : integer;
      procedure setInterval(const Value : integer);
    protected
      FInterval : TTimer;
    public
      [VCLIntegerField(0, 10000, icSpinEdit)]
      property Interval : integer read getInterval write setInterval;
      constructor Create; overload;
      constructor Create(EmissionInterval : int64); overload;
      constructor Create(TriggeredEmitter : TParticleEmitter; EmissionInterval : int64); overload;
      function Copy : TParticleEmissionTrigger; override;
      procedure Idle; override;
      procedure StartEmission; override;
      procedure StopEmission; override;
      destructor Destroy; override;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TDistanceEmissionTrigger = class(TParticleEmissionTrigger)
    protected
      FEmitDistance, FTravelledDistance : single;
      [XMLExcludeElement]
      FLastPosition : RVector3;
      [XMLExcludeElement]
      FEmitting : boolean;
    public
      [VCLSingleField(1000, isEdit)]
      property EmitDistance : single read FEmitDistance write FEmitDistance;
      constructor Create; overload;
      constructor Create(EmissionDistance : single); overload;
      constructor Create(TriggeredEmitter : TParticleEmitter; EmissionDistance : single); overload;
      function Copy : TParticleEmissionTrigger; override;
      procedure Idle; override;
      procedure StartEmission; override;
      procedure StopEmission; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation


{ TParticleEmitter }

constructor TParticleEmitter.Create(Position, Front, Up : RVector3; Rotation : RVariedVector3);
begin
  Create;
  self.Position := Position;
  self.Front := Front;
  self.Up := Up;
  self.FRotation := Rotation;
end;

constructor TParticleEmitter.Create;
begin
  Front := RVector3.UNITZ;
  Up := RVector3.UNITY;
  ParticleType := ptQuad;
  EmissionCount := 1;
  FParticleTexture.Softparticle := True;
  Times := 1;
end;

destructor TParticleEmitter.Destroy;
begin
  // it does not own this
  SimulationData := nil;
end;

procedure TParticleEmitter.DrawDebug;
var
  i : integer;
  rotMat, Origin : RMatrix;
begin
  LinePool.AddCoordinateSystem(GetBase);
  RandSeed := 0;
  for i := 0 to 100 do
  begin
    rotMat := RMatrix.CreateRotationPitchYawRoll(FRotation.getRandomVector);
    Origin := GetBase * rotMat;
    LinePool.AddLine(Origin.Translation, Origin.Translation + (Origin.Get3x3 * RVector3.UNITZ), RCOlor.CYELLOW);
  end;
  randomize;
end;

procedure TParticleEmitter.Emit(CurrentBase : RMatrix; Base : IParentConnector);
var
  i, Iteration : integer;
  EmissionCountFactor : single;
  FinalRotation : RVector3;
  Particle : TParticle;
  ownBase, rotMat : RMatrix;
begin
  if not assigned(SimulationData) then exit;
  ownBase := GetBase;
  for Iteration := 0 to FTimes - 1 do
  begin
    for i := 0 to EmissionCount - 1 do
    begin
      if (EmissionCount - 1) > 0 then
          EmissionCountFactor := i / (EmissionCount - 1)
      else
          EmissionCountFactor := 0;

      FinalRotation := FRotation.getRandomVector;
      if (FRotation.Variance.X < 0) then FinalRotation.X := FRotation.LerpDim(0, EmissionCountFactor);
      if (FRotation.Variance.Y < 0) then FinalRotation.Y := FRotation.LerpDim(1, EmissionCountFactor);

      rotMat := RMatrix.CreateRotationPitchYawRoll(FinalRotation);
      case ParticleType of
        ptPointsprite : Particle := TQuadParticle.Create(True);
        ptQuad : Particle := TQuadParticle.Create;
        ptLight : Particle := TLightParticle.Create(SimulationData.Simulator.Scene);
        ptTrace : Particle := TTraceParticle.Create;
        ptEffect :
          begin
            if EmittedEffect = '' then continue;
            Particle := TParticleEffectParticle.Create(FEmittedEffect);
          end
      else
        // assert(False, 'TParticleEmitter.Emit: Unknown ParticleType!');
        continue;
        Particle := nil; // needed to quiet the annoying warning
      end;
      if (FTimes * EmissionCount) - 1 > 0 then
          Particle.FixedRandomFactor := (i + Iteration * EmissionCount) / ((FTimes * EmissionCount) - 1)
      else
          Particle.FixedRandomFactor := 0;
      Particle.Origin := CurrentBase * ownBase * rotMat;

      if TimeOffset.Variance < 0 then Particle.TimeOffset := TimeOffset.Lerp(EmissionCountFactor)
      else Particle.TimeOffset := TimeOffset.Random;

      if StickToEmitter or DieWithEmitter then
      begin
        Particle.EmitterPosition := Base;
        Particle.DieWithEmitter := FDieWithEmitter;

        if StickToEmitter then Particle.Origin := ownBase * rotMat;
      end;

      if Particle is TGeometrieParticle then
      begin
        TGeometrieParticle(Particle).Texture := ParticleTexture;
        if not FTextureAtlasSize.HasAZero then
            TGeometrieParticle(Particle).TextureRect := RRectFloat.CreateWidthHeight(1 / FTextureAtlasSize * FTextureAtlasSize.Random, 1 / FTextureAtlasSize);
      end;
      if Particle is TTraceParticle then
      begin
        TTraceParticle(Particle).Texture := ParticleTexture;
      end;
      if Particle is TLightParticle then
      begin
        TLightParticle(Particle).IsSubtractive := ParticleTexture.BlendMode = pbSubtractive;
      end;
      assert(assigned(SimulationData.Simulator));
      SimulationData.Simulator.InitParticle(SimulationData, Particle);
    end;
  end;
end;

function TParticleEmitter.GetBase : RMatrix;
begin
  Result := RMatrix.CreateTranslation(Position) * RMatrix.CreateSaveBase(Front, Up);
end;

procedure TParticleEmitter.setFront(const Value : RVector3);
begin
  FFront := Value.Normalize;
end;

procedure TParticleEmitter.setPosition(const Value : RVector3);
begin
  FPosition := Value;
end;

procedure TParticleEmitter.setSize(const Value : single);
begin
  FSize := Value;
end;

procedure TParticleEmitter.setUp(const Value : RVector3);
begin
  FUp := Value.Normalize;
end;

{ TIntervalEmissionTrigger }

function TIntervalEmissionTrigger.Copy : TParticleEmissionTrigger;
begin
  Result := TIntervalEmissionTrigger.Create(FInterval.Interval);
  Result.FEmitter := FEmitter;
end;

constructor TIntervalEmissionTrigger.Create(EmissionInterval : int64);
begin
  inherited Create();
  FInterval := TTimer.CreatePaused(EmissionInterval);
end;

constructor TIntervalEmissionTrigger.Create;
begin
  inherited Create;
  FInterval := TTimer.CreatePaused(1000);
end;

constructor TIntervalEmissionTrigger.Create(TriggeredEmitter : TParticleEmitter; EmissionInterval : int64);
begin
  inherited Create(TriggeredEmitter);
  FInterval := TTimer.CreatePaused(EmissionInterval);
end;

destructor TIntervalEmissionTrigger.Destroy;
begin
  FInterval.Free;
  inherited;
end;

function TIntervalEmissionTrigger.getInterval : integer;
begin
  Result := FInterval.Interval;
end;

procedure TIntervalEmissionTrigger.Idle;
const
  MAX_OUTPUT_TIMES = 1000 div 25; // fastest emitter could be 25ms, shouldn't emit more than 1s
var
  i : integer;
begin
  inherited;
  if not FInterval.Expired or FInterval.Paused then exit;
  // clamp particle output, due lag spikes
  for i := 0 to FInterval.TimesExpired(MAX_OUTPUT_TIMES) - 1 do
      Emit;
  FInterval.StartWithFrac;
end;

procedure TIntervalEmissionTrigger.setInterval(const Value : integer);
begin
  FInterval.Interval := Value;
end;

procedure TIntervalEmissionTrigger.StartEmission;
begin
  FInterval.Expired := True;
  FInterval.Weiter;
end;

procedure TIntervalEmissionTrigger.StopEmission;
begin
  FInterval.Expired := True;
  FInterval.Pause;
end;

{ TInstantEmissionTrigger }

function TInstantEmissionTrigger.Copy : TParticleEmissionTrigger;
begin
  Result := TInstantEmissionTrigger.Create();
  Result.FEmitter := FEmitter;
end;

constructor TInstantEmissionTrigger.Create;
begin
  inherited;
end;

procedure TInstantEmissionTrigger.StartEmission;
begin
  Emit;
end;

procedure TInstantEmissionTrigger.StopEmission;
begin

end;

{ TDistanceEmissionTrigger }

function TDistanceEmissionTrigger.Copy : TParticleEmissionTrigger;
begin
  Result := TDistanceEmissionTrigger.Create(FEmitDistance);
  Result.FEmitter := FEmitter;
end;

constructor TDistanceEmissionTrigger.Create(EmissionDistance : single);
begin
  inherited Create();
  FEmitDistance := EmissionDistance;
end;

procedure TDistanceEmissionTrigger.Idle;
const
  MAX_LOOPS = 50;
var
  s, CurrentEmitDistance : single;
  protectionCounter : integer;
  SpawnPos, realPos : RVector3;
  OriginBase, CurrentBase : RMatrix;
begin
  inherited;
  if not FEmitting then exit;
  CurrentEmitDistance := FEmitDistance * FParentConnector.GetBase.Column[0].Length;
  if CurrentEmitDistance <= 0 then exit;
  OriginBase := FParentConnector.GetBase;
  realPos := OriginBase.Translation;
  s := realPos.Distance(FLastPosition);
  if s = 0 then exit;
  if (FTravelledDistance + s) >= CurrentEmitDistance then
  begin
    // find first emitposition and emit, cannot start iteration here because of offset with travelledDistance from other call
    s := (CurrentEmitDistance - FTravelledDistance) / s;
    SpawnPos := FLastPosition.Lerp(realPos, s);
    CurrentBase := FParentConnector.GetBase;
    CurrentBase.Translation := SpawnPos;
    FParentConnector.SetBase(CurrentBase);
    Emit;
    FLastPosition := SpawnPos;
    FTravelledDistance := FLastPosition.Distance(realPos);
    protectionCounter := 0;
    // emit in equal distances over the line
    while (FTravelledDistance > CurrentEmitDistance) and (protectionCounter < MAX_LOOPS) do
    begin
      s := FLastPosition.Distance(realPos);
      s := CurrentEmitDistance / s;
      SpawnPos := FLastPosition.Lerp(realPos, s);
      CurrentBase := FParentConnector.GetBase;
      CurrentBase.Translation := SpawnPos;
      FParentConnector.SetBase(CurrentBase);
      Emit;
      FLastPosition := SpawnPos;
      FTravelledDistance := FTravelledDistance - CurrentEmitDistance;
      inc(protectionCounter);
    end;
    FLastPosition := realPos;
  end
  else FTravelledDistance := FTravelledDistance + s;
  FParentConnector.SetBase(OriginBase);
end;

constructor TDistanceEmissionTrigger.Create;
begin
  inherited;
  FEmitDistance := 1;
end;

procedure TDistanceEmissionTrigger.StartEmission;
begin
  FEmitting := True;
  FTravelledDistance := 0;
  FLastPosition := FParentConnector.GetBase.Translation;
end;

procedure TDistanceEmissionTrigger.StopEmission;
begin
  FEmitting := False;
end;

constructor TDistanceEmissionTrigger.Create(TriggeredEmitter : TParticleEmitter; EmissionDistance : single);
begin
  inherited Create(TriggeredEmitter);
  FEmitDistance := EmissionDistance;
end;

{ TParticleEmissionTrigger }

constructor TParticleEmissionTrigger.Create(TriggeredEmitter : TParticleEmitter);
begin
  Create;
  FEmitter := TriggeredEmitter;
end;

constructor TParticleEmissionTrigger.Create;
begin
end;

destructor TParticleEmissionTrigger.Destroy;
begin
  if assigned(FParentConnector) then FParentConnector.SetIsAlive(False);
  inherited;
end;

procedure TParticleEmissionTrigger.Emit;
begin
  if assigned(FEmitter) and FParentConnector.IsVisible then
      FEmitter.Emit(FParentConnector.GetBase, FParentConnector);
end;

procedure TParticleEmissionTrigger.Idle;
begin

end;

procedure TParticleEmissionTrigger.SetParentConnector(ParentConnector : IParentConnector);
begin
  FParentConnector := ParentConnector;
end;

initialization

// Delphi optimizes the emitter away, bad for serialization
TInstantEmissionTrigger.ClassParent;
TIntervalEmissionTrigger.ClassParent;
TDistanceEmissionTrigger.ClassParent;

end.

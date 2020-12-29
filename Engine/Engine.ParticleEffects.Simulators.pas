unit Engine.ParticleEffects.Simulators;

interface

uses
  Engine.Core,
  Engine.ParticleEffects.Particles,
  Engine.ParticleEffects.Types,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Physics,
  Engine.Serializer,
  Engine.Serializer.Types,
  Engine.Vertex,
  Xml.XMLIntf,
  Math,
  SysUtils,
  Generics.Collections,
  VCL.Dialogs,
  Engine.Helferlein.VCLUtils;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  TPatternSimulationData = class;

  EnumInterpolationScheme = (isLinear, isLinearTangentFront, isLinearTangentUp, isHermite, isHermiteTangentFront, isHermiteTangentUp);

  ProcAddParticle = reference to procedure(NewParticle : TParticle);

  /// <summary> The meta class for all simulators. A simulator initializes a particle and handle it's movement and live.
  /// Also a simulator understands the given SimulationData of a particle and simulates it on that base. </summary>
  TParticleSimulator = class abstract
    protected
      FParticleCallback : ProcAddParticle;
    public
      Scene : TRenderContext;
      /// <summary> Creates a new simulator. The callback hands over all initialized particles to the particle effect engine. </summary>
      constructor Create(Scene : TRenderContext; ParticleCallback : ProcAddParticle);
      /// <summary> Initializes a particle on base of it's simulation data. The particle has a set origin from it's emitter. </summary>
      procedure InitParticle(SimulationData : TPatternSimulationData; Particle : TParticle); virtual; abstract;
      /// <summary> Simulates a particle. Called once each frame. Must return whether the particle is still alive. </summary>
      function SimulateParticle(Particle : TParticle) : boolean; virtual; abstract;
      /// <summary> Batch-Simulation of many particles. </summary>
      procedure SimulateParticles(Particles : TObjectList<TParticle>); virtual;
  end;

  /// <summary> The meta class for all simulation data. Holds all specific simulator data for a single particle. </summary>
  [XMLExcludeAll]
  TParticleSimulationData = class abstract
    protected
      FSimulator : TParticleSimulator;
    public
      property Simulator : TParticleSimulator read FSimulator;
  end;

  /// <summary> The meta class for all pattern simulation data. Holds all specific data used by the simulator for initializing
  /// particles after spawn. </summary>
  [XMLExcludeAll()]
  TPatternSimulationData = class
    public
      Simulator : TParticleSimulator;
      procedure DrawDebug; virtual;
      class function getCorrespondingSimulator : TClass; virtual; abstract;
  end;

  /// ///////////////////////////////////////////////////////////////////////////
  /// Path-Simulator
  /// ///////////////////////////////////////////////////////////////////////////

  [XMLIncludeAll([XMLIncludeFields])]
  RParticleProperties = record
  [VCLVariedRVector3Field()]
    Rotation : RVariedVector3;
    [VCLRVector3Field(1000, 1000, 1000, isEdit)]
    Front, Up : RVector3;
    [VCLVariedRVector3Field()]
    Size : RVariedVector3;
    // Color.Alpha is the Particle-Alpha
    [VCLVariedRColorField(1, 1, 1, 1, 1, 1, 1, 1)]
    Color : RVariedVector4;
    constructor Create(Rotation : RVariedVector3; Front, Up : RVector3; Size : RVariedVector3; Color : RVariedVector4);
    class function EMPTY : RParticleProperties; static;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  RParticlePathNode = record
  [VCLEditInstance]
    ParticlePattern : RParticleProperties;
    [VCLEnumField]
    InterpolationScheme : EnumInterpolationScheme;
    [VCLVariedRVector3Field()]
    Position, Tangent1, Tangent2 : RVariedVector3;
    [VCLVariedSingleField(10000, 10000, isEdit)]
    PathTime : RVariedSingle;
    constructor CreateLinear(PathTime : RVariedSingle; Position : RVariedVector3; ParticlePattern : RParticleProperties);
    constructor CreateHermite(PathTime : RVariedSingle; Position, Tangent1, Tangent2 : RVariedVector3; ParticlePattern : RParticleProperties);
    class function EMPTY : RParticlePathNode; static;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TParticlePath = class
    protected
      FParticlePathNodes : TList<RParticlePathNode>;
      FBoundingSphereRadius : single;
      function Copy : TParticlePath;
    public
      property BoundingSphereRadius : single read FBoundingSphereRadius;
      [VCLListField([loEditItem, loDeleteItem, loAddItem])]
      property Nodes : TList<RParticlePathNode> read FParticlePathNodes;
      constructor Create; overload;
      constructor Create(PathNodes : array of RParticlePathNode); overload;
      procedure DebugDraw(SelectedNode : integer);
      destructor Destroy; override;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  RParticleData = record
    Position : RVector3;
    Front, Up, Rotation : RVector3;
    Size : RVector3;
    // Color.Alpha is the Particle-Alpha
    Color : RColor;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  RIndividualParticleProperties = record
    Rotation : RVector3;
    Front, Up : RVector3;
    Size : RVector3;
    // Color.Alpha is the Particle-Alpha
    Color : RVector4;
    constructor Create(ParticleProperties : RParticleProperties; RotationDirection : integer);
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  RIndividualParticlePathNode = record
    ParticlePattern : RIndividualParticleProperties;
    InterpolationScheme : EnumInterpolationScheme;
    Position, Tangent1, Tangent2 : RVector3;
    PathTime : single;
    constructor Create(PathNodeProperties : RParticlePathNode; RotationDirection : integer; FixedRandomFactor : single);
    function toParticleData : RParticleData;
    function lerpNodes(b : RIndividualParticlePathNode; s : single) : RParticleData;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TIndividualParticlePath = class
    protected
      FParticlePathNodes : TList<RIndividualParticlePathNode>;
      FParticleTexture : RParticleTexture;
      FTimeSum : single;
      FBase : RMatrix;
      function getCurrentParticleData(ElapsedTime : single) : RParticleData;
    public
      property TimeSum : single read FTimeSum;
      constructor Create(ParticlePath : TParticlePath; Scaling, FixedRandomFactor : single);
      property Base : RMatrix read FBase write FBase;
      destructor Destroy; override;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TPathParticleSimulationData = class(TParticleSimulationData)
    protected
      FElapsedTime, FSpawnTime : single;
      FParticlePath : TIndividualParticlePath;
    public
      constructor Create;
      destructor Destroy; override;
  end;

  /// <summary> Simulator for Pathsimulation. </summary>
  TPathParticleSimulator = class(TParticleSimulator)
    protected
    public
      procedure InitParticle(SimulationData : TPatternSimulationData; Particle : TParticle); override;
      function SimulateParticle(Particle : TParticle) : boolean; override;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TPathPatternSimulationData = class(TPatternSimulationData)
    protected
      FPath : TParticlePath;
    public
      [VCLEditInstance]
      property Path : TParticlePath read FPath write FPath;
      [VCLCallable('Invert Path')]
      procedure InvertPath;
      [VCLCallable('Clone last Node')]
      procedure CloneLastNode;
      [VCLCallable('Recolor All')]
      procedure RecolorAll;
      [VCLCallable('Resize')]
      procedure Resize;
      [VCLCallable('Resample')]
      procedure Resample;
      constructor Create; overload;
      constructor Create(Path : TParticlePath); overload;
      procedure DrawDebug; override;
      destructor Destroy; override;
      class function getCorrespondingSimulator : TClass; override;
  end;

  /// ///////////////////////////////////////////////////////////////////////////
  /// Physical-Simulator
  /// ///////////////////////////////////////////////////////////////////////////

  [XMLIncludeAll([XMLIncludeFields])]
  TPhysicalParticleSimulationData = class(TParticleSimulationData)
    protected
      FMomentum : RVector3;
      FMass : single;
      FAttenuation, FDieMomentum, FDyingMomentum : single;
      FSpawnTime, FLifetime, FDyingTime : int64;
    public
      constructor Create;
  end;

  [XMLIncludeAll([XMLIncludeFields])]
  TPhysicalPatternSimulationData = class(TPatternSimulationData)
    protected
      FInitialMomentum : RVariedSingle;
      FMass : RVariedSingle;
      FAttenuation, FSize : RVariedSingle;
      FLifeDuration, FDyingDuration : RVariedSingle;
      // FDieMomentum, FDyingMomentum : RVariedSingle;
    public
      [VCLVariedSingleField(500, 500, isEdit)]
      property InitialMomentum : RVariedSingle read FInitialMomentum write FInitialMomentum;
      [VCLVariedSingleField(500, 500, isEdit)]
      property InitialMass : RVariedSingle read FMass write FMass;
      [VCLVariedSingleField(500, 500, isEdit)]
      property Attenuation : RVariedSingle read FAttenuation write FAttenuation;
      [VCLVariedSingleField(500, 500, isEdit)]
      property LifeDuration : RVariedSingle read FLifeDuration write FLifeDuration;
      [VCLVariedSingleField(500, 500, isEdit)]
      property DyingDuration : RVariedSingle read FDyingDuration write FDyingDuration;
      [VCLVariedSingleField(500, 500, isEdit)]
      property Size : RVariedSingle read FSize write FSize;
      // [VCLVariedSingleField(500, 500, isEdit)]
      // property DieMomentum : RVariedSingle read FDieMomentum write FDieMomentum;
      // [VCLVariedSingleField(500, 500, isEdit)]
      // property DyingMomentum : RVariedSingle read FDyingMomentum write FDyingMomentum;
      constructor Create; overload;
      constructor Create(InitialMomentum : single); overload;
      class function getCorrespondingSimulator : TClass; override;
  end;

  TPhysicalParticleSimulator = class(TParticleSimulator)
    protected
      FPhysicManager : TPhysicManager;
    public
      constructor Create(Scene : TRenderContext; ParticleCallback : ProcAddParticle; PhysicManager : TPhysicManager);
      procedure InitParticle(SimulationData : TPatternSimulationData; Particle : TParticle); override;
      function SimulateParticle(Particle : TParticle) : boolean; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

{ TPhysicalParticleSimulationData }

constructor TPhysicalParticleSimulationData.Create;
begin
  FMass := 1 + random;
  FAttenuation := 0.97;
end;

{ TPhysicalParticleSimulator }

constructor TPhysicalParticleSimulator.Create(Scene : TRenderContext; ParticleCallback : ProcAddParticle; PhysicManager : TPhysicManager);
begin
  inherited Create(Scene, ParticleCallback);
  FPhysicManager := PhysicManager;
end;

procedure TPhysicalParticleSimulator.InitParticle(SimulationData : TPatternSimulationData; Particle : TParticle);
var
  Data : TPhysicalPatternSimulationData;
  ParticleData : TPhysicalParticleSimulationData;
  Scaling : single;
begin
  Data := SimulationData as TPhysicalPatternSimulationData;
  ParticleData := TPhysicalParticleSimulationData.Create;

  Particle.Position := Particle.Origin * RVector3.ZERO;
  Scaling := Particle.Origin.Column[0].Length;
  ParticleData.FMomentum := ((Particle.Origin * RVector3.UNITZ) - Particle.Position).Normalize * Data.InitialMomentum.random * Scaling;
  ParticleData.FMass := Data.InitialMass.random;
  ParticleData.FAttenuation := Data.Attenuation.random * Scaling;
  // ParticleData.FDieMomentum := Data.DieMomentum.random;
  // ParticleData.FDyingMomentum := ParticleData.FDieMomentum + Data.DyingMomentum.random;
  ParticleData.FSpawnTime := TimeManager.GetTimestamp + Particle.TimeOffset;
  ParticleData.FLifetime := round(Data.LifeDuration.random);
  ParticleData.FDyingTime := round(Data.DyingDuration.random);
  Particle.Scaling := RVector3(Data.FSize.random()) * Scaling;

  ParticleData.FSimulator := self;
  Particle.SimulationData := ParticleData;
  FParticleCallback(Particle);
end;

function TPhysicalParticleSimulator.SimulateParticle(Particle : TParticle) : boolean;
var
  // k1, k2, k3, k4 : RVector3;
  SimulationData : TPhysicalParticleSimulationData;
  LifeFactor{ , MomentumFactor }, TimeDiff, SaveTimeDiff : single;
begin
  // die with emitter
  if Particle.DieWithEmitter and assigned(Particle.EmitterPosition) and not Particle.EmitterPosition.IsAlive then exit(False);
  // Runge-Kutta
  { k1:=FPhysicManager.getForceAtPosition(Particle.FPosition);
   k2:=FPhysicManager.getForceAtPosition(Particle.FPosition+0.5*TTimeManager.ZDiff*k1);
   k3:=FPhysicManager.getForceAtPosition(Particle.FPosition+0.5*TTimeManager.ZDiff*k2);
   k4:=FPhysicManager.getForceAtPosition(Particle.FPosition+TTimeManager.ZDiff*k3);
   Particle.FPosition:=Particle.FPosition+1/6*TTimeManager.ZDiff*(k1+2*k2+2*k3+k4); }

  // Movement
  TimeDiff := TimeManager.ZDiff / 1000.0;
  SaveTimeDiff := Min(0.4, TimeDiff);

  SimulationData := TPhysicalParticleSimulationData(Particle.SimulationData);
  SimulationData.FMomentum := SimulationData.FMomentum + FPhysicManager.getForceAtPosition(Particle.Position) * SaveTimeDiff;

  SimulationData.FMomentum := SimulationData.FMomentum * (power(SimulationData.FAttenuation, SaveTimeDiff));

  Particle.Position := Particle.Position + SimulationData.FMomentum / SimulationData.FMass * TimeDiff;

  FPhysicManager.ApplyObstacles(Particle.Position, SimulationData.FMomentum);

  // Dying

  if SimulationData.FLifetime <= 0 then LifeFactor := 1
  else
  begin
    LifeFactor := SimulationData.FLifetime - (TimeManager.GetTimestamp - SimulationData.FSpawnTime);
    if SimulationData.FDyingTime > 0 then LifeFactor := Min(1, LifeFactor / SimulationData.FDyingTime)
    else LifeFactor := HGeneric.TertOp(LifeFactor <= 0, 0, 1);
  end;
  LifeFactor := Max(0, LifeFactor);

  // MomentumFactor := Max(0, SimulationData.FMomentum.Length - SimulationData.FDieMomentum);
  // if SimulationData.FDyingMomentum > 0 then MomentumFactor := Min(1, MomentumFactor / SimulationData.FDyingMomentum)
  // else MomentumFactor := HGeneric.TertOp(MomentumFactor <= 0, 0, 1);
  // MomentumFactor := Max(0, MomentumFactor);

  Particle.Color.W := LifeFactor; // * MomentumFactor;
  // dies either from lifetime exceeded or from beeing too slow
  Result := (LifeFactor{ * MomentumFactor }) > 0;
end;

{ RIndividualParticleProperties }

constructor RIndividualParticleProperties.Create(ParticleProperties : RParticleProperties; RotationDirection : integer);
begin
  self.Rotation := RotationDirection * (ParticleProperties.Rotation.Mean.Abs + (ParticleProperties.Rotation.Variance * RVector3.random).Abs);
  self.Front := ParticleProperties.Front;
  self.Up := ParticleProperties.Up;
  self.Size := ParticleProperties.Size.getRandomVector;
  self.Color := ParticleProperties.Color.getRandomVector;
end;

{ RIndividualParticlePathNode }

constructor RIndividualParticlePathNode.Create(PathNodeProperties : RParticlePathNode; RotationDirection : integer; FixedRandomFactor : single);
begin
  self.ParticlePattern := RIndividualParticleProperties.Create(PathNodeProperties.ParticlePattern, RotationDirection);
  self.InterpolationScheme := PathNodeProperties.InterpolationScheme;
  self.Position := PathNodeProperties.Position.GetRandomVectorSpecial(FixedRandomFactor);
  self.Tangent1 := PathNodeProperties.Tangent1.GetRandomVectorSpecial(FixedRandomFactor);
  self.Tangent2 := PathNodeProperties.Tangent2.GetRandomVectorSpecial(FixedRandomFactor);
  self.PathTime := PathNodeProperties.PathTime.random(FixedRandomFactor);
end;

function RIndividualParticlePathNode.lerpNodes(b : RIndividualParticlePathNode; s : single) : RParticleData;
begin
  Result.Front := ParticlePattern.Front.Lerp(b.ParticlePattern.Front, s).Normalize;
  Result.Up := ParticlePattern.Up.Lerp(b.ParticlePattern.Up, s).Normalize;
  if InterpolationScheme in [isLinear, isLinearTangentFront, isLinearTangentUp] then
  begin
    Result.Position := Position.Lerp(b.Position, s);
    if InterpolationScheme = isLinearTangentFront then
        Result.Front := Position.DirectionTo(b.Position);
    if InterpolationScheme = isLinearTangentUp then
        Result.Up := Position.DirectionTo(b.Position);
  end
  else
  begin
    Result.Position := RHermiteSpline.Create(Position, b.Position, Tangent1, Tangent2).getPosition(s);
    if InterpolationScheme = isHermiteTangentFront then
        Result.Front := RHermiteSpline.Create(Position, b.Position, Tangent1, Tangent2).getTangent(s);
    if InterpolationScheme = isHermiteTangentUp then
        Result.Up := RHermiteSpline.Create(Position, b.Position, Tangent1, Tangent2).getTangent(s);
  end;
  Result.Rotation := self.ParticlePattern.Rotation.Lerp(b.ParticlePattern.Rotation, s);
  Result.Size := ParticlePattern.Size.Lerp(b.ParticlePattern.Size, s);
  Result.Color := ParticlePattern.Color.Lerp(b.ParticlePattern.Color, s);
end;

function RIndividualParticlePathNode.toParticleData : RParticleData;
begin
  Result.Position := Position;
  Result.Rotation := ParticlePattern.Rotation;
  Result.Front := ParticlePattern.Front;
  Result.Up := ParticlePattern.Up;
  Result.Size := ParticlePattern.Size;
  Result.Color := ParticlePattern.Color;
end;

{ TIndividualParticlePath }

constructor TIndividualParticlePath.Create(ParticlePath : TParticlePath; Scaling, FixedRandomFactor : single);
var
  i : integer;
  RotationDirection : integer;
  Position, LastPosition, LastSizeJitter : RVector3;
  Node : RIndividualParticlePathNode;
begin
  FParticlePathNodes := TList<RIndividualParticlePathNode>.Create;
  FTimeSum := 0;
  RotationDirection := random(2) * 2 - 1;
  for i := 0 to ParticlePath.FParticlePathNodes.Count - 1 do
  begin
    Node := RIndividualParticlePathNode.Create(ParticlePath.FParticlePathNodes[i], RotationDirection, FixedRandomFactor);
    Position := Node.Position;
    if (i > 0) and (Scaling > 0) then
    begin
      Node.Position := (Position - LastPosition) + (FParticlePathNodes[i - 1].Position / Scaling);
      // negative values are special and should not be overwritten or made by computation
      if Node.ParticlePattern.Size.X >= 0 then
          Node.ParticlePattern.Size.X := Max(0, Node.ParticlePattern.Size.X + LastSizeJitter.X);
      if Node.ParticlePattern.Size.Y >= 0 then
          Node.ParticlePattern.Size.Y := Max(0, Node.ParticlePattern.Size.Y + LastSizeJitter.Y);
      if Node.ParticlePattern.Size.Z >= 0 then
          Node.ParticlePattern.Size.Z := Max(0, Node.ParticlePattern.Size.Z + LastSizeJitter.Z);
    end;
    LastPosition := ParticlePath.FParticlePathNodes[i].Position.Mean;
    LastSizeJitter := Node.ParticlePattern.Size - ParticlePath.FParticlePathNodes[i].ParticlePattern.Size.Mean;

    if i <> ParticlePath.FParticlePathNodes.Count - 1 then
        FTimeSum := Node.PathTime + FTimeSum;

    // scaling
    Node.Position := Node.Position * Scaling;
    Node.ParticlePattern.Size := Node.ParticlePattern.Size * Scaling;
    Node.Tangent1 := Node.Tangent1 * Scaling;
    Node.Tangent2 := Node.Tangent2 * Scaling;
    FParticlePathNodes.Add(Node)
  end;
end;

destructor TIndividualParticlePath.Destroy;
begin
  FParticlePathNodes.Free;
end;

function TIndividualParticlePath.getCurrentParticleData(ElapsedTime : single) : RParticleData;
var
  i : integer;
  time, s : single;
  over : boolean;
begin
  assert(FParticlePathNodes.Count <> 0, 'TIndividualParticlePath.getCurrentParticleData: Path has no Nodes!.');
  time := 0;
  over := False;
  if ElapsedTime <= 0 then Result := FParticlePathNodes.First.toParticleData
  else
  begin
    over := True;
    for i := 0 to FParticlePathNodes.Count - 1 do
    begin
      if (time > ElapsedTime) and (FParticlePathNodes[i - 1].PathTime > 0) then
      begin
        s := 1 - HMath.clamp((time - ElapsedTime) / FParticlePathNodes[i - 1].PathTime, 0, 1);
        Result := FParticlePathNodes[i - 1].lerpNodes(FParticlePathNodes[i], s);
        over := False;
        Break;
      end;
      time := time + FParticlePathNodes[i].PathTime;
    end;
  end;
  // clamp to end
  if over then Result := FParticlePathNodes.Last.toParticleData;
  Result.Position := Base * Result.Position;
  Result.Front := (Base.Get3x3 * Result.Front).Normalize;
  Result.Up := (Base.Get3x3 * Result.Up).Normalize;
  Result.Size := RVector3.Create(Base.Column[0].Length, Base.Column[1].Length, Base.Column[2].Length) * Result.Size;
end;

{ RParticlePathNode }

constructor RParticlePathNode.CreateHermite(PathTime : RVariedSingle; Position, Tangent1, Tangent2 : RVariedVector3; ParticlePattern : RParticleProperties);
begin
  self.Tangent1 := Tangent1;
  self.Tangent2 := Tangent2;
  CreateLinear(PathTime, Position, ParticlePattern);
  self.InterpolationScheme := EnumInterpolationScheme.isHermite;
end;

constructor RParticlePathNode.CreateLinear(PathTime : RVariedSingle; Position : RVariedVector3; ParticlePattern : RParticleProperties);
begin
  self.PathTime := PathTime;
  self.Position := Position;
  self.Tangent1 := RVector3.UNITY;
  self.Tangent2 := -RVector3.UNITY;
  self.ParticlePattern := ParticlePattern;
  self.InterpolationScheme := EnumInterpolationScheme.isLinear;
end;

class function RParticlePathNode.EMPTY : RParticlePathNode;
begin
  Result.ParticlePattern := RParticleProperties.EMPTY;
  Result.InterpolationScheme := isLinear;
  Result.Position := RVector3.ZERO;
  Result.Tangent1 := RVector3.UNITY;
  Result.Tangent2 := -RVector3.UNITY;
  Result.PathTime := 1000;
end;

{ RParticleProperties }

constructor RParticleProperties.Create(Rotation : RVariedVector3; Front, Up : RVector3; Size : RVariedVector3; Color : RVariedVector4);
begin
  self.Rotation := Rotation;
  self.Front := Front;
  self.Up := Up;
  self.Size := Size;
  self.Color := Color;
end;

class function RParticleProperties.EMPTY : RParticleProperties;
begin
  Result.Rotation := RVector3.ZERO;
  Result.Front := RVector3.UNITZ;
  Result.Up := RVector3.UNITY;
  Result.Size := RVector3.Create(1);
  Result.Color := RVector4(1);
end;

{ TParticlepfad }

function TParticlePath.Copy : TParticlePath;
var
  Nodes : array of RParticlePathNode;
  i : integer;
begin
  setlength(Nodes, FParticlePathNodes.Count);
  for i := 0 to FParticlePathNodes.Count - 1 do Nodes[i] := FParticlePathNodes[i];
  Result := TParticlePath.Create(Nodes);
end;

constructor TParticlePath.Create;
begin
  FParticlePathNodes := TList<RParticlePathNode>.Create;
end;

constructor TParticlePath.Create(PathNodes : array of RParticlePathNode);
var
  i : integer;
begin
  Create;
  FParticlePathNodes.AddRange(PathNodes);
  for i := 0 to FParticlePathNodes.Count - 1 do
      FBoundingSphereRadius := FBoundingSphereRadius + FParticlePathNodes[i].Position.Mean.Length + FParticlePathNodes[i].Position.Variance.Length +
      FParticlePathNodes[i].ParticlePattern.Size.Mean.Length + FParticlePathNodes[i].ParticlePattern.Size.Variance.Length;
end;

procedure TParticlePath.DebugDraw(SelectedNode : integer);
var
  i : integer;
  procedure AddVariedNode(Position : RVector3; Varied : RVariedVector3);
  begin
    if Varied.RadialVaried then
        LinePool.AddSphere(Position, Varied.Variance.X, RColor.CRED, 16)
    else LinePool.AddBox(Position, (RVector3.UNITX + RVector3.UNITZ).Normalize, (RVector3.UNITX - RVector3.UNITZ).Normalize, Varied.Variance, RColor.CRED, 5);
  end;

begin
  for i := 0 to FParticlePathNodes.Count - 1 do
  begin
    AddVariedNode(FParticlePathNodes[i].Position.Mean, FParticlePathNodes[i].Position);
    if i < FParticlePathNodes.Count - 1 then
    begin
      if FParticlePathNodes[i].InterpolationScheme = isLinear then LinePool.AddLine(FParticlePathNodes[i].Position.Mean, FParticlePathNodes[i + 1].Position.Mean, RColor.CGREEN)
      else LinePool.AddHermite(RHermiteSpline.Create(FParticlePathNodes[i].Position.Mean, FParticlePathNodes[i + 1].Position.Mean, FParticlePathNodes[i].Tangent1.Mean, FParticlePathNodes[i].Tangent2.Mean), RColor.CGREEN, 30);
      if (SelectedNode = i) and (FParticlePathNodes[i].InterpolationScheme = isHermite) then
      begin
        LinePool.AddLine(FParticlePathNodes[i].Position.Mean, FParticlePathNodes[i].Position.Mean + FParticlePathNodes[i].Tangent1.Mean, RColor.CBLUE);
        LinePool.AddLine(FParticlePathNodes[i + 1].Position.Mean, FParticlePathNodes[i + 1].Position.Mean + FParticlePathNodes[i].Tangent2.Mean, RColor.CBLUE);
        AddVariedNode(FParticlePathNodes[i].Position.Mean + FParticlePathNodes[i].Tangent1.Mean, FParticlePathNodes[i].Tangent1);
        AddVariedNode(FParticlePathNodes[i + 1].Position.Mean + FParticlePathNodes[i].Tangent2.Mean, FParticlePathNodes[i].Tangent2);
      end;
    end;
  end;
end;

destructor TParticlePath.Destroy;
begin
  FParticlePathNodes.Free;
end;

{ TPathParticleSimulator }

procedure TPathParticleSimulator.InitParticle(SimulationData : TPatternSimulationData; Particle : TParticle);
var
  Data : TPathPatternSimulationData;
  ParticleData : TPathParticleSimulationData;
begin
  Data := SimulationData as TPathPatternSimulationData;
  ParticleData := TPathParticleSimulationData.Create;
  ParticleData.FSimulator := self;

  ParticleData.FParticlePath := TIndividualParticlePath.Create(Data.Path, 1, Particle.FixedRandomFactor);
  ParticleData.FParticlePath.Base := Particle.Origin;
  ParticleData.FSpawnTime := TimeManager.GetTimestamp + Particle.TimeOffset;
  ParticleData.FElapsedTime := Particle.TimeOffset;

  Particle.SimulationData := ParticleData;
  SimulateParticle(Particle);
  Particle.AfterInitialization;
  FParticleCallback(Particle);
end;

function TPathParticleSimulator.SimulateParticle(Particle : TParticle) : boolean;
var
  SimulationData : TPathParticleSimulationData;
  CurrentParticleData : RParticleData;
  FTempBase : RMatrix;
begin
  // if checked die with emitter
  if Particle.DieWithEmitter and assigned(Particle.EmitterPosition) and not Particle.EmitterPosition.IsAlive then exit(False);

  // proceed in time
  SimulationData := TPathParticleSimulationData(Particle.SimulationData);
  SimulationData.FElapsedTime := Max(0, TimeManager.GetTimestamp - SimulationData.FSpawnTime);
  // die at the end of the path
  if SimulationData.FParticlePath.TimeSum < SimulationData.FElapsedTime then exit(False);

  // Compute particle
  if assigned(Particle.EmitterPosition) then
  begin
    FTempBase := SimulationData.FParticlePath.Base;
    SimulationData.FParticlePath.Base := Particle.EmitterPosition.GetBase * FTempBase;
  end;
  CurrentParticleData := SimulationData.FParticlePath.getCurrentParticleData(SimulationData.FElapsedTime);
  Particle.Position := CurrentParticleData.Position;
  Particle.Rotation := CurrentParticleData.Rotation;
  Particle.Front := CurrentParticleData.Front;
  Particle.Up := CurrentParticleData.Up;
  Particle.Scaling := CurrentParticleData.Size;
  Particle.Color := CurrentParticleData.Color;
  Particle.AfterSimulation;
  if assigned(Particle.EmitterPosition) then
  begin
    SimulationData.FParticlePath.Base := FTempBase;
  end;

  if SimulationData.FSpawnTime + SimulationData.FElapsedTime > TimeManager.GetTimestamp then Particle.Scaling := RVector3.Create(0);

  Result := True;
end;

{ TParticleSimulator }

constructor TParticleSimulator.Create(Scene : TRenderContext; ParticleCallback : ProcAddParticle);
begin
  self.Scene := Scene;
  FParticleCallback := ParticleCallback;
end;

procedure TParticleSimulator.SimulateParticles(Particles : TObjectList<TParticle>);
var
  Particle : TParticle;
begin
  for Particle in Particles do SimulateParticle(Particle);
end;

{ TPathParticleSimulationData }

constructor TPathParticleSimulationData.Create;
begin

end;

destructor TPathParticleSimulationData.Destroy;
begin
  FParticlePath.Free;
  inherited;
end;

{ TPatternSimulationData }

procedure TPatternSimulationData.DrawDebug;
begin

end;

{ TPathPatternSimulationData }

procedure TPathPatternSimulationData.CloneLastNode;
begin
  if FPath.FParticlePathNodes.Count > 0 then
      FPath.FParticlePathNodes.Add(FPath.FParticlePathNodes.Last);
end;

constructor TPathPatternSimulationData.Create(Path : TParticlePath);
begin
  inherited Create;
  FPath := Path;
end;

constructor TPathPatternSimulationData.Create;
begin
  inherited Create;
  FPath := TParticlePath.Create;
end;

destructor TPathPatternSimulationData.Destroy;
begin
  FPath.Free;
  inherited;
end;

procedure TPathPatternSimulationData.DrawDebug;
begin
  inherited;
  FPath.DebugDraw(-1);
end;

class function TPathPatternSimulationData.getCorrespondingSimulator : TClass;
begin
  Result := TPathParticleSimulator;
end;

procedure TPathPatternSimulationData.InvertPath;
var
  i : integer;
  temp : RParticlePathNode;
begin
  self.FPath.FParticlePathNodes.Reverse;
  for i := 0 to FPath.FParticlePathNodes.Count - 2 do
  begin
    temp := FPath.FParticlePathNodes[i];
    temp.PathTime := FPath.FParticlePathNodes[i + 1].PathTime;
    FPath.FParticlePathNodes[i] := temp;
  end;
end;

procedure TPathPatternSimulationData.RecolorAll;
var
  Input : string;
  Color : cardinal;
  code : integer;
  PickedColor : RColor;
  i : integer;
  temp : RParticlePathNode;
begin
  Input := InputBox('Color by Hexcode', 'Please pass the color without alpha as hex code like $808080', '');
  if (Input <> '') then
  begin
    Val(Input, Color, code);
    if code = 0 then
    begin
      PickedColor := RColor.Create(Color);
      for i := 0 to FPath.FParticlePathNodes.Count - 1 do
      begin
        temp := FPath.FParticlePathNodes[i];
        temp.ParticlePattern.Color.Mean := PickedColor.RGBA.SetW(temp.ParticlePattern.Color.Mean.W);
        FPath.FParticlePathNodes[i] := temp;
      end;
    end;
  end;
end;

procedure TPathPatternSimulationData.Resample;
var
  Input : string;
  Scaling : single;
  i : integer;
  temp : RParticlePathNode;
begin
  Input := InputBox('Resample', 'Please pass a time scaling factor:', '').Replace(',', '.');
  if TryStrToFloat(Input, Scaling, EngineFloatFormatSettings) then
  begin
    for i := 0 to FPath.FParticlePathNodes.Count - 1 do
    begin
      temp := FPath.FParticlePathNodes[i];
      temp.PathTime.Mean := temp.PathTime.Mean * Scaling;
      temp.PathTime.Variance := temp.PathTime.Variance * Scaling;
      FPath.FParticlePathNodes[i] := temp;
    end;
  end;
end;

procedure TPathPatternSimulationData.Resize;
var
  Input : string;
  Scaling : single;
  i : integer;
  temp : RParticlePathNode;
begin
  Input := InputBox('Resize', 'Please pass a scaling factor:', '').Replace(',', '.');
  if TryStrToFloat(Input, Scaling, EngineFloatFormatSettings) then
  begin
    for i := 0 to FPath.FParticlePathNodes.Count - 1 do
    begin
      temp := FPath.FParticlePathNodes[i];
      temp.ParticlePattern.Size.Mean := temp.ParticlePattern.Size.Mean * Scaling;
      temp.ParticlePattern.Size.Variance := temp.ParticlePattern.Size.Variance * Scaling;
      temp.Position.Mean := temp.Position.Mean * Scaling;
      temp.Position.Variance := temp.Position.Variance * Scaling;
      temp.Tangent1.Mean := temp.Tangent1.Mean * Scaling;
      temp.Tangent1.Variance := temp.Tangent1.Variance * Scaling;
      temp.Tangent2.Mean := temp.Tangent2.Mean * Scaling;
      temp.Tangent2.Variance := temp.Tangent2.Variance * Scaling;
      FPath.FParticlePathNodes[i] := temp;
    end;
  end;
end;

{ TPhysicalPatternSimulationData }

constructor TPhysicalPatternSimulationData.Create(InitialMomentum : single);
begin
  self.InitialMomentum := InitialMomentum;
end;

constructor TPhysicalPatternSimulationData.Create;
begin
  self.InitialMomentum := 1;
end;

class function TPhysicalPatternSimulationData.getCorrespondingSimulator : TClass;
begin
  Result := TPhysicalParticleSimulator;
end;

end.

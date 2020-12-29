unit Engine.ParticleEffects;

interface

uses
  // Delphi
  System.Rtti,
  System.Classes,
  System.SyncObjs,
  System.Math,
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  // ThirdParty
  Xml.XMLIntf,
  // Engine
  Engine.Helferlein,
  Engine.Helferlein.Threads,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Math.Collision3D,
  Engine.Core,
  Engine.Core.Types,
  Engine.Core.Camera,
  Engine.Log,
  Engine.Serializer.Types,
  Engine.Serializer,
  Engine.Vertex,
  Engine.Physics,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.ParticleEffects.Types,
  Engine.ParticleEffects.Particles,
  Engine.ParticleEffects.Simulators,
  Engine.ParticleEffects.Emitters,
  Engine.Helferlein.VCLUtils;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  {$RTTI EXPLICIT METHODS([vcProtected, vcPublic]) PROPERTIES([vcProtected, vcPublic]) FIELDS([vcProtected, vcPublic])}
  TParticleEffectPattern = class;
  TParticleEffectEngine = class;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  /// <summary> A Particleeffect. This is what you need for incredible effects. If you want to free it, you must free it before the PFXEngine is freed. </summary>
  TParticleEffect = class
    private
      procedure setFront(const Value : RVector3);
      procedure setPosition(const Value : RVector3);
      procedure setUp(const Value : RVector3);
      procedure setSize(const Value : single);
      procedure setVisible(const Value : boolean);
      procedure setBase(const Value : RMatrix4x3);
    protected
      FVisible : boolean;
      FPosition : RVector3;
      FSize : single;
      FFront, FUp : RVector3;
      FTrigger : TObjectList<TParticleEmissionTrigger>;
      FOwner : TParticleEffectEngine;
      FParentConnector : IParentConnector;
      constructor Create(Owner : TParticleEffectEngine);
      /// <summary> Compute changes. </summary>
      procedure Idle;
      procedure LocationChanged; virtual;
      procedure AddTrigger(Trigger : TParticleEmissionTrigger);
      function GetBase : RMatrix;
    public
      /// <summary> Shortcut for setting position, front and up with a base matrix. </summary>
      property Base : RMatrix4x3 write setBase;
      property Visible : boolean read FVisible write setVisible;
      /// <summary> Position of the particleeffect </summary>
      property Position : RVector3 read FPosition write setPosition;
      /// <summary> Orientation of the particleeffect </summary>
      property Front : RVector3 read FFront write setFront;
      /// <summary> Orientation of the particleeffect </summary>
      property Up : RVector3 read FUp write setUp;
      /// <summary> Scaling factor if the particleeffect </summary>
      property Size : single read FSize write setSize;
      procedure Update(const Position, Front, Up : RVector3; Size : single);
      /// <summary> Starts the emission of particles. Instantemitters emits immediately, so you can use one particleeffect for many instant puffs. </summary>
      procedure StartEmission;
      /// <summary> Stops the emission of particles. No new particles will be spawned. </summary>
      procedure StopEmission;
      /// <summary> Must be called before the PFXEngine.Free </summary>
      destructor Destroy; override;
  end;

  RParticleGBuffer = record
    /// <summary> Stores the weighted sum of all Normals (R=X ; G=Y ; B=Z) and the maximum depth of the particlecloud in A. </summary>
    NormalBuffer : TTexture;
    /// <summary> Stores the weighted sum of all Colors and the minimum depth of the particlecloud in A. </summary>
    Colorbuffer : TTexture;
    /// <summary> Stores the the density (sum of alpha) in RG (if Lowres-Rendering then r contains the smaller densitiy
    /// at edges) and the Weightsum in B. A contains if Lowres the extended Depth of all edges.</summary>
    Counterbuffer : TTexture;
    Additionalbuffer : TTexture;
  end;

  TDeferredParticleLighting = class(TDeferredShading)
    private
      FTestMode : string;
    protected
      DirectionalShader : TShader;
      FPFXEngine : TParticleEffectEngine;
      FResolutionDivider : integer;
      procedure Render(RenderContext : TRenderContext); override;
      procedure SetResolutionDivider(Value : integer);
      procedure SetTestMode(Value : string);
      procedure CompileShaders;
    public
      property Testmode : string read FTestMode write SetTestMode;
      property ResolutionDivider : integer read FResolutionDivider write SetResolutionDivider;
      constructor Create(RenderOrder : integer; PFXEngine : TParticleEffectEngine);
      destructor Destroy; override;
  end;

  TParticleEffectEngine = class(TRenderable)
    private type
      TRenderData = class
        Data : TArray<Byte>;
        DataSize : LongWord;
        RenderCount : LongWord;
        Texture : RParticleTexture;
        VertexDeclaration : TVertexDeclaration;
      end;

      TSimulateThread = class(TThread)
        strict private
          FCameraData : RCameraData;
          FParticles : TThreadSafeObjectData<TObjectList<TGeometrieParticle>>;
          FSimulateStarter : TEvent;
          FToBeRendered : TObjectDictionary<RTuple<RParticleTexture, TVertexDeclaration>, TList<TGeometrieParticle>>;
          FRenderCounter : TDictionary<RTuple<RParticleTexture, TVertexDeclaration>, cardinal>;
          FRenderData : TThreadSafeObjectData<TObjectList<TRenderData>>;
        protected
          procedure Execute; override;
        public
          property CameraData : RCameraData read FCameraData write FCameraData;
          property Particles : TThreadSafeObjectData < TObjectList < TGeometrieParticle >> read FParticles;
          property RenderData : TThreadSafeObjectData < TObjectList < TRenderData >> read FRenderData;
          constructor Create;
          procedure StartSimulating;
          destructor Destroy; override;
      end;
    private
      // for rendering
      FClearParticles : boolean;
      ParticleTextureComparer : IComparer<RTuple<RParticleTexture, TVertexDeclaration>>;
      RenderCounter : TDictionary<RTuple<RParticleTexture, TVertexDeclaration>, cardinal>;
    protected
      FTextures : TObjectDictionary<RParticleTexture, TDiffuseNormalTexture>;
      FParticleEffects : TObjectList<TParticleEffect>;

      // all vertexbuffers for the differenz FVFs
      FVertexbuffer : TObjectDictionary<RTuple<RParticleTexture, TVertexDeclaration>, TVertexbufferList>;
      FParticleEffectPatterns : TObjectDictionary<string, TParticleEffectPattern>;
      // all reloaded patterns are stored here to not break up dependencies, in production this should be empty
      FParticleEffectPatternsStorage : TObjectList<TParticleEffectPattern>;
      FDrawnParticles : integer;

      FDeferredEnlighter : TDeferredParticleLighting;
      FGBuffer : RParticleGBuffer;
      FLightBuffer : TTexture;
      FResolutionDivider : integer;
      FDeferredParticleShader, FDeferredParticleToBackbuffer, FShadowShader : TShader;
      FScreenQuad : TScreenQuad;

      FSimulators : TObjectList<TParticleSimulator>;
      FSimulateThread : TSimulateThread;

      FParticles : TObjectList<TParticle>;
      procedure Compute;
      /// <summary> Magic </summary>
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
      procedure RenderShadowContribution(RenderContext : TRenderContext);
      procedure SetResolutionDivider(Value : integer);
      procedure CompileShaders;
      procedure AddParticle(Particle : TParticle);
      procedure AddParticles(Particles : TObjectList<TParticle>);
      procedure AddPattern(Pattern : TParticleEffectPattern; UID : string);
      procedure RemovePattern(UID : string);
      procedure RemoveParticleEffect(Effect : TParticleEffect);
      function GetSimulator(SimulatorType : TClass) : TParticleSimulator;
      procedure OnPatternChange(const FilePath : string);
    public
      UseVFD, Lighting, DeferredShading, Shadows, SafeBackground : boolean;
      Softparticlerange, Depthweightrange, Aliasingrange, Solidness, ScatteringStrength, testvalue : single;
      /// <summary> The root path of all particle effects and textures. </summary>
      AssetPath : string;
      property ResolutionDivider : integer read FResolutionDivider write SetResolutionDivider;
      /// <summary> Creates the engine. </summary>
      constructor Create(Scene : TRenderManager; PhysicManager : TPhysicManager = nil);
      /// <summary> Creates a particle effect from a pattern. Pattern is linked internally, so do not free. </summary>
      function CreateParticleEffectFromPattern(Pattern : TParticleEffectPattern; UID : string = '') : TParticleEffect;
      /// <summary> Creates a particle effects from a file. </summary>
      function CreateParticleEffectFromFile(Dateipfad : string; FailSilently : boolean = False) : TParticleEffect;
      /// <summary> How many particles are drawn in the last frame. </summary>
      property ParticlesRenderedInLastFrame : integer read FDrawnParticles;
      /// <summary> Computes changes. Should be called every frame once. </summary>
      procedure Idle();
      /// <summary> Removes all active particles. </summary>
      procedure ClearParticles;
      /// <summary> Translates a particle texture to a real texture. TODO move this to somewhere more intelligent. </summary>
      function GetTexture(ParticleTexture : RParticleTexture; out NormalMap : TTexture) : TTexture;
      /// <summary> Free me! </summary>
      destructor Destroy; override;

      procedure DeferredParticleToBackbuffer(RenderContext : TRenderContext);
  end;

  {$RTTI EXPLICIT METHODS([vcProtected, vcPublic]) PROPERTIES([vcProtected, vcPublic]) FIELDS([vcProtected, vcPublic])}

  [XMLIncludeAll([XMLIncludeFields])]
  TParticleEffectPattern = class
    protected
      [XMLExcludeElement]
      FUID : string;
      [XMLExcludeElement]
      FOwningEngine : TParticleEffectEngine;
      // Pattern only
      FEmitter : TObjectList<TParticleEmitter>;
      FSimulationData : TObjectList<TPatternSimulationData>;
      // Copied to ParticleEffect
      FTrigger : TObjectList<TParticleEmissionTrigger>;
      /// <summary> Called if consumed with AddFromPattern, frees the structure but leaves dependencies intact. </summary>
      procedure FreeHull;
    public
      [VCLListField([loEditItem, loDeleteItem, loAddItem, loDeleteAllRefrencesToItem])]
      property SimulationData : TObjectList<TPatternSimulationData> read FSimulationData;
      [VCLListField([loEditItem, loDeleteItem, loAddItem, loDeleteAllRefrencesToItem])]
      property Emitter : TObjectList<TParticleEmitter> read FEmitter;
      [VCLListField([loEditItem, loDeleteItem, loAddItem, loDeleteAllRefrencesToItem])]
      property Trigger : TObjectList<TParticleEmissionTrigger> read FTrigger;
      constructor Create(OwningEngine : TParticleEffectEngine; UID : string = ''); overload;
      constructor CreateFromFile(FileName : string; OwningEngine : TParticleEffectEngine); overload;
      function Instantiate(OwningEngine : TParticleEffectEngine) : TParticleEffect;

      procedure AddEmitter(Emitter : TParticleEmitter);
      procedure RemoveEmitter(Emitter : TParticleEmitter);

      procedure AddTrigger(Trigger : TParticleEmissionTrigger);
      procedure RemoveTrigger(Trigger : TParticleEmissionTrigger);

      procedure AddSimulationData(Data : TPatternSimulationData);
      procedure RemoveSimulationData(Data : TPatternSimulationData);

      procedure UpdateSimulatorsInData;

      /// <summary> This consumes and frees the other pattern. </summary>
      procedure AddFromPattern(const AnotherPattern : TParticleEffectPattern);

      procedure SaveToFile(FileName : string);
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  ParticleCountScale : single = 1;
  ParticleEffectEngine : TParticleEffectEngine;

  threadvar
    ParticleCameraData : RCameraData;

implementation


{ TParticleEffectEngine }

procedure TParticleEffectEngine.AddParticle(Particle : TParticle);
begin
  FParticles.Add(Particle);
end;

procedure TParticleEffectEngine.AddParticles(Particles : TObjectList<TParticle>);
begin
  FParticles.AddRange(Particles);
end;

procedure TParticleEffectEngine.AddPattern(Pattern : TParticleEffectPattern; UID : string);
begin
  if ((UID = '') or not FParticleEffectPatterns.ContainsKey(UID)) and not(FParticleEffectPatterns.ContainsValue(Pattern)) then
  begin
    if (UID = '') then UID := Inttostr(FParticleEffectPatterns.Keys.Count);
    FParticleEffectPatterns.Add(UID, Pattern);
  end;
end;

procedure TParticleEffectEngine.RemovePattern(UID : string);
begin
  FParticleEffectPatterns.ExtractPair(UID);
end;

procedure TParticleEffectEngine.ClearParticles;
begin
  FClearParticles := True;
  FParticles.Clear;
end;

procedure TParticleEffectEngine.CompileShaders;
begin
  FDeferredParticleShader.Free;
  FDeferredParticleToBackbuffer.Free;
  FShadowShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleShadowShader.fx'), []);
  if ResolutionDivider <> 1 then
  begin
    FDeferredParticleShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('Particleshader.fx'), ['#define LOWRES']);
    FDeferredParticleToBackbuffer := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleToBackbuffer.fx'), ['#define LOWRES']);
  end
  else
  begin
    FDeferredParticleShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('Particleshader.fx'), []);
    FDeferredParticleToBackbuffer := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleToBackbuffer.fx'), []);
  end;
end;

procedure TParticleEffectEngine.Compute;
var
  tupel : RTuple<RParticleTexture, TVertexDeclaration>;
  vertexbufferList : TVertexbufferList;
  vertexbuffer : TVertexbuffer;
  pVertex : Pointer;
  i : integer;
  alive : boolean;
  ThreadParticles : TObjectList<TGeometrieParticle>;
  ThreadRenderData : TObjectList<TRenderData>;
  RenderDataItem : TRenderData;
begin
  // cleanup
  for tupel in RenderCounter.Keys do
  begin
    RenderCounter[tupel] := 0;
  end;

  // compute active ParticleEffects
  i := 0;
  while i < FParticleEffects.Count do
  begin
    FParticleEffects[i].Idle;
    inc(i);
  end;

  // start filling thread with new particles, lock will ensure that thread is currently not simulating data,
  // so this lock will also synchronize on thread
  ThreadParticles := FSimulateThread.Particles.Lock;
  begin
    // in lock we can clear all remaining particles, if all particles should have been cleared
    if FClearParticles then
    begin
      ThreadParticles.Clear;
      FClearParticles := False;
    end;
    // pass the camera, so it is fix for the computation step
    FSimulateThread.CameraData := Scene.Camera.CameraData;
    begin
      for i := FParticles.Count - 1 downto 0 do
      begin
        // transfer all geometrie particles to thread, only this type of particles supports threadsafe simulating
        if FParticles[i] is TGeometrieParticle then
        begin
          FParticles.OwnsObjects := False;
          ThreadParticles.Add(TGeometrieParticle(FParticles[i]));
          FParticles.Delete(i);
          FParticles.OwnsObjects := True;
        end
        else
        // Simulate all non geometrie particles in mainthread, they are NOT threadsafe
        begin
          alive := TParticleSimulationData(FParticles[i].SimulationData).Simulator.SimulateParticle(FParticles[i]);
          if not alive then
            // kill particle
              FParticles.Delete(i);
        end;
      end;
      FDrawnParticles := FParticles.Count + ThreadParticles.Count;
    end;
  end;
  FSimulateThread.Particles.Unlock;

  // read all computed render data from simulating thread
  ThreadRenderData := FSimulateThread.RenderData.Lock;
  begin
    for RenderDataItem in ThreadRenderData do
    begin
      if RenderDataItem.DataSize > 0 then
      begin
        tupel := RTuple<RParticleTexture, TVertexDeclaration>.Create(RenderDataItem.Texture, RenderDataItem.VertexDeclaration);
        if not FVertexbuffer.TryGetValue(tupel, vertexbufferList) then
        begin
          vertexbufferList := TVertexbufferList.Create([usFrequentlyWriteable], GFXD.Device3D);
          FVertexbuffer.Add(tupel, vertexbufferList);
        end;
        vertexbuffer := vertexbufferList.GetVertexbuffer(RenderDataItem.DataSize);
        pVertex := vertexbuffer.LowLock([lfDiscard]);
        Move(RenderDataItem.Data[0], pVertex^, RenderDataItem.DataSize);
        vertexbuffer.Unlock;
        RenderCounter.AddOrSetValue(tupel, RenderDataItem.RenderCount);
      end;
    end;
  end;
  FSimulateThread.RenderData.Unlock;

  // send signal to simulating thread next simulating round can start
  FSimulateThread.StartSimulating;
end;

constructor TParticleEffectEngine.Create(Scene : TRenderManager; PhysicManager : TPhysicManager);
var
  Comparer : TDelegatedEqualityComparer<RTuple<RParticleTexture, TVertexDeclaration>>;
begin
  FCallbackTime := ctAfter;
  inherited Create(Scene, [rsEffects, rsGlow, rsDistortion]);
  FTextures := TObjectDictionary<RParticleTexture, TDiffuseNormalTexture>.Create([doOwnsValues]);
  FParticles := TObjectList<TParticle>.Create;
  FParticleEffects := TObjectList<TParticleEffect>.Create(True);
  FParticleEffectPatterns := TObjectDictionary<string, TParticleEffectPattern>.Create([doOwnsValues]);
  FParticleEffectPatternsStorage := TObjectList<TParticleEffectPattern>.Create;

  Comparer := TDelegatedEqualityComparer < RTuple < RParticleTexture, TVertexDeclaration >>.Create(
    function(const Left, Right : RTuple<RParticleTexture, TVertexDeclaration>) : boolean
    begin
      Result := (Left.a = Right.a) and (Left.b = Right.b);
    end,
    function(const Value : RTuple<RParticleTexture, TVertexDeclaration>) : integer
    begin
      Result := Value.a.Hash + integer(SetToCardinal(Value.b, SizeOf(Value.b)));
    end);
  FVertexbuffer := TObjectDictionary<RTuple<RParticleTexture, TVertexDeclaration>, TVertexbufferList>.Create([doOwnsValues], Comparer);
  RenderCounter := TDictionary<RTuple<RParticleTexture, TVertexDeclaration>, cardinal>.Create(Comparer);

  SafeBackground := True;
  UseVFD := True;
  Lighting := True;
  DeferredShading := True;
  Softparticlerange := 2;
  Depthweightrange := 6.5;
  ScatteringStrength := 1.0;
  Aliasingrange := 22 / 1000;
  Solidness := 0.5;
  Shadows := False;

  FScreenQuad := TScreenQuad.Create();
  FDeferredEnlighter := TDeferredParticleLighting.Create(0, self);

  FSimulators := TObjectList<TParticleSimulator>.Create;
  FSimulators.Add(TPathParticleSimulator.Create(Scene, self.AddParticle));
  FSimulators.Add(TPhysicalParticleSimulator.Create(Scene, self.AddParticle, PhysicManager));

  FSimulateThread := TSimulateThread.Create;

  ResolutionDivider := 1;

  Scene.Eventbus.Subscribe(geDrawTranslucentShadowmap, RenderShadowContribution);

  ParticleTextureComparer := TComparer < RTuple < RParticleTexture, TVertexDeclaration >>.Construct(
    (
    function(const Left, Right : RTuple<RParticleTexture, TVertexDeclaration>) : integer
    begin
      Result := sign(Left.a.DrawOrder - Right.a.DrawOrder);
    end));
end;

procedure TParticleEffectEngine.DeferredParticleToBackbuffer(RenderContext : TRenderContext);
var
  Shader : TShader;
begin
  Shader := FDeferredParticleToBackbuffer;

  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsMaterial, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable2, tfPoint, amClamp);

  GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1);
  GFXD.Device3D.SetRenderState(rsSRCBLEND, blSRCALPHA);
  GFXD.Device3D.SetRenderState(rsDESTBLEND, blINVSRCALPHA);
  GFXD.Device3D.SetRenderState(rsBLENDOP, boADD);
  GFXD.Device3D.SetRenderState(rsZENABLE, 0);
  Shader.SetTexture(tsColor, FGBuffer.Colorbuffer);
  Shader.SetTexture(tsNormal, FGBuffer.Counterbuffer);
  Shader.SetTexture(tsMaterial, FGBuffer.Additionalbuffer);
  Shader.SetTexture(tsVariable1, FLightBuffer);
  Shader.SetTexture(tsVariable2, RenderContext.GBuffer.NormalBuffer.Texture);
  Shader.SetShaderConstant<single>('pixelwidth', 1 / (GFXD.Settings.Resolution.Width div ResolutionDivider));
  Shader.SetShaderConstant<single>('pixelheight', 1 / (GFXD.Settings.Resolution.Height div ResolutionDivider));
  Shader.SetShaderConstant<single>('width', GFXD.Settings.Resolution.Width div ResolutionDivider);
  Shader.SetShaderConstant<single>('height', GFXD.Settings.Resolution.Height div ResolutionDivider);
  Shader.SetShaderConstant<single>('Softparticlerange', Softparticlerange);
  Shader.SetShaderConstant<single>('Aliasingrange', Aliasingrange);
  Shader.SetShaderConstant<single>('Solidness', Solidness);
  Shader.SetShaderConstant<single>('testvalue', testvalue);
  Shader.ShaderBegin;
  FScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

destructor TParticleEffectEngine.Destroy;
begin
  FSimulateThread.Free;
  FShadowShader.Free;
  FSimulators.Free;
  FGBuffer.NormalBuffer.Free;
  FGBuffer.Colorbuffer.Free;
  FGBuffer.Counterbuffer.Free;
  FDeferredParticleShader.Free;
  FDeferredParticleToBackbuffer.Free;
  FDeferredEnlighter.Free;
  FScreenQuad.Free;
  FTextures.Free;
  FParticles.Free;
  FParticleEffects.Free;
  FParticleEffectPatterns.Free;
  FParticleEffectPatternsStorage.Free;
  FVertexbuffer.Free;
  RenderCounter.Free;
  inherited;
end;

function TParticleEffectEngine.GetSimulator(SimulatorType : TClass) : TParticleSimulator;
var
  Simulator : TParticleSimulator;
begin
  Result := nil;
  for Simulator in FSimulators do
  begin
    if Simulator.ClassType = SimulatorType then exit(Simulator);
  end;
end;

function TParticleEffectEngine.GetTexture(ParticleTexture : RParticleTexture; out NormalMap : TTexture) : TTexture;
var
  temp : TDiffuseNormalTexture;
begin
  if not FTextures.TryGetValue(ParticleTexture, temp) then
  begin
    temp := TDiffuseNormalTexture.Create;
    temp.Diffuse := TTexture.CreateTextureFromFile(HFilepathManager.RelativeToAbsolute(AssetPath + '\' + ParticleTexture.TextureFileName), GFXD.Device3D);
    if not assigned(temp.Diffuse) then
    begin
      temp.Diffuse := TTexture.CreateTexture(64, 64, 0, [usWriteable], tfA8R8G8B8, GFXD.Device3D);
      temp.Diffuse.Fill<cardinal>(RColor.CWHITE.AsCardinal);
    end;
    temp.Normal := nil;
    if ParticleTexture.NormalMapFileName <> '' then
    begin
      temp.Normal := TTexture.CreateTextureFromFile(HFilepathManager.RelativeToAbsolute(AssetPath + '\' + ParticleTexture.NormalMapFileName), GFXD.Device3D);
      if not assigned(temp.Normal) then
      begin
        temp.Normal := TTexture.CreateTexture(64, 64, 0, [usWriteable], tfA8R8G8B8, GFXD.Device3D);
        temp.Normal.Fill<cardinal>(RColor.CDEFAULTNORMAL.AsCardinal);
      end;
    end;
    FTextures.Add(ParticleTexture, temp);
  end;
  Result := temp.Diffuse;
  NormalMap := temp.Normal;
end;

function TParticleEffectEngine.CreateParticleEffectFromFile(Dateipfad : string; FailSilently : boolean) : TParticleEffect;
var
  Pattern : TParticleEffectPattern;
begin
  Dateipfad := AbsolutePath(Dateipfad).ToLowerInvariant;
  if not FileExists(Dateipfad) then
  begin
    HLog.Log('TParticleEffectEngine.CreateParticleEffectFromFile: Pattern ' + Dateipfad + ' does not exist!');
    Result := nil;
    if not FailSilently then
        raise EFileNotFoundException.Create('TParticleEffectEngine.CreateParticleEffectFromFile: Patternfile ''' + Dateipfad + ''' does not exist!');
    exit;
  end;
  ContentManager.SubscribeToFile(Dateipfad, OnPatternChange, True);
  if not FParticleEffectPatterns.TryGetValue(Dateipfad, Pattern) then
      Pattern := TParticleEffectPattern.CreateFromFile(Dateipfad, self);
  Result := CreateParticleEffectFromPattern(Pattern, Dateipfad);
end;

function TParticleEffectEngine.CreateParticleEffectFromPattern(Pattern : TParticleEffectPattern; UID : string = '') : TParticleEffect;
begin
  Result := Pattern.Instantiate(self);
  FParticleEffects.Add(Result);
end;

procedure TParticleEffectEngine.Idle();
begin
  Compute;
end;

procedure TParticleEffectEngine.OnPatternChange(const FilePath : string);
var
  Pattern : TParticleEffectPattern;
  UnifiedFilePath : string;
begin
  UnifiedFilePath := FilePath.ToLowerInvariant;
  // if pattern changes on disk, we remove it from cache to be reloaded on next usaged
  if FParticleEffectPatterns.TryGetValue(UnifiedFilePath, Pattern) then
  begin
    FParticleEffectPatternsStorage.Add(Pattern);
    FParticleEffectPatterns.ExtractPair(UnifiedFilePath);
  end;
end;

procedure TParticleEffectEngine.RemoveParticleEffect(Effect : TParticleEffect);
begin
  FParticleEffects.Extract(Effect);
end;

procedure TParticleEffectEngine.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
var
  Shader : TShader;
  FVFSize : integer;
  vertexbufferList : TVertexbufferList;
  tupel : RTuple<RParticleTexture, TVertexDeclaration>;
  tupelList : TArray<RTuple<RParticleTexture, TVertexDeclaration>>;
  Texture, NormalMap : TTexture;
  ShaderStack : TArray<string>;
  IsSoftparticle : boolean;
  i : integer;
  BlendMode : EnumParticleBlendMode;
  ShaderFlags : SetDefaultShaderFlags;
  OnlyView : RMatrix;
  CurrentBlendModes : TArray<EnumParticleBlendMode>;
begin
  if FDrawnParticles <= 0 then exit;

  tupelList := RenderCounter.Keys.ToArray;
  TArray.Sort < RTuple < RParticleTexture, TVertexDeclaration >> (tupelList, ParticleTextureComparer);

  GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfAuto, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);

  case Stage of
    rsEffects : CurrentBlendModes := [pbSubtractive, pbAdditive, pbLinear, pbShaded];
    rsGlow : CurrentBlendModes := [pbGlow];
    rsDistortion : CurrentBlendModes := [pbDistortion];
  else
    raise EInvalidOperation.Create('TParticleEffectEngine.Render: ParticleEffectEngine rendered in wrong stage!');
  end;

  // Render all Particles
  for i := 0 to Length(CurrentBlendModes) - 1 do
  begin
    BlendMode := CurrentBlendModes[i];
    // initialize Deferred Particles
    if DeferredShading and (BlendMode = pbShaded) then
    begin
      GFXD.Device3D.PushRenderTargets([FGBuffer.NormalBuffer.asRendertarget, FGBuffer.Colorbuffer.asRendertarget, FGBuffer.Counterbuffer.asRendertarget, FGBuffer.Additionalbuffer.asRendertarget]);
      // clear Textures
      GFXD.Device3D.Clear([cfTarget], 0, 1, 0);
    end;
    for tupel in tupelList do
      if tupel.a.BlendMode = BlendMode then
        if RenderCounter[tupel] > 0 then
        begin
          FVFSize := tupel.b.VertexSize;
          // fetch appropiate vertexbuffer
          if not FVertexbuffer.TryGetValue(tupel, vertexbufferList) then continue;

          if tupel.a.IgnoreZ then GFXD.Device3D.SetRenderState(rsZENABLE, False)
          else GFXD.Device3D.SetRenderState(rsZENABLE, True);

          GFXD.Device3D.SetRenderState(rsZWRITEENABLE, 0);
          GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1);
          Texture := GetTexture(tupel.a, NormalMap);
          if DeferredShading and (tupel.a.BlendMode = pbShaded) then
          begin
            // needed Renderstates
            GFXD.Device3D.SetRenderState(rsCULLMODE, cmNONE);
            GFXD.Device3D.SetRenderState(rsSRCBLEND, blONE);
            GFXD.Device3D.SetRenderState(rsDESTBLEND, blONE);
            GFXD.Device3D.SetRenderState(rsBLENDOP, boADD);
            GFXD.Device3D.SetRenderState(rsSEPARATEALPHABLENDENABLE, 1);
            GFXD.Device3D.SetRenderState(rsSRCBLENDALPHA, blONE);
            GFXD.Device3D.SetRenderState(rsDESTBLENDALPHA, blONE);
            GFXD.Device3D.SetRenderState(rsBLENDOPALPHA, boMAX);

            Shader := FDeferredParticleShader;
            Shader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
            Shader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
            OnlyView := RenderContext.Camera.View;
            OnlyView.Translation := RVector3.Zero;
            Shader.SetShaderConstant<RMatrix>('InvView', RenderContext.Camera.View.Inverse);
            Shader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
            Shader.SetShaderConstant<single>('viewportwidth', RenderContext.Size.Width div ResolutionDivider);
            Shader.SetShaderConstant<single>('viewportheight', RenderContext.Size.Height div ResolutionDivider);
            Shader.SetShaderConstant<single>('Softparticlerange', Softparticlerange);
            Shader.SetShaderConstant<single>('Depthweightrange', Depthweightrange);
          end
          else
          begin
            ShaderFlags := [sfVertexcolor];
            if Texture <> nil then ShaderFlags := ShaderFlags + [sfDiffuseTexture];
            GFXD.Device3D.SetRenderState(rsCULLMODE, cmNONE);
            // build shader stack
            ShaderStack := ['ForwardParticleShader.fx'];
            IsSoftparticle := (rrGBuffer in RenderContext.AvailableRequirements) and
              tupel.a.Softparticle and
              (Softparticlerange > 0) and
              not tupel.a.IgnoreZ;

            if IsSoftparticle then
            begin
              ShaderStack := ['ForwardSoftParticleShader.fx'] + ShaderStack;
              if not SafeBackground then ShaderStack := ['ForwardSoftParticleWithoutBackgroundShader.fx'] + ShaderStack;
            end;

            if tupel.a.AlphaSubtraction then ShaderStack := ShaderStack + ['ForwardParticleShaderAlphaSubtraction.fx'];

            Shader := RenderContext.CreateAndSetDefaultShader(ShaderFlags, ShaderStack);

            // set constants
            if IsSoftparticle then Shader.SetShaderConstant<single>('Softparticlerange', Softparticlerange);

            Shader.SetShaderConstant<single>('viewportwidth', RenderContext.Size.Width);
            Shader.SetShaderConstant<single>('viewportheight', RenderContext.Size.Height);
            if (rrGBuffer in RenderContext.AvailableRequirements) then
                Shader.SetTexture(tsVariable1, RenderContext.GBuffer.NormalBuffer.Texture);

            Shader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
            if Lighting and (NormalMap <> nil) then
            begin
              Shader.SetShaderConstant<RVector3>(dcCameraUp, -RenderContext.Camera.ScreenUp);
              Shader.SetShaderConstant<RVector3>(dcCameraLeft, -RenderContext.Camera.ScreenLeft);
              Shader.SetShaderConstant<RVector3>(dcCameraDirection, -RenderContext.Camera.CameraDirection);
            end;

            case tupel.a.BlendMode of
              pbAdditive :
                begin
                  GFXD.Device3D.SetRenderState(rsSRCBLEND, blSRCALPHA);
                  GFXD.Device3D.SetRenderState(rsDESTBLEND, blONE);
                  GFXD.Device3D.SetRenderState(rsBLENDOP, boADD);
                end;
              pbLinear, pbGlow, pbDistortion, pbShaded :
                begin
                  GFXD.Device3D.SetRenderState(rsSRCBLEND, blSRCALPHA);
                  GFXD.Device3D.SetRenderState(rsDESTBLEND, blINVSRCALPHA);
                  GFXD.Device3D.SetRenderState(rsBLENDOP, boADD);
                end;
              pbSubtractive :
                begin
                  GFXD.Device3D.SetRenderState(rsSRCBLEND, blSRCALPHA);
                  GFXD.Device3D.SetRenderState(rsDESTBLEND, blONE);
                  GFXD.Device3D.SetRenderState(rsBLENDOP, boREVSUBTRACT);
                end;
            end;
          end;
          // render vertexbuffer
          Shader.SetWorld(RMatrix.IDENTITY);
          if Texture <> nil then Shader.SetTexture(tsColor, Texture);
          if DeferredShading and (BlendMode = pbShaded) then Shader.SetTexture(tsVariable1, RenderContext.GBuffer.NormalBuffer.Texture);
          GFXD.Device3D.SetVertexDeclaration(tupel.b);
          GFXD.Device3D.SetStreamSource(0, vertexbufferList.CurrentVertexbuffer, 0, FVFSize);
          Shader.ShaderBegin;
          GFXD.Device3D.DrawPrimitive(ptTriangleList, 0, ((RenderCounter[tupel] div 3)));
          Shader.ShaderEnd;

          GFXD.Device3D.ClearRenderState();
        end;
    if DeferredShading and (BlendMode = pbShaded) then
    begin
      // recover old surface
      GFXD.Device3D.PopRenderTargets;

      // render Lights
      FDeferredEnlighter.Render(RenderContext);

      DeferredParticleToBackbuffer(RenderContext);
    end;
  end;
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TParticleEffectEngine.RenderShadowContribution(RenderContext : TRenderContext);
var
  Shader : TShader;
  FVFSize : integer;
  vertexbufferList : TVertexbufferList;
  tupel : RTuple<RParticleTexture, TVertexDeclaration>;
  tupelList : TArray<RTuple<RParticleTexture, TVertexDeclaration>>;
  Texture, NormalMap : TTexture;
  OnlyView : RMatrix;
begin
  if not Shadows or (RenderContext.MainDirectionalLight = nil) then exit;
  tupelList := RenderCounter.Keys.ToArray;
  GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amWrap);
  GFXD.Device3D.SetSamplerState(tsNormal, tfAuto, amWrap);
  for tupel in tupelList do
    if (tupel.a.BlendMode = pbShaded) and (RenderCounter[tupel] > 0) then
    begin
      FVFSize := tupel.b.VertexSize;
      // fetch appropiate vertexbuffer
      if not FVertexbuffer.TryGetValue(tupel, vertexbufferList) then continue;
      GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1);
      Texture := GetTexture(tupel.a, NormalMap);

      // needed Renderstates
      Shader := FShadowShader;
      Shader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
      Shader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
      OnlyView := RenderContext.Camera.View;
      OnlyView.Translation := RVector3.Zero;
      Shader.SetShaderConstant<RMatrix>('OnlyView', OnlyView);
      Shader.SetShaderConstant<RMatrix>('InvView', RenderContext.Camera.View.Inverse);
      Shader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
      Shader.SetShaderConstant<RVector3>(dcCameraDirection, RenderContext.MainDirectionalLight.Direction);
      Shader.SetShaderConstant<RVector3>(dcCameraUp, RenderContext.Camera.ScreenUp);
      Shader.SetShaderConstant<single>('viewportwidth', RenderContext.Size.Width div ResolutionDivider);
      Shader.SetShaderConstant<single>('viewportheight', RenderContext.Size.Height div ResolutionDivider);
      // render vertexbuffer

      Shader.SetWorld(RMatrix.IDENTITY);
      Shader.SetTexture(tsColor, Texture);
      Shader.SetTexture(tsNormal, NormalMap);
      GFXD.Device3D.SetVertexDeclaration(tupel.b);
      GFXD.Device3D.SetStreamSource(0, vertexbufferList.CurrentVertexbuffer, 0, FVFSize);
      Shader.ShaderBegin;
      GFXD.Device3D.DrawPrimitive(ptTriangleList, 0, ((RenderCounter[tupel] div 3)));
      Shader.ShaderEnd;

      GFXD.Device3D.ClearRenderState();
    end;
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TParticleEffectEngine.SetResolutionDivider(Value : integer);
var
  Format : EnumTextureFormat;
begin
  FResolutionDivider := Value;
  FDeferredEnlighter.ResolutionDivider := Value;
  FGBuffer.NormalBuffer.Free;
  FGBuffer.Colorbuffer.Free;
  FGBuffer.Counterbuffer.Free;
  FGBuffer.Additionalbuffer.Free;
  FLightBuffer.Free;
  Format := tfA32B32G32R32F;
  FGBuffer.NormalBuffer := TTexture.CreateTexture(GFXD.Settings.Resolution.Width div ResolutionDivider, GFXD.Settings.Resolution.Height div ResolutionDivider, 1, [usRendertarget], Format, GFXD.Device3D);
  FGBuffer.Colorbuffer := TTexture.CreateTexture(GFXD.Settings.Resolution.Width div ResolutionDivider, GFXD.Settings.Resolution.Height div ResolutionDivider, 1, [usRendertarget], Format, GFXD.Device3D);
  FGBuffer.Counterbuffer := TTexture.CreateTexture(GFXD.Settings.Resolution.Width div ResolutionDivider, GFXD.Settings.Resolution.Height div ResolutionDivider, 1, [usRendertarget], Format, GFXD.Device3D);
  FGBuffer.Additionalbuffer := TTexture.CreateTexture(GFXD.Settings.Resolution.Width div ResolutionDivider, GFXD.Settings.Resolution.Height div ResolutionDivider, 1, [usRendertarget], Format, GFXD.Device3D);
  FLightBuffer := TTexture.CreateTexture(GFXD.Settings.Resolution.Width div ResolutionDivider, GFXD.Settings.Resolution.Height div ResolutionDivider, 1, [usRendertarget], tfA16B16G16R16F, GFXD.Device3D);
  CompileShaders;
end;

{ TParticleEffect }

procedure TParticleEffect.AddTrigger(Trigger : TParticleEmissionTrigger);
begin
  FTrigger.Add(Trigger);
  Trigger.SetParentConnector(FParentConnector);
end;

constructor TParticleEffect.Create(Owner : TParticleEffectEngine);
begin
  FSize := 1;
  FTrigger := TObjectList<TParticleEmissionTrigger>.Create;
  FFront := RVector3.UNITZ;
  FUp := RVector3.UNITY;
  FOwner := Owner;
  FVisible := True;
  FParentConnector := TParentConnector.Create;
  LocationChanged;
end;

destructor TParticleEffect.Destroy;
begin
  StopEmission;
  FTrigger.Free;
  FOwner.RemoveParticleEffect(self);
end;

function TParticleEffect.GetBase : RMatrix;
begin
  Result := RMatrix.CreateTranslation(Position) * RMatrix.CreateSaveBase(FFront, FUp) * RMatrix.CreateScaling(FSize);
end;

procedure TParticleEffect.Idle;
var
  i : integer;
begin
  for i := 0 to FTrigger.Count - 1 do FTrigger[i].Idle;
end;

procedure TParticleEffect.LocationChanged;
var
  Base : RMatrix;
begin
  Base := GetBase;
  FParentConnector.setBase(Base);
end;

procedure TParticleEffect.setBase(const Value : RMatrix4x3);
begin
  Update(Value.Translation, Value.Front, Value.Up, FSize);
end;

procedure TParticleEffect.setFront(const Value : RVector3);
begin
  FFront := Value;
  LocationChanged;
end;

procedure TParticleEffect.setPosition(const Value : RVector3);
begin
  FPosition := Value;
  LocationChanged;
end;

procedure TParticleEffect.setSize(const Value : single);
begin
  FSize := Value;
  LocationChanged;
end;

procedure TParticleEffect.setUp(const Value : RVector3);
begin
  FUp := Value;
  LocationChanged;
end;

procedure TParticleEffect.setVisible(const Value : boolean);
begin
  FVisible := Value;
  FParentConnector.setVisible(FVisible);
end;

procedure TParticleEffect.StartEmission;
var
  i : integer;
begin
  for i := 0 to FTrigger.Count - 1 do FTrigger[i].StartEmission;
end;

procedure TParticleEffect.StopEmission;
var
  i : integer;
begin
  for i := 0 to FTrigger.Count - 1 do FTrigger[i].StopEmission;
end;

procedure TParticleEffect.Update(const Position, Front, Up : RVector3; Size : single);
begin
  FPosition := Position;
  FFront := Front;
  FUp := Up;
  FSize := Size;
  LocationChanged;
end;

{ TParticleEffectPattern }

procedure TParticleEffectPattern.AddEmitter(Emitter : TParticleEmitter);
begin
  FEmitter.Add(Emitter);
end;

procedure TParticleEffectPattern.AddFromPattern(const AnotherPattern : TParticleEffectPattern);
var
  i : integer;
begin
  for i := 0 to AnotherPattern.SimulationData.Count - 1 do
      AddSimulationData(AnotherPattern.SimulationData[i]);
  for i := 0 to AnotherPattern.Emitter.Count - 1 do
      AddEmitter(AnotherPattern.Emitter[i]);
  for i := 0 to AnotherPattern.Trigger.Count - 1 do
      AddTrigger(AnotherPattern.Trigger[i]);
  AnotherPattern.FreeHull;
end;

procedure TParticleEffectPattern.AddSimulationData(Data : TPatternSimulationData);
begin
  FSimulationData.Add(Data);
  Data.Simulator := FOwningEngine.GetSimulator(Data.getCorrespondingSimulator);
end;

procedure TParticleEffectPattern.AddTrigger(Trigger : TParticleEmissionTrigger);
begin
  FTrigger.Add(Trigger);
end;

constructor TParticleEffectPattern.Create(OwningEngine : TParticleEffectEngine; UID : string);
begin
  FUID := UID;
  FOwningEngine := OwningEngine;
  FOwningEngine.AddPattern(self, UID);
  FEmitter := TObjectList<TParticleEmitter>.Create;
  FSimulationData := TObjectList<TPatternSimulationData>.Create;
  FTrigger := TObjectList<TParticleEmissionTrigger>.Create;
end;

constructor TParticleEffectPattern.CreateFromFile(FileName : string; OwningEngine : TParticleEffectEngine);
var
  Path : TString;
begin
  Create(OwningEngine, FileName);
  Path := TString.Create(ExtractFilePath(FileName));
  TXMLSerializer.CacheXMLDocuments := False;
  HXMLSerializer.LoadObjectFromFile(self, FileName, [Path]);
  TXMLSerializer.CacheXMLDocuments := True;
  Path.Free;
  UpdateSimulatorsInData;
end;

destructor TParticleEffectPattern.Destroy;
begin
  FEmitter.Free;
  FSimulationData.Free;
  FTrigger.Free;
end;

procedure TParticleEffectPattern.FreeHull;
begin
  FEmitter.OwnsObjects := False;
  FSimulationData.OwnsObjects := False;
  FTrigger.OwnsObjects := False;
  FOwningEngine.RemovePattern(FUID);
  Free;
end;

function TParticleEffectPattern.Instantiate(OwningEngine : TParticleEffectEngine) : TParticleEffect;
var
  Trigger : TParticleEmissionTrigger;
begin
  Result := TParticleEffect.Create(OwningEngine);
  for Trigger in FTrigger do
  begin
    Result.AddTrigger(Trigger.Copy);
  end;
end;

procedure TParticleEffectPattern.RemoveEmitter(Emitter : TParticleEmitter);
var
  Trigger : TParticleEmissionTrigger;
begin
  FEmitter.Remove(Emitter);
  for Trigger in FTrigger do
    if Trigger.Emitter = Emitter then Trigger.Emitter := nil;
end;

procedure TParticleEffectPattern.RemoveSimulationData(Data : TPatternSimulationData);
var
  Emitter : TParticleEmitter;
begin
  for Emitter in FEmitter do
    if Emitter.SimulationData = Data then Emitter.SimulationData := nil;
  FSimulationData.Remove(Data);
end;

procedure TParticleEffectPattern.RemoveTrigger(Trigger : TParticleEmissionTrigger);
begin
  FTrigger.Remove(Trigger);
end;

procedure TParticleEffectPattern.SaveToFile(FileName : string);
begin
  HXMLSerializer.SaveObjectToFile(self, FileName);
end;

procedure TParticleEffectPattern.UpdateSimulatorsInData;
var
  i : integer;
begin
  for i := 0 to FSimulationData.Count - 1 do
      FSimulationData[i].Simulator := FOwningEngine.GetSimulator(FSimulationData[i].getCorrespondingSimulator);
end;

{ TDeferredParticleLighting }

procedure TDeferredParticleLighting.CompileShaders;
begin
  DirectionalShader.Free;
  Pointshader.Free;
  Spotshader.Free;
  if ResolutionDivider <> 1 then
  begin
    DirectionalShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleDeferredDirectionalAmbientLight.fx'), ['#define LOWRES']);
    Pointshader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleDeferredPointLight.fx'), ['#define LOWRES']);
    Spotshader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleDeferredSpotLight.fx'), ['#define LOWRES']);
  end
  else
  begin
    DirectionalShader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleDeferredDirectionalAmbientLight.fx'), []);
    Pointshader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleDeferredPointLight.fx'), []);
    Spotshader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, ('ParticleDeferredSpotLight.fx'), []);
  end;
end;

constructor TDeferredParticleLighting.Create(RenderOrder : integer; PFXEngine : TParticleEffectEngine);
begin
  inherited Create;
  FPFXEngine := PFXEngine;
  FreeAndNil(Shader);
  FreeAndNil(Pointshader);
  FreeAndNil(Spotshader);
  FreeAndNil(LBSpotshader);
  FreeAndNil(LBShader);
  FreeAndNil(LBPointshader);
end;

destructor TDeferredParticleLighting.Destroy;
begin
  DirectionalShader.Free;
  inherited;
end;

procedure TDeferredParticleLighting.Render(RenderContext : TRenderContext);
var
  OnlyView : RMatrix;
  Shader : TShader;
  Dir : RVector3;
  Color : RVector4;
begin
  GFXD.Device3D.SetSamplerState(tsColor, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable2, tfPoint, amClamp);

  GFXD.Device3D.PushRenderTargets([RenderContext.Lightbuffer.asRendertarget]);
  GFXD.Device3D.Clear([cfTarget], 0, 1, 0);
  Shader := RenderContext.SetShader(DirectionalShader);
  Shader.SetTexture(tsColor, FPFXEngine.FGBuffer.NormalBuffer);
  Shader.SetTexture(tsNormal, FPFXEngine.FGBuffer.Colorbuffer);
  Shader.SetTexture(tsVariable1, FPFXEngine.FGBuffer.Counterbuffer);
  Shader.SetShaderConstant<RMatrix>(dcWorld, RMatrix.IDENTITY);
  Shader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
  Shader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
  OnlyView := RenderContext.Camera.View;
  OnlyView.Translation := RVector3.Zero;
  if RenderContext.MainDirectionalLight <> nil then
  begin
    Dir := RenderContext.MainDirectionalLight.Direction.Normalize;
    if RenderContext.MainDirectionalLight.Enabled then Color := RenderContext.MainDirectionalLight.Color
    else Color := RenderContext.MainDirectionalLight.Color.SetAlphaF(0);
  end
  else
  begin
    Dir := RVector3.Zero;
    Color := RVector4.Zero;
  end;
  Shader.SetShaderConstant<RVector3>(dcDirectionalLightDir, (OnlyView * (Dir)).Normalize * RVector3.Create(-1, 1, 1));
  Shader.SetShaderConstant<RVector3>('DirectionalLightDirWorld', Dir);
  Shader.SetShaderConstant<RVector4>(dcDirectionalLightColor, Color);
  Shader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
  Shader.SetShaderConstant<single>('pixelwidth', 1 / (RenderContext.Size.Width div FPFXEngine.ResolutionDivider));
  Shader.SetShaderConstant<single>('pixelheight', 1 / (RenderContext.Size.Height div FPFXEngine.ResolutionDivider));
  GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 0);
  GFXD.Device3D.SetRenderState(rsZENABLE, 0);
  Shader.SetShaderConstant<RVector3>(dcAmbient, RenderContext.Ambient.PremultiplyAlpha.RGB);
  Shader.SetShaderConstant<RVector3>('CornerLT', RenderContext.Camera.Clickvector(RVector2.Create(0, 0)).Direction);
  Shader.SetShaderConstant<RVector3>('CornerRT', RenderContext.Camera.Clickvector(RVector2.Create(1, 0)).Direction);
  Shader.SetShaderConstant<RVector3>('CornerLB', RenderContext.Camera.Clickvector(RVector2.Create(0, 1)).Direction);
  Shader.SetShaderConstant<RVector3>('CornerRB', RenderContext.Camera.Clickvector(RVector2.Create(1, 1)).Direction);
  Shader.SetShaderConstant<single>('ScatteringStrength', FPFXEngine.ScatteringStrength);
  Shader.SetShaderConstant<single>('testvalue', FPFXEngine.testvalue);
  Shader.ShaderBegin;
  ScreenQuad.Render;
  Shader.ShaderEnd;
  GFXD.Device3D.ClearRenderState();

  SetUpVertexbuffer(RenderContext);

  if pointvertices.Count > 0 then
  begin
    Shader := RenderContext.SetShader(Pointshader);
    Shader.SetTexture(tsColor, FPFXEngine.FGBuffer.NormalBuffer);
    Shader.SetTexture(tsNormal, FPFXEngine.FGBuffer.Colorbuffer);
    Shader.SetTexture(tsVariable1, FPFXEngine.FGBuffer.Counterbuffer);
    Shader.SetTexture(tsVariable2, FPFXEngine.FGBuffer.Additionalbuffer);
    Shader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
    Shader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
    Shader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
    OnlyView.Row[1] := -OnlyView.Row[1];
    OnlyView.Row[2] := -OnlyView.Row[2];
    Shader.SetShaderConstant<RMatrix>('OnlyView', OnlyView);
    Shader.SetShaderConstant<RVector3>(dcAmbient, RVector3.Zero);
    Shader.SetShaderConstant<single>('width', 1.0 / RenderContext.Size.Width / 2.0);
    Shader.SetShaderConstant<single>('height', 1.0 / RenderContext.Size.Height / 2.0);
    Shader.SetShaderConstant<RVector3>('CornerLT', RenderContext.Camera.Clickvector(RVector2.Create(0, 0)).Direction);
    Shader.SetShaderConstant<RVector3>('CornerRT', RenderContext.Camera.Clickvector(RVector2.Create(1, 0)).Direction);
    Shader.SetShaderConstant<RVector3>('CornerLB', RenderContext.Camera.Clickvector(RVector2.Create(0, 1)).Direction);
    Shader.SetShaderConstant<RVector3>('CornerRB', RenderContext.Camera.Clickvector(RVector2.Create(1, 1)).Direction);
    Shader.SetShaderConstant<single>('ScatteringStrength', FPFXEngine.ScatteringStrength);
    Shader.SetShaderConstant<single>('testvalue', FPFXEngine.testvalue);
    GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(rsSRCBLEND, blONE);
    GFXD.Device3D.SetRenderState(rsDESTBLEND, blONE);
    GFXD.Device3D.SetRenderState(rsBLENDOP, boADD);
    GFXD.Device3D.SetRenderState(rsZENABLE, 0);
    GFXD.Device3D.SetRenderState(rsCULLMODE, cmNONE);
    Shader.ShaderBegin;
    GFXD.Device3D.SetVertexDeclaration(pointvertexdeclaration);
    GFXD.Device3D.SetStreamSource(0, pointvertexbuffer.CurrentVertexbuffer, 0, SizeOf(RPointlightVertex));
    GFXD.Device3D.DrawPrimitive(ptTriangleList, 0, pointvertices.Count div 3);
    Shader.ShaderEnd;
    GFXD.Device3D.ClearRenderState();
  end;

  if spotvertices.Count > 0 then
  begin
    Shader := RenderContext.SetShader(Spotshader);
    Shader.SetTexture(tsColor, FPFXEngine.FGBuffer.NormalBuffer);
    Shader.SetTexture(tsNormal, FPFXEngine.FGBuffer.Colorbuffer);
    Shader.SetTexture(tsVariable1, FPFXEngine.FGBuffer.Counterbuffer);
    Shader.SetTexture(tsVariable2, FPFXEngine.FGBuffer.Additionalbuffer);
    Shader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);
    Shader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
    Shader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
    OnlyView.Row[1] := -OnlyView.Row[1];
    OnlyView.Row[2] := -OnlyView.Row[2];
    Shader.SetShaderConstant<RMatrix>('OnlyView', OnlyView);
    Shader.SetShaderConstant<RVector3>(dcAmbient, RVector3.Zero);
    Shader.SetShaderConstant<single>('width', 1.0 / RenderContext.Size.Width / 2.0);
    Shader.SetShaderConstant<single>('height', 1.0 / RenderContext.Size.Height / 2.0);
    Shader.SetShaderConstant<RVector3>('CornerLT', RenderContext.Camera.Clickvector(RVector2.Create(0, 0)).Direction);
    Shader.SetShaderConstant<RVector3>('CornerRT', RenderContext.Camera.Clickvector(RVector2.Create(1, 0)).Direction);
    Shader.SetShaderConstant<RVector3>('CornerLB', RenderContext.Camera.Clickvector(RVector2.Create(0, 1)).Direction);
    Shader.SetShaderConstant<RVector3>('CornerRB', RenderContext.Camera.Clickvector(RVector2.Create(1, 1)).Direction);
    Shader.SetShaderConstant<single>('ScatteringStrength', FPFXEngine.ScatteringStrength);
    Shader.SetShaderConstant<single>('testvalue', FPFXEngine.testvalue);
    GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(rsSRCBLEND, blONE);
    GFXD.Device3D.SetRenderState(rsDESTBLEND, blONE);
    GFXD.Device3D.SetRenderState(rsBLENDOP, boADD);
    GFXD.Device3D.SetRenderState(rsZENABLE, 0);
    GFXD.Device3D.SetRenderState(rsCULLMODE, cmCW);
    Shader.ShaderBegin;
    GFXD.Device3D.SetVertexDeclaration(spotvertexdeclaration);
    GFXD.Device3D.SetStreamSource(0, spotvertexbuffer.CurrentVertexbuffer, 0, SizeOf(RSpotlightVertex));
    GFXD.Device3D.DrawPrimitive(ptTriangleList, 0, spotvertices.Count div 3);
    Shader.ShaderEnd;
    GFXD.Device3D.ClearRenderState();
  end;

  GFXD.Device3D.PopRenderTargets;
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TDeferredParticleLighting.SetResolutionDivider(Value : integer);
begin
  FResolutionDivider := Value;
  ScreenQuad.Free;
  ScreenQuad := TScreenQuad.Create(ResolutionDivider);
  CompileShaders;
end;

procedure TDeferredParticleLighting.SetTestMode(Value : string);
begin
  if Value = '' then FTestMode := ''
  else FTestMode := '#define ' + AnsiUpperCase(Value);
  CompileShaders;
end;

{ TParticleEffectEngine.TSimulateThread }

constructor TParticleEffectEngine.TSimulateThread.Create;
var
  UID : TGuid;
  Comparer : TDelegatedEqualityComparer<RTuple<RParticleTexture, TVertexDeclaration>>;
begin
  CreateGuid(UID);
  FParticles := TThreadSafeObjectData < TObjectList < TGeometrieParticle >>.Create(TObjectList<TGeometrieParticle>.Create());
  FRenderData := TThreadSafeObjectData < TObjectList < TRenderData >>.Create(TObjectList<TRenderData>.Create());
  FSimulateStarter := TEvent.Create(nil, True, False, GuidToString(UID));
  Comparer := TDelegatedEqualityComparer < RTuple < RParticleTexture, TVertexDeclaration >>.Create(
    function(const Left, Right : RTuple<RParticleTexture, TVertexDeclaration>) : boolean
    begin
      Result := (Left.a = Right.a) and (Left.b = Right.b);
    end,
    function(const Value : RTuple<RParticleTexture, TVertexDeclaration>) : integer
    begin
      Result := Value.a.Hash + integer(SetToCardinal(Value.b, SizeOf(Value.b)));
    end);
  FToBeRendered := TObjectDictionary < RTuple<RParticleTexture, TVertexDeclaration>, TList < TGeometrieParticle >>.Create([doOwnsValues], Comparer);
  FRenderCounter := TDictionary<RTuple<RParticleTexture, TVertexDeclaration>, cardinal>.Create(Comparer);
  inherited Create;
end;

destructor TParticleEffectEngine.TSimulateThread.Destroy;
begin
  FRenderCounter.Free;
  FToBeRendered.Free;
  FRenderData.Free;
  FParticles.Free;
  FSimulateStarter.Free;
  inherited;
end;

procedure TParticleEffectEngine.TSimulateThread.Execute;
var
  FVFSize : cardinal;
  Particle : TGeometrieParticle;
  ParticleList : TList<TGeometrieParticle>;
  tupel : RTuple<RParticleTexture, TVertexDeclaration>;
  pVertex : Pointer;
  i : integer;
  alive : boolean;
  Particles : TObjectList<TGeometrieParticle>;
  waitResult : TWaitResult;
  RenderDataItem : TRenderData;
  RenderData : TObjectList<TRenderData>;
begin
  while not Terminated do
  begin
    try
      waitResult := FSimulateStarter.WaitFor(100);
      if waitResult = TWaitResult.wrSignaled then
      begin
        FSimulateStarter.ResetEvent;
        Particles := self.Particles.Lock;
        begin
          // Clear Renderdictionary
          for ParticleList in FToBeRendered.Values do
            if ParticleList <> nil then ParticleList.Clear;
          for tupel in FRenderCounter.Keys do
          begin
            FRenderCounter[tupel] := 0;
          end;

          // Build Renderdictionary and simulate particles
          for i := Particles.Count - 1 downto 0 do
          begin
            Particle := Particles[i];
            // Simulate
            alive := TParticleSimulationData(Particle.SimulationData).Simulator.SimulateParticle(Particle);
            if not alive then
            begin
              // kill particle
              Particles.Delete(i);
              continue;
            end;

            // skip invisible particles
            if not Particle.IsVisible then continue;

            // get the TextureFVFList, create if not existing
            if not FToBeRendered.TryGetValue(RTuple<RParticleTexture, TVertexDeclaration>.Create(Particle.GetTexture, Particle.GetVertexFormat), ParticleList) then
            begin
              ParticleList := TList<TGeometrieParticle>.Create;
              FToBeRendered.Add(RTuple<RParticleTexture, TVertexDeclaration>.Create(Particle.GetTexture, Particle.GetVertexFormat), ParticleList);
            end;
            ParticleList.Add(Particle);
            tupel.a := Particle.GetTexture;
            tupel.b := Particle.GetVertexFormat;
            if not FRenderCounter.ContainsKey(tupel) then FRenderCounter.Add(tupel, 0);
            FRenderCounter[tupel] := FRenderCounter[tupel] + Particle.GetVertexCount;
          end;

          RenderData := FRenderData.Lock;
          begin
            ParticleCameraData := CameraData;
            RenderData.Clear;
            // compute geometry of all active particles and store them in their vertexbuffers
            for tupel in FToBeRendered.Keys do
              if FToBeRendered[tupel].Count > 0 then
              begin
                FVFSize := tupel.b.VertexSize;
                RenderDataItem := TRenderData.Create;
                RenderDataItem.RenderCount := FRenderCounter[tupel];
                RenderDataItem.Texture := tupel.a;
                RenderDataItem.VertexDeclaration := tupel.b;
                RenderDataItem.DataSize := RenderDataItem.RenderCount * FVFSize;
                setLength(RenderDataItem.Data, RenderDataItem.DataSize);
                pVertex := @RenderDataItem.Data[0];
                for Particle in FToBeRendered[tupel] do
                    Particle.WriteToBuffer(pVertex);
                RenderData.Add(RenderDataItem);
              end;
          end;
          FRenderData.Unlock;
        end;
        self.Particles.Unlock;
      end;
    except
      // mute exception
    end;
  end;
end;

procedure TParticleEffectEngine.TSimulateThread.StartSimulating;
begin
  FSimulateStarter.SetEvent;
end;

end.

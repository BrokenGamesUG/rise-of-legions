unit Engine.Water;

interface

uses
  SysUtils,
  Windows,
  Types,
  Generics.Collections,
  Engine.Core,
  Engine.Core.Types,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Core.Camera,
  Engine.Vertex,
  Engine.Serializer,
  Engine.Serializer.Types;

type

  {$RTTI EXPLICIT METHODS([vcProtected]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  [XMLIncludeAll([XMLIncludeProperties])]
  TWaterSurface = class(TRenderable)
    protected
      FDirty : boolean;
      FReflections : boolean;
      FPosition : RVector3;
      FSize : RVector2;
      FGeometryResolution : integer;
      FVertexbuffer : TVertexbuffer;
      FIndexbuffer : TIndexbuffer;
      FWatershader : TShader;
      FWave, FSky, FCaustics : TTexture;
      FRefraction, FShaderDeferredShading : boolean;
      procedure setRefraction(const Value : boolean);
      constructor Create; overload;
      constructor Create(Scene : TRenderManager); overload;
      procedure GenerateGeometry;
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
      procedure SetGeometryResolution(const Value : integer);
      procedure setSize(const Value : RVector2);
      procedure LoadWaveTexture(filename : string);
      function getWaveTexturePath() : string;
      function getCausticsTexturePath : string;
      function getSkyTexturePath : string;
      procedure SetDirty;
      procedure CleanDirty;
      procedure LoadCausticsTexture(const Value : string);
      procedure LoadSkyTexture(const Value : string);
      procedure CompileShader;
      procedure setReflections(const Value : boolean);
    public
      [XMLIncludeElement]
      WaveHeight, Roughness, Size, FresnelOffset, Transparency, DepthTransparencyRange, RefractionIndex, RefractionStepLength, RefractionSteps, ColorExtinctionRange, CausticsRange : single;
      [XMLIncludeElement]
      Exposure, Specularpower, Specularintensity, CausticsScale : single;
      /// <summary> Color of the water and the reflected color of the sky. </summary>
      [XMLIncludeElement]
      WaterColor, SkyColor, FallbackWaterColor : RColor;
      /// <summary> Use reflections. (Environment out of water reflects on the surface) </summary>
      property Reflections : boolean read FReflections write setReflections;
      /// <summary> Use refractions. (Environment beneath the water is correctly distorted) </summary>
      property Refraction : boolean read FRefraction write setRefraction;
      /// <summary> The center of this water surface. </summary>
      property Position : RVector3 read FPosition write FPosition;
      /// <summary> The world size of the surface in X and Z direction. </summary>
      property GeometrySize : RVector2 read FSize write setSize;
      /// <summary> How many gridnodes per axis are used for the surface. </summary>
      property GeometryResolution : integer read FGeometryResolution write SetGeometryResolution;
      /// <summary> The wave texture RGBA => (Normal.xzy, Height) </summary>
      property WaveTexture : string read getWaveTexturePath write LoadWaveTexture;
      /// <summary> A reflected spherical environment map. Replaces SkyColor. </summary>
      property SkyTexture : string read getSkyTexturePath write LoadSkyTexture;
      /// <summary> Underwater caustics in the alpha channel. </summary>
      property CausticsTexture : string read getCausticsTexturePath write LoadCausticsTexture;
      /// <summary> Creates a default water surface. </summary>
      constructor CreateEmpty(Scene : TRenderManager);
      function Requirements : SetRenderRequirements; override;
      destructor Destroy; override;
  end;

  /// <summary> Offers management, save and load functionality for a bunch of watersurfaces. </summary>
  [XMLExcludeAll]
  TWaterManager = class
    public
      const
      FILEEXTENSION = '.wat';
    private
      function getSurface(index : integer) : TWaterSurface;
      procedure SetVisible(const Value : boolean);
    protected
      [XMLIncludeElement]
      FWaterSurfaces : TObjectList<TWaterSurface>;
    public
      /// <summary> Draws the geometry wireframed. </summary>
      DrawWireFramed : boolean;
      property Visible : boolean write SetVisible;
      /// <summary> All registered Surfaces. </summary>
      property Surfaces[index : integer] : TWaterSurface read getSurface;
      /// <summary>  </summary>
      constructor Create();
      /// <summary> Loads watersurfaces from a waterfile. </summary>
      constructor CreateFromFile(WaterFile : string);
      /// <summary> Add a surface to be managed. </summary>
      procedure AddSurface(Surface : TWaterSurface);
      /// <summary> Removes and frees a surface from the watermanager </summary>
      procedure RemoveSurface(Surface : TWaterSurface);
      /// <summary> Returns the managed surface count. </summary>
      function SurfaceCount : integer;
      /// <summary> Loads watersurfaces from a waterfile. </summary>
      procedure LoadFromFile(filename : string);
      /// <summary> Should be called once a frame for rendering. </summary>
      procedure Idle;
      /// <summary> Saves all registered watersurfaces to a file. </summary>
      procedure SaveToFile(filename : string);
      /// <summary> Skeddush </summary>
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  SafeBackground : boolean = False;

implementation


{ TWaterSurface }

constructor TWaterSurface.Create;
begin
  Create(GFXD.MainScene);
end;

constructor TWaterSurface.CreateEmpty(Scene : TRenderManager);
begin
  Create(Scene);
end;

procedure TWaterSurface.CleanDirty;
begin
  if FDirty then CompileShader;
end;

procedure TWaterSurface.CompileShader;
var
  defines : TArray<string>;
begin
  FWatershader.Free;
  defines := TArray<string>.Create();
  if assigned(FSky) then HGeneric.ArrayAppend<string>(defines, '#define SKY_REFLECTION');
  if assigned(FCaustics) then HGeneric.ArrayAppend<string>(defines, '#define CAUSTICS');
  if not SafeBackground then HGeneric.ArrayAppend<string>(defines, '#define SCENE_MAY_CONTAIN_BACKBUFFER');
  if FReflections then HGeneric.ArrayAppend<string>(defines, '#define REFLECTIONS');
  if FRefraction then HGeneric.ArrayAppend<string>(defines, '#define REFRACTION');
  if GFXD.Settings.DeferredShading then HGeneric.ArrayAppend<string>(defines, '#define DEFERRED_SHADING');
  FShaderDeferredShading := GFXD.Settings.DeferredShading;
  FWatershader := TShader.CreateShaderFromResourceOrFile(GFXD.Device3D, 'Watershader.fx', defines);
  FDirty := False;
end;

constructor TWaterSurface.Create(Scene : TRenderManager);
begin
  FCallbackTime := ctBefore;
  inherited Create(Scene, [rsEffects]);
  FGeometryResolution := 200;
  WaterColor := $0C1940;
  SkyColor := $345971;
  Exposure := 0.35;
  WaveHeight := 1.2;
  Roughness := 0.68;
  Specularpower := 40;
  Specularintensity := 0.8;
  Size := 90;
  Transparency := 0.0;
  DepthTransparencyRange := 1.5;
  FSize := RVector2.Create(50, 50);
  RefractionIndex := 1 / 1.333; // Air => Water
  RefractionStepLength := 10;
  RefractionSteps := 14;
  FresnelOffset := 0.2;
  ColorExtinctionRange := 150;
  CausticsRange := 15;
  CausticsScale := 1;
  GenerateGeometry;
  SetDirty;
  WaveTexture := ''; // create dummy texture
  Reflections := True;
  Refraction := True;
end;

destructor TWaterSurface.Destroy;
begin
  FWave.Free;
  FCaustics.Free;
  FSky.Free;
  FWatershader.Free;
  FVertexbuffer.Free;
  FIndexbuffer.Free;
  inherited;
end;

procedure TWaterSurface.GenerateGeometry;
var
  x, z, topLeft, topRight, bottomLeft, bottomRight, index : integer;
  Vertex : RVertexPositionTexture;
begin
  // create vertex-grid
  FVertexbuffer.Free;
  FVertexbuffer := TVertexbuffer.CreateVertexBuffer(sqr(FGeometryResolution) * SizeOf(RVertexPositionTexture), [usWriteable], GFXD.Device3D);
  FVertexbuffer.Lock();
  for z := 0 to FGeometryResolution - 1 do
    for x := 0 to FGeometryResolution - 1 do
    begin
      Vertex.Position.x := x / (FGeometryResolution - 1) - 0.5;
      Vertex.Position.Y := 0;
      Vertex.Position.z := z / (FGeometryResolution - 1) - 0.5;
      Vertex.TextureCoordinate.x := x / (FGeometryResolution - 1);
      Vertex.TextureCoordinate.Y := z / (FGeometryResolution - 1);
      FVertexbuffer.setElement<RVertexPositionTexture>(z * FGeometryResolution + x, Vertex);
    end;
  FVertexbuffer.Unlock;
  // create indices
  FIndexbuffer.Free;
  FIndexbuffer := TIndexbuffer.CreateIndexBuffer(sqr(FGeometryResolution) * 6 * SizeOf(integer), [usWriteable], ifINDEX32, GFXD.Device3D);
  FIndexbuffer.Lock;
  index := 0;
  for z := 0 to FGeometryResolution - 2 do
    for x := 0 to FGeometryResolution - 2 do
    begin
      topLeft := z * FGeometryResolution + x;
      topRight := topLeft + 1;
      bottomLeft := topLeft + FGeometryResolution;
      bottomRight := bottomLeft + 1;

      FIndexbuffer.setElement<integer>(index + 0, topLeft);
      FIndexbuffer.setElement<integer>(index + 1, bottomLeft);
      FIndexbuffer.setElement<integer>(index + 2, bottomRight);
      FIndexbuffer.setElement<integer>(index + 3, bottomRight);
      FIndexbuffer.setElement<integer>(index + 4, topRight);
      FIndexbuffer.setElement<integer>(index + 5, topLeft);

      index := index + 6;
    end;
  FIndexbuffer.Unlock;
end;

function TWaterSurface.getCausticsTexturePath : string;
begin
  if assigned(FCaustics) then Result := RelativDateiPfad(FCaustics.filename)
  else Result := '';
end;

function TWaterSurface.getSkyTexturePath : string;
begin
  if assigned(FSky) then Result := RelativDateiPfad(FSky.filename)
  else Result := '';
end;

function TWaterSurface.getWaveTexturePath : string;
begin
  if assigned(FWave) then Result := RelativDateiPfad(FWave.filename)
  else Result := '';
end;

procedure TWaterSurface.LoadCausticsTexture(const Value : string);
begin
  FreeAndNil(FCaustics);
  if Value <> '' then FCaustics := TTexture.CreateTextureFromFile(FormatDateiPfad(Value), GFXD.Device3D, mhGenerate, True);
  SetDirty;
end;

procedure TWaterSurface.LoadSkyTexture(const Value : string);
begin
  FreeAndNil(FSky);
  if Value <> '' then FSky := TTexture.CreateTextureFromFile(FormatDateiPfad(Value), GFXD.Device3D, mhGenerate, True);
  SetDirty;
end;

procedure TWaterSurface.LoadWaveTexture(filename : string);
begin
  FreeAndNil(FWave);
  if filename <> '' then FWave := TTexture.CreateTextureFromFile(FormatDateiPfad(filename), GFXD.Device3D, mhGenerate, True);
  if not assigned(FWave) then
  begin
    FWave := TTexture.CreateTexture(32, 32, 1, [usWriteable], tfA8R8G8B8, GFXD.Device3D);
    FWave.Fill<Cardinal>(RColor.CDEFAULTNORMAL.AsCardinal);
  end;
end;

procedure TWaterSurface.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
var
  World : RMatrix;
begin
  inherited;
  RenderContext.SwitchScene(True);
  if FShaderDeferredShading <> GFXD.Settings.DeferredShading then CompileShader;
  assert(assigned(FWatershader));

  GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amWrap);
  GFXD.Device3D.SetSamplerState(tsNormal, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsMaterial, tfLinear, amWrap);
  GFXD.Device3D.SetSamplerState(tsVariable1, tfPoint, amClamp);
  GFXD.Device3D.SetSamplerState(tsVariable2, tfAuto, amWrap);
  GFXD.Device3D.SetSamplerState(tsVariable3, tfAuto, amWrap);
  GFXD.Device3D.SetSamplerState(tsVariable4, tfPoint, amClamp);

  GFXD.Device3D.SetStreamSource(0, FVertexbuffer, 0, SizeOf(RVertexPositionTexture));
  GFXD.Device3D.SetIndices(FIndexbuffer);
  GFXD.Device3D.SetVertexDeclaration(RVertexPositionTexture.BuildVertexdeclaration());

  if (Transparency < 1.0) or not GFXD.Settings.DeferredShading then
  begin
    GFXD.Device3D.SetRenderState(rsALPHABLENDENABLE, True);
    GFXD.Device3D.SetRenderState(rsSRCBLEND, EnumBlend.blSrcAlpha);
    GFXD.Device3D.SetRenderState(rsDESTBLEND, EnumBlend.blInvSrcAlpha);
    GFXD.Device3D.SetRenderState(rsBLENDOP, EnumBlendOp.boAdd);
  end;

  RenderContext.SetShader(FWatershader);

  World := RMatrix.CreateTranslation(FPosition) * RMatrix.CreateScaling(FSize.X0Y);
  FWatershader.SetWorld(World);
  FWatershader.SetShaderConstant<RMatrix>(dcView, RenderContext.Camera.View);
  FWatershader.SetShaderConstant<RMatrix>(dcProjection, RenderContext.Camera.Projection);
  FWatershader.SetShaderConstant<RVector3>(dcCameraPosition, RenderContext.Camera.Position);

  if RenderContext.MainDirectionalLight <> nil then
  begin
    FWatershader.SetShaderConstant<RVector3>(dcDirectionalLightDir, -RenderContext.MainDirectionalLight.Direction);
    FWatershader.SetShaderConstant<RVector4>(dcDirectionalLightColor, RenderContext.MainDirectionalLight.Color);
  end
  else
  begin
    FWatershader.SetShaderConstant<RVector3>(dcDirectionalLightDir, RVector3.ZERO);
    FWatershader.SetShaderConstant<RVector4>(dcDirectionalLightColor, RVector4.ZERO);
  end;

  if GFXD.Settings.DeferredShading then
  begin
    FWatershader.SetShaderConstant<RVector3>('WaterColor', WaterColor.RGB);
    FWatershader.SetShaderConstant<single>('Transparency', Transparency);
  end
  else
  begin
    FWatershader.SetShaderConstant<RVector3>('WaterColor', FallbackWaterColor.RGB);
    FWatershader.SetShaderConstant<single>('Transparency', FallbackWaterColor.A);
  end;
  FWatershader.SetShaderConstant<RVector3>('SkyColor', SkyColor.RGB);
  FWatershader.SetShaderConstant<single>('Exposure', Exposure);
  FWatershader.SetShaderConstant<single>('WaveHeight', 1 / WaveHeight);
  FWatershader.SetShaderConstant<single>('Roughness', Roughness);
  FWatershader.SetShaderConstant<single>(dcSpecularpower, Specularpower);
  FWatershader.SetShaderConstant<single>(dcSpecularintensity, Specularintensity);
  FWatershader.SetShaderConstant<single>('Size', Size);
  FWatershader.SetShaderConstant<single>('FresnelOffset', FresnelOffset);
  FWatershader.SetShaderConstant<single>('TimeTick', TimeManager.GetFloatingTimestamp / 1000);
  FWatershader.SetShaderConstant<single>('WaveTexelsize', 1 / FWave.Width);
  FWatershader.SetShaderConstant<single>('WaveTexelworldsize', 1 / FWave.Width * 2000 / Size);
  FWatershader.SetShaderConstant<RVector2>('TextureNormalization', FSize / 2000);

  FWatershader.SetShaderConstant<single>('DepthTransparencyRange', DepthTransparencyRange);
  FWatershader.SetShaderConstant<single>('RefractionIndex', RefractionIndex);
  FWatershader.SetShaderConstant<single>('RefractionStepLength', RefractionStepLength);
  FWatershader.SetShaderConstant<single>('RefractionSteps', RefractionSteps);
  FWatershader.SetShaderConstant<single>('ColorExtinctionRange', ColorExtinctionRange);
  FWatershader.SetShaderConstant<single>('CausticsRange', CausticsRange);
  FWatershader.SetShaderConstant<single>('CausticsScale', CausticsScale);

  FWatershader.SetShaderConstant<RVector4>('MinMax', RVector4.Create(Position.XZ - (GeometrySize / 2), Position.XZ + (GeometrySize / 2)));

  FWatershader.SetShaderConstant<single>('SizeVS', Size);
  FWatershader.SetShaderConstant<single>('TimeTickVS', TimeManager.GetFloatingTimestamp / 1000);
  FWatershader.SetShaderConstant<single>('WaveHeightVS', WaveHeight);
  FWatershader.SetShaderConstant<RVector2>('TextureNormalizationVS', FSize / 2000);

  // for VS
  FWatershader.SetTexture(tsMaterial, FWave, stVertexShader);

  FWatershader.SetTexture(tsColor, FWave);
  FWatershader.SetTexture(tsVariable3, FCaustics);
  FWatershader.SetTexture(tsVariable2, FSky);

  FWatershader.SetTexture(tsNormal, RenderContext.Scene);
  if GFXD.Settings.DeferredShading then
  begin
    FWatershader.SetTexture(tsVariable1, RenderContext.GBuffer.PositionBuffer.Texture);
    FWatershader.SetTexture(tsVariable4, RenderContext.GBuffer.Normalbuffer.Texture);
  end;

  FWatershader.ShaderBegin;

  FDrawCalls := 1;
  FDrawnTriangles := sqr(FGeometryResolution) * 2;
  GFXD.Device3D.DrawIndexedPrimitive(EnumPrimitveType.ptTrianglelist, 0, 0, sqr(FGeometryResolution), 0, sqr(FGeometryResolution) * 2);

  FWatershader.ShaderEnd;

  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

function TWaterSurface.Requirements : SetRenderRequirements;
begin
  Result := [rrScene];
end;

procedure TWaterSurface.SetDirty;
begin
  FDirty := True;
end;

procedure TWaterSurface.SetGeometryResolution(const Value : integer);
begin
  FGeometryResolution := Value;
  GenerateGeometry;
end;

procedure TWaterSurface.setReflections(const Value : boolean);
begin
  FReflections := Value;
  SetDirty;
end;

procedure TWaterSurface.setRefraction(const Value : boolean);
begin
  FRefraction := Value;
  SetDirty;
end;

procedure TWaterSurface.setSize(const Value : RVector2);
begin
  FSize := Value;
end;

{ TWaterManager }

procedure TWaterManager.AddSurface(Surface : TWaterSurface);
begin
  FWaterSurfaces.Add(Surface);
end;

constructor TWaterManager.Create();
begin
  FWaterSurfaces := TObjectList<TWaterSurface>.Create();
end;

constructor TWaterManager.CreateFromFile(WaterFile : string);
begin
  Create();
  LoadFromFile(WaterFile);
end;

destructor TWaterManager.Destroy;
begin
  FWaterSurfaces.Free;
  inherited;
end;

function TWaterManager.getSurface(index : integer) : TWaterSurface;
begin
  assert((index >= 0) and (index < FWaterSurfaces.Count), 'Invalid WaterSurface-Index!');
  Result := FWaterSurfaces.Items[index];
end;

procedure TWaterManager.Idle;
var
  i : integer;
begin
  for i := 0 to FWaterSurfaces.Count - 1 do
  begin
    FWaterSurfaces[i].CleanDirty;
  end;
end;

procedure TWaterManager.LoadFromFile(filename : string);
var
  i : integer;
begin
  if not FileExists(filename) then raise Exception.Create('TWaterManager.LoadFromFile: Waterfile ' + filename + ' does not exist!');
  FWaterSurfaces.Clear;
  HXMLSerializer.LoadObjectFromFile(self, filename, [GFXD]);
  for i := 0 to FWaterSurfaces.Count - 1 do FWaterSurfaces[i].CleanDirty;
end;

procedure TWaterManager.RemoveSurface(Surface : TWaterSurface);
begin
  FWaterSurfaces.Remove(Surface);
end;

procedure TWaterManager.SaveToFile(filename : string);
begin
  HXMLSerializer.SaveObjectToFile(self, filename);
end;

procedure TWaterManager.SetVisible(const Value : boolean);
var
  i : integer;
begin
  for i := 0 to FWaterSurfaces.Count - 1 do
      FWaterSurfaces[i].Visible := Value;
end;

function TWaterManager.SurfaceCount : integer;
begin
  Result := FWaterSurfaces.Count;
end;

end.

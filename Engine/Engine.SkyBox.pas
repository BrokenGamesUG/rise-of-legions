unit Engine.SkyBox;

interface

uses
  Engine.Core,
  Engine.Core.Types,
  Engine.Vertex,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Core.Camera,
  Math;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  TSky = class(TRenderable)
    protected
      Vertexbuffer : TVertexbuffer;

      constructor Create(Scene : TRenderManager);
    public
      destructor Destroy; override;
  end;

  TSkyBox = class(TSky)
    protected
      Skymap : array [0 .. 5] of TTexture; // Links,Vorne,Rechts,Hinten,Oben,Unten
      HatTexturen : Boolean;
      FPrimitivesPerSide : integer;
      procedure InitGeometry(ColorTop, ColorBottom : RColor); virtual;
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
    public
      constructor Create(Scene : TRenderManager; Dateiname : array of string); overload;
      constructor Create(Scene : TRenderManager; FarbeUnten, FarbeOben : Cardinal); overload;
      destructor Destroy; override;
  end;

  TSkySphericalCube = class(TSkyBox)
    protected
      procedure InitGeometry(ColorTop, ColorBottom : RColor); override;
  end;

  TSkySphere = class(TSky)
    protected
      Skymap : TTexture;
      HatTexturen : Boolean;
      Indexbuffer : TIndexbuffer;
      Primitiven, Vertices : integer;
      FHalfSphere : Boolean;
      procedure InitGeometry(Gradient : array of Cardinal);
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
    public
      constructor Create(Scene : TRenderManager; Dateiname : string; HalfSphere : Boolean = True); overload;
      constructor Create(Scene : TRenderManager; HalfSphere : Boolean = True; FarbeUnten : Cardinal = $FF9CC8FE; FarbeOben : Cardinal = $FF5B7EC5); overload;
      /// <summary> Gradient is oriented top to bottom. </summary>
      constructor Create(Scene : TRenderManager; Gradient : array of Cardinal; HalfSphere : Boolean = True); overload;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

{ TSkyBox }

procedure TSkyBox.InitGeometry(ColorTop, ColorBottom : RColor);
const
  Tex1 : RVector2 = (X : 1; Y : 0);
  Tex2 : RVector2 = (X : 0; Y : 0);
  Tex3 : RVector2 = (X : 1; Y : 1);
  Tex4 : RVector2 = (X : 0; Y : 1);

var
  Punkte : array [0 .. 35] of RVertexPositionColorTexture;
  Corner1 : RVertexPositionColorTexture;
  Corner2 : RVertexPositionColorTexture;
  Corner3 : RVertexPositionColorTexture;
  Corner4 : RVertexPositionColorTexture;
  Corner5 : RVertexPositionColorTexture;
  Corner6 : RVertexPositionColorTexture;
  Corner7 : RVertexPositionColorTexture;
  Corner8 : RVertexPositionColorTexture;
  pVertex : Pointer;
begin
  FPrimitivesPerSide := 6;
  Corner1.Position := RVector3.Create(-10, 10, -10);
  Corner1.Color := ColorTop;
  Corner2.Position := RVector3.Create(-10, 10, 10);
  Corner2.Color := ColorTop;
  Corner3.Position := RVector3.Create(-10, -10, -10);
  Corner3.Color := ColorBottom;
  Corner4.Position := RVector3.Create(-10, -10, 10);
  Corner4.Color := ColorBottom;
  Corner5.Position := RVector3.Create(10, 10, -10);
  Corner5.Color := ColorTop;
  Corner6.Position := RVector3.Create(10, 10, 10);
  Corner6.Color := ColorTop;
  Corner7.Position := RVector3.Create(10, -10, -10);
  Corner7.Color := ColorBottom;
  Corner8.Position := RVector3.Create(10, -10, 10);
  Corner8.Color := ColorBottom;
  Vertexbuffer := TVertexbuffer.CreateVertexBuffer(sizeof(RVertexPositionColorTexture) * 36, [usWriteable], GFXD.Device3D);
  // Links
  Punkte[0] := Corner1;
  Punkte[1] := Corner2;
  Punkte[2] := Corner3;
  Punkte[3] := Corner3;
  Punkte[4] := Corner2;
  Punkte[5] := Corner4;
  Punkte[0].TextureCoordinate := Tex2;
  Punkte[1].TextureCoordinate := Tex1;
  Punkte[2].TextureCoordinate := Tex4;
  Punkte[3].TextureCoordinate := Tex4;
  Punkte[4].TextureCoordinate := Tex1;
  Punkte[5].TextureCoordinate := Tex3;
  // Vorne
  Punkte[6] := Corner2;
  Punkte[7] := Corner6;
  Punkte[8] := Corner4;
  Punkte[9] := Corner4;
  Punkte[10] := Corner6;
  Punkte[11] := Corner8;
  Punkte[6].TextureCoordinate := Tex2;
  Punkte[7].TextureCoordinate := Tex1;
  Punkte[8].TextureCoordinate := Tex4;
  Punkte[9].TextureCoordinate := Tex4;
  Punkte[10].TextureCoordinate := Tex1;
  Punkte[11].TextureCoordinate := Tex3;
  // Rechts
  Punkte[12] := Corner6;
  Punkte[13] := Corner5;
  Punkte[14] := Corner8;
  Punkte[15] := Corner8;
  Punkte[16] := Corner5;
  Punkte[17] := Corner7;
  Punkte[12].TextureCoordinate := Tex2;
  Punkte[13].TextureCoordinate := Tex1;
  Punkte[14].TextureCoordinate := Tex4;
  Punkte[15].TextureCoordinate := Tex4;
  Punkte[16].TextureCoordinate := Tex1;
  Punkte[17].TextureCoordinate := Tex3;
  // Hinten
  Punkte[18] := Corner5;
  Punkte[19] := Corner1;
  Punkte[20] := Corner7;
  Punkte[21] := Corner7;
  Punkte[22] := Corner1;
  Punkte[23] := Corner3;
  Punkte[18].TextureCoordinate := Tex2;
  Punkte[19].TextureCoordinate := Tex1;
  Punkte[20].TextureCoordinate := Tex4;
  Punkte[21].TextureCoordinate := Tex4;
  Punkte[22].TextureCoordinate := Tex1;
  Punkte[23].TextureCoordinate := Tex3;
  // Oben
  Punkte[24] := Corner2;
  Punkte[25] := Corner1;
  Punkte[26] := Corner6;
  Punkte[27] := Corner6;
  Punkte[28] := Corner1;
  Punkte[29] := Corner5;
  Punkte[24].TextureCoordinate := Tex4;
  Punkte[25].TextureCoordinate := Tex2;
  Punkte[26].TextureCoordinate := Tex3;
  Punkte[27].TextureCoordinate := Tex3;
  Punkte[28].TextureCoordinate := Tex2;
  Punkte[29].TextureCoordinate := Tex1;
  // Unten
  Punkte[30] := Corner4;
  Punkte[31] := Corner8;
  Punkte[32] := Corner3;
  Punkte[33] := Corner3;
  Punkte[34] := Corner8;
  Punkte[35] := Corner7;
  Punkte[30].TextureCoordinate := Tex2;
  Punkte[31].TextureCoordinate := Tex1;
  Punkte[32].TextureCoordinate := Tex4;
  Punkte[33].TextureCoordinate := Tex4;
  Punkte[34].TextureCoordinate := Tex1;
  Punkte[35].TextureCoordinate := Tex3;

  pVertex := Vertexbuffer.LowLock;
  Move(Punkte, pVertex^, sizeof(Punkte));
  Vertexbuffer.Unlock;
end;

constructor TSkyBox.Create(Scene : TRenderManager; Dateiname : array of string);
begin
  inherited Create(Scene);
  HatTexturen := True;
  Skymap[0] := TTexture.CreateTextureFromFile(Dateiname[0], GFXD.Device3D, mhGenerate, True);
  Skymap[1] := TTexture.CreateTextureFromFile(Dateiname[1], GFXD.Device3D, mhGenerate, True);
  Skymap[2] := TTexture.CreateTextureFromFile(Dateiname[2], GFXD.Device3D, mhGenerate, True);
  Skymap[3] := TTexture.CreateTextureFromFile(Dateiname[3], GFXD.Device3D, mhGenerate, True);
  Skymap[4] := TTexture.CreateTextureFromFile(Dateiname[4], GFXD.Device3D, mhGenerate, True);
  Skymap[5] := TTexture.CreateTextureFromFile(Dateiname[5], GFXD.Device3D, mhGenerate, True);
  InitGeometry($FFFFFFFF, $FFFFFFFF);
end;

constructor TSkyBox.Create(Scene : TRenderManager; FarbeUnten, FarbeOben : Cardinal);
begin
  inherited Create(Scene);
  HatTexturen := False;
  InitGeometry(FarbeOben, FarbeUnten);
end;

destructor TSkyBox.Destroy;
var
  i : integer;
begin
  for i := 0 to length(Skymap) - 1 do Skymap[i].Free;
  inherited;
end;

procedure TSkyBox.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
var
  CameraData : RCameraData;
  i : integer;
  ShaderFlags : SetDefaultShaderFlags;
  Shader : TShader;
begin
  CameraData := RenderContext.Camera.CameraData;
  RenderContext.Camera.PerspectiveCamera(RVector3.ZERO, RenderContext.Camera.CameraDirection);
  GFXD.Device3D.SetRenderState(EnumRenderstate.rsZENABLE, False);

  ShaderFlags := [];
  if HatTexturen then
  begin
    ShaderFlags := ShaderFlags + [sfDiffuseTexture];
    GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amClamp);
  end
  else ShaderFlags := ShaderFlags + [sfVertexcolor];

  Shader := RenderContext.CreateAndSetDefaultShader(ShaderFlags);
  Shader.SetWorld(RMatrix.IDENTITY);

  GFXD.Device3D.SetStreamSource(0, Vertexbuffer, 0, sizeof(RVertexPositionColorTexture));
  GFXD.Device3D.SetVertexDeclaration(RVertexPositionColorTexture.BuildVertexdeclaration);
  GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, EnumCullmode.cmCCW);
  // GFXD.Device3D.SetRenderState(EnumRenderstate.rsFILLMODE, EnumFillMode.fmWireframe);

  if HatTexturen then
  begin
    for i := 0 to 5 do
    begin
      Shader.SetTexture(tsColor, Skymap[i]);
      Shader.ShaderBegin;
      GFXD.Device3D.DrawPrimitive(ptTrianglelist, i * FPrimitivesPerSide * 3, FPrimitivesPerSide);
      Shader.ShaderEnd;
    end;
  end
  else
  begin
    Shader.ShaderBegin;
    GFXD.Device3D.DrawPrimitive(ptTrianglelist, 0, FPrimitivesPerSide * 6);
    Shader.ShaderEnd;
  end;
  RenderContext.Camera.CameraData := CameraData;

  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

{ TSkySphere }

constructor TSkySphere.Create(Scene : TRenderManager; Dateiname : string; HalfSphere : Boolean);
begin
  inherited Create(Scene);
  HatTexturen := True;
  FHalfSphere := HalfSphere;
  Skymap := TTexture.CreateTextureFromFile(Dateiname, GFXD.Device3D, mhGenerate, True);
  InitGeometry([$FFFFFFFF]);
end;

constructor TSkySphere.Create(Scene : TRenderManager; HalfSphere : Boolean; FarbeUnten : Cardinal; FarbeOben : Cardinal);
begin
  Create(Scene, [FarbeOben, FarbeUnten], HalfSphere);
end;

constructor TSkySphere.Create(Scene : TRenderManager; Gradient : array of Cardinal; HalfSphere : Boolean);
begin
  inherited Create(Scene);
  HatTexturen := False;
  FHalfSphere := HalfSphere;
  InitGeometry(Gradient);
end;

destructor TSkySphere.Destroy;
begin
  Skymap.Free;
  Indexbuffer.Free;
  inherited;
end;

procedure TSkySphere.InitGeometry(Gradient : array of Cardinal);
var
  Punkte : array of RVertexPositionColorTexture;
  Indizes : array of Cardinal;
  pVertex : Pointer;
  i, i2, Layer, Segments, Radius, ind, PointIndex : integer;
  s, s2, stemp : Single;
  LayerVector, Pos : RVector3;
begin
  Segments := 64;
  Layer := 64;
  Radius := 20;
  Vertices := Layer * Segments;
  Primitiven := ((Layer - 1) * (Segments - 1) * 2);
  if FHalfSphere then
  begin
    Primitiven := ((Layer div 2) * (Segments - 1) * 2);
    Vertices := (Layer div 2 + 1) * Segments;
  end;
  Vertexbuffer := TVertexbuffer.CreateVertexBuffer(sizeof(RVertexPositionColorTexture) * Vertices, [usWriteable], GFXD.Device3D);
  Indexbuffer := TIndexbuffer.CreateIndexBuffer(sizeof(Cardinal) * Primitiven * 3, [usWriteable], ifINDEX32, GFXD.Device3D);

  SetLength(Punkte, Vertices);
  // Layers
  PointIndex := 0;
  for i := 0 to Layer - 1 do
  begin
    s := i / (Layer - 1);
    LayerVector := RVector3.Create(sin(s * PI), cos(s * PI), 0).Normalize * Radius;
    for i2 := 0 to Segments - 1 do
    begin
      s2 := i2 / (Segments - 1);
      Pos := LayerVector.RotatePitchYawRoll(0, s2 * 2 * PI, 0);
      Punkte[PointIndex].Position := Pos;
      Pos.InNormalize;
      if FHalfSphere then stemp := i / (Layer div 2)
      else stemp := arcsin(SLinLerp(-1, 1, s)) / PI + 0.5;
      Punkte[PointIndex].TextureCoordinate := RVector2.Create(s2, stemp);
      Punkte[PointIndex].Color := RColor.LerpArray(Gradient, HGeneric.TertOp<Single>(FHalfSphere, s * 2, s));
      inc(PointIndex);
    end;
    if FHalfSphere and (i >= (Layer div 2)) then break;
  end;
  assert(PointIndex = Vertices);

  pVertex := Vertexbuffer.LowLock;
  Move(Punkte[0], pVertex^, sizeof(RVertexPositionColorTexture) * length(Punkte));
  Vertexbuffer.Unlock;

  SetLength(Indizes, Primitiven * 3);
  ind := 0;
  for i := 0 to Layer - 2 do
  begin
    for i2 := 0 to Segments - 2 do
    begin
      Indizes[ind] := i * Segments + i2;
      Indizes[ind + 1] := (i + 1) * Segments + i2;
      Indizes[ind + 2] := i * Segments + (i2 + 1);

      Indizes[ind + 3] := Indizes[ind + 2];
      Indizes[ind + 4] := Indizes[ind + 1];
      Indizes[ind + 5] := (i + 1) * Segments + (i2 + 1);
      inc(ind, 6);
    end;
    if FHalfSphere and (i >= (Layer div 2) - 1) then break;
  end;
  assert(ind = Primitiven * 3);
  pVertex := Indexbuffer.LowLock([lfDiscard]);
  Move(Indizes[0], pVertex^, sizeof(Cardinal) * Primitiven * 3);
  Indexbuffer.Unlock;
end;

constructor TSky.Create(Scene : TRenderManager);
begin
  inherited Create(Scene, [rsEnvironment]);
end;

destructor TSky.Destroy;
begin
  Vertexbuffer.Free;
  inherited;
end;

procedure TSkySphere.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
var
  CameraData : RCameraData;
  ShaderFlags : SetDefaultShaderFlags;
  Shader : TShader;
begin
  CameraData := RenderContext.Camera.CameraData;
  RenderContext.Camera.PerspectiveCamera(RVector3.ZERO, RenderContext.Camera.CameraDirection);

  GFXD.Device3D.SetRenderState(EnumRenderstate.rsZENABLE, 0);
  GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, ord(cmCCW));
  ShaderFlags := [];
  if HatTexturen then ShaderFlags := ShaderFlags + [sfDiffuseTexture]
  else ShaderFlags := ShaderFlags + [sfVertexcolor];

  Shader := RenderContext.CreateAndSetDefaultShader(ShaderFlags);
  if HatTexturen then Shader.SetTexture(tsColor, Skymap);
  Shader.SetWorld(RMatrix.IDENTITY);
  GFXD.Device3D.SetVertexDeclaration(RVertexPositionColorTexture.BuildVertexdeclaration);
  GFXD.Device3D.SetStreamSource(0, Vertexbuffer, 0, sizeof(RVertexPositionColorTexture));
  GFXD.Device3D.SetIndices(Indexbuffer);
  Shader.ShaderBegin;
  GFXD.Device3D.DrawIndexedPrimitive(ptTrianglelist, 0, 0, Vertices, 0, Primitiven);
  Shader.ShaderEnd;

  RenderContext.Camera.CameraData := CameraData;
  GFXD.Device3D.ClearRenderState();
end;

{ TSkySphericalCube }

procedure TSkySphericalCube.InitGeometry(ColorTop, ColorBottom : RColor);
const
  GRID = 16;
var
  Points : array of RVertexPositionColorTexture;
  Vertices, Counter : integer;
  pVertex : Pointer;
  Side : integer;
  Corner1, Corner2, Corner3, Corner4 : RVector3;
  procedure AddSide(Samples : integer);
  var
    tpoint1, tpoint2, tpoint3, tpoint4 : RVertexPositionColorTexture;
    X, Y : integer;
    procedure AddPoint(s, t : Single);
    // var
    // X, Y, z : Single;
    begin
      Points[Counter] := tpoint1.Lerp(tpoint2, s).Lerp(tpoint3.Lerp(tpoint4, s), t);
      Points[Counter].Position := Points[Counter].Position * 10;
      // X := Points[Counter].Position.X;
      // Y := Points[Counter].Position.Y;
      // z := Points[Counter].Position.z;
      // Points[Counter].Position := RVector3.Create(X * sqrt(1 - (sqr(Y) / 2) - (sqr(z) / 2) + ((sqr(Y) * sqr(z)) / 3)),
      // Y * sqrt(1 - (sqr(z) / 2) - (sqr(X) / 2) + ((sqr(z) * sqr(X)) / 3)),
      // z * sqrt(1 - (sqr(X) / 2) - (sqr(Y) / 2) + ((sqr(X) * sqr(Y)) / 3)))*10;
      inc(Counter);
    end;

  begin
    tpoint1 := RVertexPositionColorTexture.Create(Corner1, RVector2.Create(0, 0), $FFFFFFFF);
    tpoint2 := RVertexPositionColorTexture.Create(Corner2, RVector2.Create(1, 0), $FFFFFFFF);
    tpoint3 := RVertexPositionColorTexture.Create(Corner3, RVector2.Create(0, 1), $FFFFFFFF);
    tpoint4 := RVertexPositionColorTexture.Create(Corner4, RVector2.Create(1, 1), $FFFFFFFF);

    for Y := 0 to Samples - 2 do
      for X := 0 to Samples - 2 do
      begin
        AddPoint((X) / (Samples - 1), (Y) / (Samples - 1));
        AddPoint((X + 1) / (Samples - 1), (Y) / (Samples - 1));
        AddPoint((X) / (Samples - 1), (Y + 1) / (Samples - 1));
        AddPoint((X) / (Samples - 1), (Y + 1) / (Samples - 1));
        AddPoint((X + 1) / (Samples - 1), (Y) / (Samples - 1));
        AddPoint((X + 1) / (Samples - 1), (Y + 1) / (Samples - 1));
      end;
  end;

begin
  Vertices := 6 * sqr(GRID - 1) * 2 * 3;
  Vertexbuffer := TVertexbuffer.CreateVertexBuffer(sizeof(RVertexPositionColorTexture) * Vertices, [usWriteable], GFXD.Device3D);
  SetLength(Points, Vertices);
  Counter := 0;

  for Side := 0 to 5 do
  begin
    Corner1 := RVector3.Create(-1, 1, 1);
    Corner2 := RVector3.Create(1, 1, 1);
    Corner3 := RVector3.Create(-1, -1, 1);
    Corner4 := RVector3.Create(1, -1, 1);

    if Side < 4 then
    begin
      Corner1 := Corner1.RotatePitchYawRoll(0, PI / 2 * Side, 0);
      Corner2 := Corner2.RotatePitchYawRoll(0, PI / 2 * Side, 0);
      Corner3 := Corner3.RotatePitchYawRoll(0, PI / 2 * Side, 0);
      Corner4 := Corner4.RotatePitchYawRoll(0, PI / 2 * Side, 0);
    end
    else
    begin
      Corner1 := Corner1.RotatePitchYawRoll(PI * (-Side + 4.5), 0, 0);
      Corner2 := Corner2.RotatePitchYawRoll(PI * (-Side + 4.5), 0, 0);
      Corner3 := Corner3.RotatePitchYawRoll(PI * (-Side + 4.5), 0, 0);
      Corner4 := Corner4.RotatePitchYawRoll(PI * (-Side + 4.5), 0, 0);
    end;
    AddSide(GRID);
  end;

  assert(Vertices = Counter);

  pVertex := Vertexbuffer.LowLock;
  Move(Points[0], pVertex^, sizeof(RVertexPositionColorTexture) * length(Points));
  Vertexbuffer.Unlock;

  FPrimitivesPerSide := sqr(GRID - 1) * 2;
end;

end.

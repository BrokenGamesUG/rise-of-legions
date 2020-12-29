unit Engine.AnimatedBackground;

interface

uses
  Generics.Collections,
  SysUtils,
  Engine.Core,
  Engine.Core.Types,
  Engine.GFXApi.Types,
  Engine.Serializer,
  Engine.Serializer.Types,
  Engine.Vertex,
  Engine.Math.Collision2D,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.GFXApi;

const

  MAX_DRAW_ORDER = 100000;

type

  {$RTTI EXPLICIT METHODS([vcPublic, vcProtected]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  TAnimatedImage = class;

  RKeyFrame = record
    RelativeTime : single;
    PositionOffset : RVector2;
    constructor Create(RelativeTime : single; PositionOffset : RVector2);
  end;

  [XMLExcludeAll]
  TAnimatedImageLayer = class
    private
      function getTextureFilename : string;
      procedure setTextureFilename(const Value : string);
      procedure SetIndices(const Value : TList<RIntVector3>);
      procedure SetVertices(const Value : TList<RVector2>);
      procedure SetKeyframes(const Value : TObjectDictionary < integer, TList < RKeyFrame >> );
    protected
      FOwner : TAnimatedImage;
      FTexture : TTexture;
      FQuad : TVertexScreenAlignedQuad;
      FTriangles : TObjectList<TVertexScreenAlignedTriangle>;
      FDepth, FTimeScale : single;
      FRect : RRectFloat;
      /// <summary> Vertices are saved relative to FRect. </summary>
      FVertices : TList<RVector2>;
      FIndices : TList<RIntVector3>;
      /// <summary> Maps VertexIndex to Keyframes </summary>
      FKeyFrames : TObjectDictionary<integer, TList<RKeyFrame>>;
      constructor Create; overload;
      function GetVertexPositionInTime(VertexIndex : integer; Time : single) : RVector2;
    public
      [XMLIncludeElement]
      /// <summary> The keyframes are mapped onto one second. This value manipulates the animation length. </summary>
      property TimeScale : single read FTimeScale write FTimeScale;
      [XMLIncludeElement]
      /// <summary> Depth of this layer in [0,1], where 0 is the foreground and 1 the background. </summary>
      property Depth : single read FDepth write FDepth;
      [XMLIncludeElement]
      property Rect : RRectFloat read FRect write FRect;
      [XMLIncludeElement]
      property TextureFilename : string read getTextureFilename write setTextureFilename;
      [XMLIncludeElement]
      property Vertices : TList<RVector2> read FVertices write SetVertices;
      [XMLIncludeElement]
      property Indices : TList<RIntVector3> read FIndices write SetIndices;
      [XMLIncludeElement]
      property Keyframes : TObjectDictionary < integer, TList < RKeyFrame >> read FKeyFrames write SetKeyframes;
      procedure AddVertex(ScreenPosition : RVector2);
      procedure ManipulateVertex(index : integer; NewPosition : RVector2);
      procedure RemoveVertex(VertexIndex : integer);
      procedure SetKeyFrame(VertexIndex : integer; RelativeTime : single; TargetPosition : RVector2);
      function ScreenToLayer(Position : RVector2) : RVector2;
      function LayerToScreen(Position : RVector2) : RVector2;
      function LayerToRelativeScreen(Position : RVector2) : RVector2;
      function RelativeScreenToLayer(Position : RVector2) : RVector2;
      function RelativeScreenToScreen(Position : RVector2) : RVector2;
      function ScreenToRelativeScreen(Position : RVector2) : RVector2;
      procedure AddTriangle(Indices : RIntVector3);
      procedure RemoveTriangle(index : integer);
      constructor Create(Owner : TAnimatedImage); overload;
      procedure Idle(Offset : RVector2; Zoom : single; CurrentTime : single);
      destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TAnimatedImage = class
    protected
      FBlackBorderTop, FBlackBorderBottom : TVertexScreenAlignedQuad;
      [XMLIncludeElement]
      FLayer : TObjectList<TAnimatedImageLayer>;
      FOffset : RVector2;
      [XMLIncludeElement]
      FZoom : single;
      [XMLIncludeElement]
      FAspectRatio : single;
      function NeedsBlackBorder : boolean;
      procedure ProcessBlackBorder;
    public
      Animated : single;
      property Layer : TObjectList<TAnimatedImageLayer> read FLayer;
      property Offset : RVector2 read FOffset write FOffset;
      property Zoom : single read FZoom write FZoom;
      constructor Create;
      constructor CreateFromFile(Filename : string);
      function AddLayer(TextureFilename : string) : TAnimatedImageLayer;
      procedure Idle;
      procedure SaveToFile(Filename : string);
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

{ TAnimatedImage }

function TAnimatedImage.AddLayer(TextureFilename : string) : TAnimatedImageLayer;
begin
  Result := TAnimatedImageLayer.Create(self);
  FZoom := 1.0;
  FLayer.Add(Result);
  Result.TextureFilename := TextureFilename;
end;

constructor TAnimatedImage.Create;
begin
  FLayer := TObjectList<TAnimatedImageLayer>.Create;
  Animated := -1;
  FAspectRatio := 1920 / 1080;
end;

constructor TAnimatedImage.CreateFromFile(Filename : string);
begin
  Create;
  if not FileExists(Filename) then raise Exception.Create('TAnimatedImage.CreateFromFile: Animated background file ' + Filename + ' does not exist!');
  HXMLSerializer.LoadObjectFromFile(self, Filename, [self]);
end;

destructor TAnimatedImage.Destroy;
begin
  FLayer.Free;
  FBlackBorderTop.Free;
  FBlackBorderBottom.Free;
  inherited;
end;

procedure TAnimatedImage.Idle;
var
  i : integer;
begin
  for i := 0 to FLayer.Count - 1 do
  begin
    if Animated < 0 then
        FLayer[i].Idle(FOffset, FZoom, TimeManager.GetFloatingTimestamp / 1000)
    else
        FLayer[i].Idle(RVector2.Create(0), 1, Animated);
  end;
  ProcessBlackBorder;
end;

function TAnimatedImage.NeedsBlackBorder : boolean;
begin
  Result := False and (GFXD.Settings.Resolution.AspectRatio < FAspectRatio);
end;

procedure TAnimatedImage.ProcessBlackBorder;
begin
  if NeedsBlackBorder then
  begin
    if not assigned(FBlackBorderTop) then FBlackBorderTop := TVertexScreenAlignedQuad.Create(VertexEngine);
    if not assigned(FBlackBorderBottom) then FBlackBorderBottom := TVertexScreenAlignedQuad.Create(VertexEngine);
    FBlackBorderTop.Position := RVector2.ZERO;
    FBlackBorderTop.Color := $FF000000;
    FBlackBorderTop.DrawOrder := MAX_DRAW_ORDER + 1;
    FBlackBorderTop.Width := GFXD.Settings.Resolution.Width;
    FBlackBorderTop.Height := GFXD.Settings.Resolution.Height * (1 - GFXD.Settings.Resolution.AspectRatio / FAspectRatio) / 2;
    FBlackBorderTop.AddRenderJob;
    FBlackBorderBottom.Position := RVector2.Create(0, GFXD.Settings.Resolution.Height - FBlackBorderTop.Height);
    FBlackBorderBottom.Color := $FF000000;
    FBlackBorderBottom.DrawOrder := MAX_DRAW_ORDER + 1;
    FBlackBorderBottom.Width := GFXD.Settings.Resolution.Width;
    FBlackBorderBottom.Height := FBlackBorderTop.Height;
    FBlackBorderBottom.AddRenderJob;
  end;
end;

procedure TAnimatedImage.SaveToFile(Filename : string);
begin
  HXMLSerializer.SaveObjectToFile(self, Filename);
end;

{ TAnimatedImageLayer }

procedure TAnimatedImageLayer.AddTriangle(Indices : RIntVector3);
var
  Triangle : TVertexScreenAlignedTriangle;
begin
  FIndices.Add(Indices);
  Triangle := TVertexScreenAlignedTriangle.Create(VertexEngine);
  Triangle.DrawsAtStage := rsEnvironment;
  Triangle.AddressMode := EnumTexturAddressMode.amClamp;
  FTriangles.Add(Triangle);
end;

procedure TAnimatedImageLayer.AddVertex(ScreenPosition : RVector2);
begin
  FVertices.Add(ScreenToLayer(ScreenPosition));
end;

constructor TAnimatedImageLayer.Create;
begin
  Depth := 0;
  FTimeScale := 1.0;
  Rect := RRectFloat.Create(0, 0, 1, 1);
  FTriangles := TObjectList<TVertexScreenAlignedTriangle>.Create;
  FVertices := TList<RVector2>.Create;
  FIndices := TList<RIntVector3>.Create;
  FKeyFrames := TObjectDictionary < integer, TList < RKeyFrame >>.Create([doOwnsValues]);
end;

constructor TAnimatedImageLayer.Create(Owner : TAnimatedImage);
begin
  Create;
  FOwner := Owner;
  FQuad := TVertexScreenAlignedQuad.Create(VertexEngine);
  FQuad.DrawsAtStage := rsEnvironment;
  FQuad.AddressMode := amClamp;
  FQuad.Anchor := RVector2.Create(0.5);
end;

destructor TAnimatedImageLayer.Destroy;
begin
  FKeyFrames.Free;
  FVertices.Free;
  FIndices.Free;
  FTriangles.Free;
  FQuad.Free;
  FTexture.Free;
  inherited;
end;

function TAnimatedImageLayer.getTextureFilename : string;
begin
  Result := '';
  if assigned(FTexture) then
      Result := RelativDateiPfad(FTexture.Filename);
end;

function TAnimatedImageLayer.GetVertexPositionInTime(VertexIndex : integer; Time : single) : RVector2;
var
  Keyframes : TList<RKeyFrame>;
  i, ip1 : integer;
  originalPos : RVector2;
  s : single;
  Over : boolean;
begin
  // in edit mode doesn't apply timescale
  if FOwner.Animated < 0 then Time := frac(Time / FTimeScale)
  else Time := frac(Time);

  originalPos := FVertices[VertexIndex];
  if not FKeyFrames.TryGetValue(VertexIndex, Keyframes) then exit(originalPos);
  if Keyframes.Count = 1 then exit(originalPos + Keyframes.First.PositionOffset);

  for i := 0 to Keyframes.Count - 1 do
  begin
    ip1 := (i + 1) mod Keyframes.Count;

    Over := Keyframes[ip1].RelativeTime < Keyframes[i].RelativeTime;

    if Over then
        s := ((1 + Keyframes[ip1].RelativeTime) - Keyframes[i].RelativeTime)
    else
        s := (Keyframes[ip1].RelativeTime - Keyframes[i].RelativeTime);

    if s = 0 then s := 0
    else
    begin
      if Time < Keyframes[i].RelativeTime then
          s := (Time - (Keyframes[i].RelativeTime - 1)) / s
      else
          s := (Time - Keyframes[i].RelativeTime) / s;
    end;

    if (s >= 0) and (s <= 1) then
    begin
      Result := originalPos + Keyframes[i].PositionOffset.CosLerp(Keyframes[ip1].PositionOffset, s);
      exit;
    end;
  end;
end;

procedure TAnimatedImageLayer.Idle(Offset : RVector2; Zoom : single; CurrentTime : single);
  function ApplyZoomAndOffsetToRelativePosition(Pos : RVector2) : RVector2;
  begin
    // zoom position
    Result := (Pos - RVector2.Create(0.5, 0.5)) * Zoom + RVector2.Create(0.5, 0.5);
    // apply offset
    Result := Result + (Offset * (1 - Depth));
  end;

var
  i, j : integer;
  RelativePosition : RVector2;
begin
  if (FTriangles.Count <= 0) or not(FOwner.Animated < 0) then
  begin
    if (FTriangles.Count > 0) then FQuad.Color := $80FFFFFF
    else FQuad.Color := $FFFFFFFF;
    FQuad.Texture := FTexture;
    FQuad.DrawOrder := round(MAX_DRAW_ORDER * (1 - Depth));
    FQuad.Size := RelativeScreenToScreen(FRect.Size * Zoom);

    FQuad.Position := ApplyZoomAndOffsetToRelativePosition(FRect.Center);
    FQuad.Position := RelativeScreenToScreen(FQuad.Position);

    FQuad.AddRenderJob;
  end;

  for i := 0 to FTriangles.Count - 1 do
  begin
    FTriangles[i].Texture := FTexture;
    FTriangles[i].DrawOrder := round(MAX_DRAW_ORDER * (1 - Depth));

    for j := 0 to 2 do
    begin
      RelativePosition := FVertices[FIndices[i].Element[j]];
      FTriangles[i].TextureCoordinate[j] := RelativePosition;
      RelativePosition := GetVertexPositionInTime(FIndices[i].Element[j], CurrentTime);
      FTriangles[i].Position[j] := LayerToRelativeScreen(RelativePosition);
      FTriangles[i].Position[j] := ApplyZoomAndOffsetToRelativePosition(FTriangles[i].Position[j]);
      FTriangles[i].Position[j] := RelativeScreenToScreen(FTriangles[i].Position[j]);
    end;

    FTriangles[i].AddRenderJob;
  end;
end;

function TAnimatedImageLayer.LayerToRelativeScreen(Position : RVector2) : RVector2;
begin
  Result := (Position * FRect.Size + FRect.LeftTop);
end;

function TAnimatedImageLayer.LayerToScreen(Position : RVector2) : RVector2;
begin
  Result := RelativeScreenToScreen(LayerToRelativeScreen(Position));
end;

procedure TAnimatedImageLayer.ManipulateVertex(index : integer; NewPosition : RVector2);
begin
  FVertices[index] := ScreenToLayer(NewPosition);
end;

function TAnimatedImageLayer.RelativeScreenToLayer(Position : RVector2) : RVector2;
begin
  Result := (Position - FRect.LeftTop) / FRect.Size;
end;

function TAnimatedImageLayer.RelativeScreenToScreen(Position : RVector2) : RVector2;
var
  stretchfactor : single;
  Offset, Scale : RVector2;
begin
  stretchfactor := GFXD.Settings.Resolution.AspectRatio / FOwner.FAspectRatio;
  // broader than we -> cut left and right
  if stretchfactor > 1 then
  begin
    Offset := RVector2.Create(0, 0);
    Scale := RVector2.Create(1, stretchfactor)
  end
  else
  // thinner than we -> black top and bottom border; or same than stretchfactor = 1 and nothing happens
  begin
    Offset := RVector2.Create(0, GFXD.Settings.Resolution.Height * (1 - stretchfactor) / 2);
    Scale := RVector2.Create(1, stretchfactor);
  end;
  Result := Position * GFXD.Settings.Resolution.Size * Scale + Offset;
end;

function TAnimatedImageLayer.ScreenToLayer(Position : RVector2) : RVector2;
begin
  Result := RelativeScreenToLayer(ScreenToRelativeScreen(Position));
end;

function TAnimatedImageLayer.ScreenToRelativeScreen(Position : RVector2) : RVector2;
begin
  Result := Position / GFXD.Settings.Resolution.Size;
end;

procedure TAnimatedImageLayer.RemoveTriangle(index : integer);
begin
  FIndices.Delete(index);
  FTriangles.Delete(index);
end;

procedure TAnimatedImageLayer.RemoveVertex(VertexIndex : integer);
var
  i : integer;
  j : integer;
  tri : RIntVector3;
  list : TList<RKeyFrame>;
  tempDict : TObjectDictionary<integer, TList<RKeyFrame>>;
begin
  // remove all dependend triangles
  for i := Indices.Count - 1 downto 0 do
  begin
    if Indices[i].Contains(VertexIndex) then
        RemoveTriangle(i);
  end;
  // remove vertex and update indices and keyframes
  FVertices.Delete(VertexIndex);
  FKeyFrames.Remove(VertexIndex);
  for i := 0 to Indices.Count - 1 do
  begin
    tri := Indices[i];
    for j := 0 to 2 do
      if tri.Element[j] >= VertexIndex then dec(tri.Element[j]);
    Indices[i] := tri;
  end;
  // dicts aren't sorted so the iteration would produce errors possibly, e.g. frame is lowered from 13 to 12, but 12 haven't been processed yet
  // using a temp dictionary as solution
  tempDict := TObjectDictionary < integer, TList < RKeyFrame >>.Create([doOwnsValues]);
  for i in Keyframes.Keys.ToArray do
  begin
    list := Keyframes.ExtractPair(i).Value;
    if i >= VertexIndex then
        tempDict.Add(i - 1, list)
    else
        tempDict.Add(i, list);
  end;
  FKeyFrames.Free;
  FKeyFrames := tempDict;
end;

procedure TAnimatedImageLayer.SetIndices(const Value : TList<RIntVector3>);
var
  i : integer;
begin
  if Value = FIndices then
  begin
    FIndices := TList<RIntVector3>.Create;
  end
  else FIndices.Clear;
  for i := 0 to Value.Count - 1 do
  begin
    AddTriangle(Value[i]);
  end;
  Value.Free;
end;

procedure TAnimatedImageLayer.SetKeyFrame(VertexIndex : integer; RelativeTime : single; TargetPosition : RVector2);
var
  Keyframes : TList<RKeyFrame>;
  i : integer;
  newKeyFrame : RKeyFrame;
begin
  if not FKeyFrames.TryGetValue(VertexIndex, Keyframes) then
  begin
    Keyframes := TList<RKeyFrame>.Create;
    FKeyFrames.Add(VertexIndex, Keyframes);
  end;
  newKeyFrame := RKeyFrame.Create(RelativeTime, ScreenToLayer(TargetPosition) - FVertices[VertexIndex]);
  for i := 0 to Keyframes.Count - 1 do
  begin
    if Keyframes[i].RelativeTime = RelativeTime then
    begin
      Keyframes[i] := newKeyFrame;
      exit;
    end;
    if Keyframes[i].RelativeTime > RelativeTime then
    begin
      Keyframes.Insert(i, newKeyFrame);
      exit;
    end;
  end;
  Keyframes.Add(newKeyFrame);
end;

procedure TAnimatedImageLayer.SetKeyframes(const Value : TObjectDictionary < integer, TList < RKeyFrame >> );
begin
  if Value <> FKeyFrames then
  begin
    FKeyFrames.Free;
  end;
  FKeyFrames := Value;
end;

procedure TAnimatedImageLayer.setTextureFilename(const Value : string);
begin
  FTexture.Free;
  FTexture := TTexture.CreateTextureFromFile(AbsolutePath(Value), GFXD.Device3D, mhGenerate, True);
end;

procedure TAnimatedImageLayer.SetVertices(const Value : TList<RVector2>);
begin
  if Value <> FVertices then
  begin
    FVertices.Free;
  end;
  FVertices := Value;
end;

{ RKeyFrame }

constructor RKeyFrame.Create(RelativeTime : single; PositionOffset : RVector2);
begin
  self.RelativeTime := RelativeTime;
  self.PositionOffset := PositionOffset;
end;

end.

unit Engine.Terrain;

interface

uses
  SysUtils,
  Windows,
  Math,
  Types,
  RTTI,
  Generics.Collections,
  Engine.Log,
  Engine.Core,
  Engine.Core.Types,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Math,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Core.Camera,
  Engine.Serializer.Types,
  Engine.Serializer,
  Engine.Vertex;

type

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  EnumMapType = (mtDiffuse, mtNormal, mtMaterial);

  /// <summary> A Texture for a chunk, which hold Diffuse-,Normalmaps etc. </summary>
  [XMLExcludeAll()]
  TChunkTexture = class(TXMLCustomSerializable)
    protected
      const
      DEFAULTSIZE = 1024;
    var
      FFileName : string;
      /// <summary> Diffuse - RGB Albedo | Normal - RGB Normal | Material - A Shading Reduction R Intensity G Power  </summary>
      FDiffusemap, FNormalmap, FMaterialmap : TTexture;
      FSize : cardinal;
      FEditable : array [EnumMapType] of boolean;
      /// <summary> The rect where this texture is applied to. Once with indices and once with floating coords </summary>
      FRect : RRect;
      FRelRect : RRectFloat;
      FChunkID : cardinal;
      procedure Resize(Size : cardinal);
      procedure CustomXMLSave(Node : TXMLNode; CustomData : array of TObject); override;
      procedure CustomAfterXMLCreate; override;
      constructor CustomXMLCreate(Node : TXMLNode; CustomData : array of TObject); override;
      procedure CreateTextures(Size : Integer);
      procedure MakeEditable;
    public
      [XMLIncludeElement]
      property ChunkID : cardinal read FChunkID write FChunkID;
      constructor Create(ChunkID : cardinal = 0); overload;
      constructor Create(FileBase, DiffusemapFile, NormalMapFile, SpecularMapFile : string; ChunkID : cardinal = 0); overload;
      property TextureSize : cardinal read FSize write Resize;
      property DiffuseMap : TTexture read FDiffusemap;
      property NormalMap : TTexture read FNormalmap;
      property MaterialMap : TTexture read FMaterialmap;
      /// <summary> Loads a texture into one of the maps. Index: 0 - Diffuse, 1 - Normal, 2 - Specular </summary>
      procedure SetTexture(FilePath : string; Index : Integer);
      procedure ClearTexture(MapType : EnumMapType; Value : RColor);
      destructor Destroy; override;
  end;
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  EnumTerrainShadowTechnique = (NoShadows, Lightmap, Stencilshadows);

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  /// <summary> Holds all visualisationsettings for the terrain. </summary>
  RTerrainSettings = record
    Geomipmapdistanceerror, Geomipmapnormalerror : single;
    [XMLExcludeElement]
    DrawWireFramed : boolean;
    [XMLExcludeElement]
    UsedShadowTechnique : EnumTerrainShadowTechnique;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([vcPublic, vcPublished, vcProtected]) FIELDS([vcPublic, vcPublished, vcProtected])}

  /// <summary> A 2D-Heightmap. </summary>
  [XMLBaseClass]
  [XMLIncludeAll([XMLIncludeFields, XMLIncludeProperties])]
  TTerrain = class(TWorldObject)
    public
      const
      FILEEXTENSION = '.ter';
    protected
      type
      /// <summary> Holds the LoD-Level of a tile and its neightbours. </summary>
      RLoDDependency = record
        Middle, Left, Top, Right, Bottom : cardinal;
        constructor Create(Middle, Left, Top, Right, Bottom : cardinal);
      end;

      /// <summary> A node of the Grid. </summary>
      RRawNode = record
        Position, Normal : RVector3;
      end;

      RSaveRawNode = record
        Height : single;
      end;

      ARawData = array of array of RRawNode;
      ASaveRawData = array of array of RSaveRawNode;

      TQuadTreeNode = class
        const
          TILESIZE = 64;

        type
          ANodeMap = array of array of TQuadTreeNode;
          EnumNeighbour = (Middle, Left, Top, Right, Bottom);
        var
          FChildren : array [0 .. 3] of TQuadTreeNode;
          FData : ARawData;
          FTile : TRect;
          FTerrain : TTerrain;
          FBoundingBox : RAABB;
          FLoDError : TList<single>;
          FTileMap : ANodeMap;
          FChunkTexture : TChunkTexture;
          FParent : TQuadTreeNode;
          FLastTileLoDLevel : RLoDDependency;
          constructor Create(SubRect : TRect; Data : ARawData; Terrain : TTerrain; Parent : TQuadTreeNode; Tilemap : ANodeMap = nil);
          function getTilePerIndex(x, y : Integer) : TQuadTreeNode;
          function getNeighbour(Neighbour : EnumNeighbour) : TQuadTreeNode;
          function getLoDDependency : RLoDDependency;
          function HasChildren : boolean;
          function getRelativeRect : RRectFloat;
          procedure ComputeLoDErrors;
          function getLoDLevel : Integer;
          function TileRectToMinMaxBox(TileRect : TRect) : RAABB;
          function CheckVisibility(Cam : TCamera) : boolean;
          function getDepth() : byte;
          /// <summary> Return the childid of this node related to its parent. (0-4) </summary>
          function getChildID() : byte;
          /// <summary> Get the id of this node, if all nodes of the same depth would be numbered row by row. </summary>
          function getLayerID() : cardinal;
          procedure SetChunkTextures(Textures : TUltimateObjectList<TChunkTexture>);
          procedure RenderTiles(RenderContext : TRenderContext; ComputeLOD : boolean);
          destructor Destroy; override;
      end;

      ProcGridAction = procedure(x, y : Integer) of object;
    var
      [XMLExcludeElement]
      FVirtualBoundingBox : RAABB;
      [XMLExcludeElement]
      FVertexbuffer : TVertexBuffer;
      [XMLExcludeElement]
      FIndexBuffer : TDictionary<RLoDDependency, RTuple<cardinal, TIndexbuffer>>;
      [XMLExcludeElement]
      FQuadTree : TQuadTreeNode;

      FScale, FPosition : RVector3;
      [XMLExcludeElement]
      FShadingReduction : single;
      [XMLExcludeElement]
      FGridData : ARawData;
      [XMLExcludeElement]
      FGridSize : Integer;
      [XMLIncludeElement]
      FTextureSplits : byte;
      FChunkTextures : TUltimateObjectList<TChunkTexture>;
      procedure setGridData(GridData : ASaveRawData);
      function getGridData() : ASaveRawData;
      /// <summary> Only for saving an loading. </summary>
      [XMLIncludeElement]
      [XMLRawData]
      property GridData : ASaveRawData read getGridData write setGridData;

      constructor Create(Scene : TRenderManager);
      procedure GridDataToVertexbuffer(); overload;
      procedure GridDataToVertexbuffer(SubRect : TRect); overload;

      procedure GridActionNodeToVertexbuffer(x, y : Integer);
      procedure GridActionComputeNormal(x, y : Integer);
      procedure GridActionSmoothNormal(x, y : Integer);
      procedure GridActionSmoothHeight(x, y : Integer);
      procedure DoGridAction(Action : ProcGridAction); overload;
      procedure DoGridAction(SubRect : TRect; Action : ProcGridAction); overload;

      procedure BuildQuadtree;
      procedure GridDataEvaluation;
      procedure ResetTextures;

      /// <summary> Out of range indizes will be clamped. </summary>
      function getGridNode(x, y : Integer) : RRawNode;
      function GridNodeToVertex(x, y : Integer) : RVertexPositionTextureNormalTangentBinormal;
      function GridNodeSize : single;
      function IndexToNormal(x, y : Integer) : RVector3; overload;
      function IndexToNormal(xy : RIntVector2) : RVector3; overload;
      function IndexToPosition(x, y : Integer) : RVector3; overload;
      function IndexToPosition(xy : RIntVector2) : RVector3; overload;
      /// <summary> Get Node-Index of the Quad within Worldposition. </summary>
      function PositionToIndex(pos : RVector3) : RIntVector2;
      function PositionToRelativeCoord(pos : RVector3; Clamp : boolean = True) : RVector2;

      function getIndexbuffer(LoDDependency : RLoDDependency) : RTuple<cardinal, TIndexbuffer>;
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
      procedure RenderShadowContribution(RenderContext : TRenderContext);
      procedure RenderTile(StartIndex : Integer; LoDDependency : RLoDDependency);

      // for editor / debug
      procedure RenderBorders(ChunkID : Integer);

      procedure SetGridSize(Size : Integer);
      procedure setTextureSplits(const Value : byte);
    public
      /// <summary> Miscellaneous Settings. </summary>
      TerrainSettings : RTerrainSettings;
      /// <summary> The center of the Terrain. The pivot is at Scale*(0.5,0.5,0.5). </summary>
      [XMLExcludeElement]
      property Position : RVector3 read FPosition write FPosition;
      /// <summary> Describes the dimension of the Terrain in each axis. </summary>
      [XMLExcludeElement]
      property Scale : RVector3 read FScale write FScale;
      /// <summary> How many splits are made for the terrain texture. 0 -> 1 Texture, 1 -> 4 Textures, 2 -> 16 Textures </summary>
      [XMLExcludeElement]
      property TextureSplits : byte read FTextureSplits write setTextureSplits;
      /// <summary> How much nodes contains the grid at each axis. </summary>
      [XMLExcludeElement]
      property Size : Integer read FGridSize;
      property ShadingReduction : single read FShadingReduction write FShadingReduction;
      /// <summary> Create a plane with n(Size) nodes at each axis. </summary>
      constructor CreateEmpty(Scene : TRenderManager; Size : Integer);
      /// <summary> Generates a heightmap from the red-Channel of the bitmap. Bitmap must be Power of 2 Sized. </summary>
      constructor CreateFromGrayscaleTexture(Scene : TRenderManager; Texturfile : string);
      /// <summary> Loads the Terrain from a XML-File. All used Texture must be found under their relative Path to the TexturePath. </summary>
      constructor CreateFromFile(Scene : TRenderManager; TerrainFile : string);
      procedure LoadEmpty(Size : Integer);
      procedure LoadFromFile(TerrainFile : string);
      procedure LoadFromGrayscaleTexture(Texturfile : string);
      procedure LoadFromOBJ(ObjFile : string);
      /// <summary> Returns the point on the surface of the terrain at this Worldcoordinate. if ClampToBorder is true all xz-coordinates are clamped to the Terrainborders.</summary>
      function GetTerrainHeight(Position : RVector2; ClampToBorder : boolean = false; Normal : PRVector3 = nil) : RVector3; overload;
      /// <summary> Returns the point on the surface of the terrain at this Worldcoordinate. Y is ignored. if ClampToBorder is true all xz-coordinates are clamped to the Terrainborders. </summary>
      function GetTerrainHeight(Position : RVector3; ClampToBorder : boolean = false; Normal : PRVector3 = nil) : RVector3; overload;
      /// <summary> Get the point, where the line hit the surface of the terrain. </summary>
      function IntersectRayTerrain(Start, Direction : RVector3; Normal : PRVector3 = nil) : RVector3; overload;
      function IntersectRayTerrain(Ray : RRay; Normal : PRVector3 = nil) : RVector3; overload;
      /// <summary> Saves the Terrain in a XML-File. The Texturechunks are saved at the same location. </summary>
      procedure SaveToFile(TerrainFile : string);
      /// <summary> Saves the terrain to an obj file. </summary>
      procedure SaveToOBJ(ObjFile : string);
      /// <summary> Builds all necessary Data for Geomipmapping and Textureoptimization. Needed after changes to the grid. </summary>
      procedure Optimize;
      function GetBoundingBox() : RAABB; override;
      function GetBoundingSphere() : RSphere; override;
      destructor Destroy; override;
  end;
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  EnumMirrorType = (mtX, mtY);

  /// <summary> Provide methods for manipulate a Terrain. </summary>
  TTerrainEditor = class
    private
      procedure setDiffuse(const Value : TTexture);
      procedure setMaterial(const Value : TTexture);
      procedure setNormal(const Value : TTexture);
    protected
      type
      ProcTerrainEditAction = procedure(x, y : Integer; Brushstrength : single; Center : RVector3) of object;
    var
      FDiffuse, FNormal, FMaterial : TTexture;
      procedure EditActionTransform(x, y : Integer; Brushstrength : single; Center : RVector3);
      procedure EditActionSetHeight(x, y : Integer; Brushstrength : single; Center : RVector3);
      procedure EditActionSmooth(x, y : Integer; Brushstrength : single; Center : RVector3);
      procedure EditActionNoise(x, y : Integer; Brushstrength : single; Center : RVector3);
      procedure EditActionPlane(x, y : Integer; Brushstrength : single; Center : RVector3);
      procedure DoAction(Position : RVector3; Action : ProcTerrainEditAction);
    public
      Terrain : TTerrain;
      Brushcore, Brushedge, Strength, BrushTextureScale : single;
      Alpha : single;
      OverwriteColor, OverwriteMaterial : boolean;
      ExtraColor, ExtraMaterial : RColor;
      // Texture Brush
      property Diffuse : TTexture read FDiffuse write setDiffuse;
      property Normal : TTexture read FNormal write setNormal;
      property Material : TTexture read FMaterial write setMaterial;
      constructor Create(Terrain : TTerrain);
      procedure ClearMap(MapType : EnumMapType);
      procedure Plane(Position : RVector3);
      procedure Smooth(Position : RVector3);
      procedure Transform(Position : RVector3; SetToHeight : boolean = false);
      procedure DrawTexture(Position : RVector3);
      function GetColor(Position : RVector3) : RColor;
      procedure Noise(Position : RVector3);
      procedure PointReflection(MirrorType : EnumMirrorType; InvertDirection : boolean);
      procedure AxisReflection(MirrorType : EnumMirrorType; InvertDirection : boolean);
      procedure Flatten(HeightReference : single);
      destructor Destroy; override;
  end;

  TLinePoolTerrainHelper = class helper for TLinePool
    procedure DrawPolyOnTerrain(Terrain : TTerrain; Polygon : TPolygon; Color : RColor; Samplingrate : single = -1; YEpsilon : single = 0.1);
    procedure DrawMultiPolyOnTerrain(Terrain : TTerrain; Polygon : TMultipolygon; Color : RColor; Samplingrate : single = -1; YEpsilon : single = 0.1);
    procedure DrawLineOnTerrain(Terrain : TTerrain; StartPosition, EndPosition : RVector3; Color : RColor; Samplingrate : single = -1; YEpsilon : single = 0.1); overload;
    procedure DrawLineOnTerrain(Terrain : TTerrain; StartPosition, EndPosition : RVector3; StartColor, EndColor : RColor; Samplingrate : single = -1; YEpsilon : single = 0.1); overload;
    procedure DrawCircleOnTerrain(Terrain : TTerrain; Position : RVector3; Radius : single; Color : RColor; Samplingrate : Integer = 64); overload;
    procedure DrawCircleOnTerrain(Terrain : TTerrain; Position : RVector3; Radius, Radius2 : single; Color : RColor; Rings : Integer; Samplingrate : Integer = 64); overload;
    procedure DrawFixedGridOnTerrain(Terrain : TTerrain; Position : RVector3; Radius : single; Color : RColor; Samplingrate : single = 1);
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  UseGeoMipMapping : boolean = True;

implementation

function CosFactor(Faktor : single) : single;
begin
  Result := (1 - cos(Faktor * 3.14159265)) * 0.5;
end;

{ TChunkTexture }

constructor TChunkTexture.Create(ChunkID : cardinal);
begin
  self.CreateTextures(TChunkTexture.DEFAULTSIZE);
  self.ChunkID := ChunkID;
end;

procedure TChunkTexture.ClearTexture(MapType : EnumMapType; Value : RColor);
begin
  case MapType of
    mtDiffuse :
      begin
        FDiffusemap.Free;
        FDiffusemap := TTexture.CreateTexture(FSize, FSize, 1, [usReadable, usWriteable], EnumTextureFormat.tfA8R8G8B8, GFXD.Device3D);
        Value.A := 1.0;
        FDiffusemap.Fill<cardinal>(Value.AsCardinal);
      end;
    mtNormal :
      begin
        FNormalmap.Free;
        FNormalmap := TTexture.CreateTexture(FSize, FSize, 1, [usReadable, usWriteable], EnumTextureFormat.tfA8R8G8B8, GFXD.Device3D);
        Value.A := 1.0;
        FNormalmap.Fill<cardinal>(Value.AsCardinal);
      end;
    mtMaterial :
      begin
        FMaterialmap.Free;
        FMaterialmap := TTexture.CreateTexture(FSize, FSize, 1, [usReadable, usWriteable], EnumTextureFormat.tfA8R8G8B8, GFXD.Device3D);
        FMaterialmap.Fill<cardinal>(Value.AsCardinal);
      end;
  end;
  FEditable[MapType] := True;
end;

constructor TChunkTexture.Create(FileBase, DiffusemapFile, NormalMapFile, SpecularMapFile : string; ChunkID : cardinal);
begin
  Create(ChunkID);
  SetTexture(FormatDateiPfad(FileBase + DiffusemapFile), 0);
  SetTexture(FormatDateiPfad(FileBase + NormalMapFile), 1);
  SetTexture(FormatDateiPfad(FileBase + SpecularMapFile), 2);
end;

procedure TChunkTexture.CreateTextures(Size : Integer);
begin
  FSize := Size;
  ClearTexture(mtDiffuse, $FF808080);
  ClearTexture(mtNormal, $FF8080FF);
  ClearTexture(mtMaterial, $00404000);
end;

procedure TChunkTexture.SetTexture(FilePath : string; Index : Integer);
var
  target : ^TTexture;
  temp : TTexture;
begin
  case index of
    0 : target := @self.FDiffusemap;
    1 : target := @self.FNormalmap;
    2 : target := @self.FMaterialmap;
  else
    assert(false, 'TChunkTexture.SetTexture: Index out of Range');
    target := nil;
  end;
  if assigned(target) then
  begin
    temp := TTexture.CreateTextureFromFile(FilePath, GFXD.Device3D, mhGenerate, True);
    if assigned(temp) then
    begin
      target^ := temp;
      if TextureSize = 0 then FSize := target^.Width
      else target^.Resize(TextureSize, TextureSize);
      FEditable[EnumMapType(index)] := false;
    end;
  end;
end;

procedure TChunkTexture.CustomAfterXMLCreate;
begin
  inherited;
  SetTexture(ChangeFileExt(FFileName, Inttostr(ChunkID) + 'Diffuse.png'), 0);
  SetTexture(ChangeFileExt(FFileName, Inttostr(ChunkID) + 'Normal.png'), 1);
  SetTexture(ChangeFileExt(FFileName, Inttostr(ChunkID) + 'Material.png'), 2);
end;

constructor TChunkTexture.CustomXMLCreate(Node : TXMLNode; CustomData : array of TObject);
begin
  inherited;
  FFileName := TObjectWrapper<string>(CustomData[0]).Value;
end;

procedure TChunkTexture.CustomXMLSave(Node : TXMLNode; CustomData : array of TObject);
begin
  inherited;
  FFileName := TString(CustomData[0]).Value;
  if FEditable[mtDiffuse] then FDiffusemap.SaveToFile(ChangeFileExt(FFileName, Inttostr(ChunkID) + 'Diffuse.png'), tfPNG);
  if FEditable[mtNormal] then FNormalmap.SaveToFile(ChangeFileExt(FFileName, Inttostr(ChunkID) + 'Normal.png'), tfPNG);
  if FEditable[mtMaterial] then FMaterialmap.SaveToFile(ChangeFileExt(FFileName, Inttostr(ChunkID) + 'Material.png'), tfPNG);
end;

destructor TChunkTexture.Destroy;
begin
  FDiffusemap.Free;
  FNormalmap.Free;
  FMaterialmap.Free;
  inherited;
end;

procedure TChunkTexture.MakeEditable;
var
  temp : TTexture;
begin
  if not FEditable[mtDiffuse] then
  begin
    if assigned(FDiffusemap) then
    begin
      temp := FDiffusemap.CloneAndConvert(tfA8R8G8B8);
      FDiffusemap.Free;
      FDiffusemap := temp;
      FDiffusemap.MakeLockable;
      FDiffusemap.DisableMipLevels;
      FEditable[mtDiffuse] := True;
    end;
  end;
  if not FEditable[mtNormal] then
  begin
    if assigned(FNormalmap) then
    begin
      temp := FNormalmap.CloneAndConvert(tfA8R8G8B8);
      FNormalmap.Free;
      FNormalmap := temp;
      FNormalmap.MakeLockable;
      FNormalmap.DisableMipLevels;
      FEditable[mtNormal] := True;
    end;
  end;
  if not FEditable[mtMaterial] then
  begin
    if assigned(FMaterialmap) then
    begin
      temp := FMaterialmap.CloneAndConvert(tfA8R8G8B8);
      FMaterialmap.Free;
      FMaterialmap := temp;
      FMaterialmap.MakeLockable;
      FMaterialmap.DisableMipLevels;
      FEditable[mtMaterial] := True;
    end;
  end;
end;

procedure TChunkTexture.Resize(Size : cardinal);
begin
  CreateTextures(Size);
end;

{ TTerrain }

procedure TTerrain.BuildQuadtree;
begin
  FQuadTree.Free;
  FQuadTree := TQuadTreeNode.Create(Rect(0, 0, Size - 1, Size - 1), FGridData, self, nil);
  FQuadTree.SetChunkTextures(FChunkTextures);
end;

constructor TTerrain.Create(Scene : TRenderManager);
begin
  inherited Create(Scene);
  TerrainSettings.Geomipmapdistanceerror := 0.02;
  TerrainSettings.Geomipmapnormalerror := 3.3;
  FIndexBuffer := TDictionary < RLoDDependency, RTuple < cardinal, TIndexbuffer >>.Create();
  FScale := RVector3.Create(100, 30, 100);
  TextureSplits := 1;
  FChunkTextures := TUltimateObjectList<TChunkTexture>.Create();
  Scene.Eventbus.Subscribe(geDrawOpaqueShadowmap, RenderShadowContribution);
end;

constructor TTerrain.CreateEmpty(Scene : TRenderManager; Size : Integer);
begin
  Create(Scene);
  LoadEmpty(Size);
end;

constructor TTerrain.CreateFromFile(Scene : TRenderManager; TerrainFile : string);
begin
  Create(Scene);
  LoadFromFile(TerrainFile);
end;

procedure TTerrain.LoadEmpty(Size : Integer);
begin
  SetGridSize(Size);
  ResetTextures();
  GridDataEvaluation;
end;

procedure TTerrain.LoadFromFile(TerrainFile : string);
var
  Str : TObjectWrapper<string>;
begin
  if not FileExists(TerrainFile) then raise Exception.Create('TTerrain.CreateFromFile: Terrainfile ' + TerrainFile + ' does not exist!');
  Str := TObjectWrapper<string>.Create(TerrainFile);
  FChunkTextures.Clear;
  HXMLSerializer.LoadObjectFromFile(self, TerrainFile, [Str]);
  Str.Free;
  if FChunkTextures.Count <= 0 then ResetTextures;
  GridDataEvaluation;
end;

constructor TTerrain.CreateFromGrayscaleTexture(Scene : TRenderManager; Texturfile : string);
begin
  Create(Scene);
  LoadFromGrayscaleTexture(Texturfile);
end;

procedure TTerrain.LoadFromGrayscaleTexture(Texturfile : string);
var
  x, y : Integer;
  HeightMapTex : TTexture;
begin
  HeightMapTex := TTexture.CreateTextureFromFile(Texturfile, GFXD.Device3D, mhSkip, false);
  assert(assigned(HeightMapTex));
  HeightMapTex.MakeLockable;
  // Grundgerüst erstellen
  SetGridSize(Min(HeightMapTex.Width, HeightMapTex.Height));
  // Höhen aus der Textur auslesen
  HeightMapTex.Lock;
  for y := 0 to Size - 1 do
    for x := 0 to Size - 1 do
    begin
      FGridData[x, y].Position.y := RColor(HeightMapTex.getTexel<cardinal>(x, y, amClamp)).R - 0.5;
    end;
  HeightMapTex.Unlock;
  HeightMapTex.Free;

  DoGridAction(GridActionSmoothHeight);
  GridDataEvaluation;
end;

destructor TTerrain.Destroy;
var
  Indextuple : RTuple<cardinal, TIndexbuffer>;
begin
  for Indextuple in FIndexBuffer.Values do Indextuple.b.Free;
  FVertexbuffer.Free;
  FIndexBuffer.Free;
  FQuadTree.Free;
  FChunkTextures.Free;
  Scene.Eventbus.Unsubscribe(geDrawOpaqueShadowmap, RenderShadowContribution);
  inherited;
end;

procedure TTerrain.DoGridAction(Action : ProcGridAction);
begin
  DoGridAction(Rect(0, 0, Size - 1, Size - 1), Action);
end;

procedure TTerrain.DoGridAction(SubRect : TRect; Action : ProcGridAction);
var
  x, y : Integer;
begin
  SubRect.Left := Max(0, SubRect.Left);
  SubRect.Top := Max(0, SubRect.Top);
  SubRect.Right := Min(Size - 1, SubRect.Right);
  SubRect.Bottom := Min(Size - 1, SubRect.Bottom);
  for x := SubRect.Left to SubRect.Right do
    for y := SubRect.Top to SubRect.Bottom do Action(x, y);
end;

function TTerrain.GetBoundingBox : RAABB;
begin
  Result := FVirtualBoundingBox.Scale(Scale).Translate(Position);
end;

function TTerrain.GetBoundingSphere : RSphere;
begin
  Result := GetBoundingBox.ToSphere;
end;

function TTerrain.getGridData : ASaveRawData;
var
  i, x, y, Size : Integer;
begin
  Size := self.Size;
  setLength(Result, Size);
  for i := 0 to Size - 1 do
      setLength(Result[i], Size);
  for x := 0 to Size - 1 do
    for y := 0 to Size - 1 do
    begin
      Result[x, y].Height := FGridData[x, y].Position.y;
    end;
end;

function TTerrain.getGridNode(x, y : Integer) : RRawNode;
begin
  x := Min(Size - 1, Max(0, x));
  y := Min(Size - 1, Max(0, y));
  Result := FGridData[x, y];
end;

function TTerrain.getIndexbuffer(LoDDependency : RLoDDependency) : RTuple<cardinal, TIndexbuffer>;
var
  ibx, iby, x, y, IBSize, Pow2, TILESIZE : Integer;
  function getNodeIndex(x, y : Integer) : cardinal;
  var
    Pow2, newX, newY : Integer;
  begin
    newX := x;
    newY := y;
    if (x = 0) and (LoDDependency.Middle < LoDDependency.Left) then
    begin
      Pow2 := 1 shl (LoDDependency.Left - 1);
      newY := MapToLowerSampling(y, Pow2);
    end;
    if (x = TILESIZE) and (LoDDependency.Middle < LoDDependency.Right) then
    begin
      Pow2 := 1 shl (LoDDependency.Right - 1);
      newY := MapToLowerSampling(y, Pow2);
    end;
    if (y = 0) and (LoDDependency.Middle < LoDDependency.Top) then
    begin
      Pow2 := 1 shl (LoDDependency.Top - 1);
      newX := MapToLowerSampling(x, Pow2);
    end;
    if (y = TILESIZE) and (LoDDependency.Middle < LoDDependency.Bottom) then
    begin
      Pow2 := 1 shl (LoDDependency.Bottom - 1);
      newX := MapToLowerSampling(x, Pow2);
    end;
    Result := newX + newY * Integer(Size);
  end;

begin
  if not FIndexBuffer.TryGetValue(LoDDependency, Result) then
  begin
    Pow2 := 1 shl (LoDDependency.Middle - 1);
    IBSize := TQuadTreeNode.TILESIZE div (1 shl (LoDDependency.Middle - 1));
    Result.A := sqr(IBSize) * 2;
    Result.b := TIndexbuffer.CreateIndexBuffer(sqr(IBSize) * 6 * SizeOf(cardinal), [usWriteable], ifINDEX32, GFXD.Device3D);
    Result.b.Lock;
    TILESIZE := IBSize * Pow2;
    x := 0;
    ibx := 0;
    while (ibx <= IBSize - 1) do
    begin
      y := 0;
      iby := 0;
      while (iby <= IBSize - 1) do
      begin
        Result.b.setElement<cardinal>((ibx + iby * IBSize) * 6 + 0, getNodeIndex(x, y));
        Result.b.setElement<cardinal>((ibx + iby * IBSize) * 6 + 1, getNodeIndex(x, (y + Pow2)));
        Result.b.setElement<cardinal>((ibx + iby * IBSize) * 6 + 2, getNodeIndex((x + Pow2), y));
        Result.b.setElement<cardinal>((ibx + iby * IBSize) * 6 + 3, getNodeIndex((x + Pow2), y));
        Result.b.setElement<cardinal>((ibx + iby * IBSize) * 6 + 4, getNodeIndex(x, (y + Pow2)));
        Result.b.setElement<cardinal>((ibx + iby * IBSize) * 6 + 5, getNodeIndex((x + Pow2), (y + Pow2)));
        inc(y, Pow2);
        inc(iby);
      end;
      inc(x, Pow2);
      inc(ibx);
    end;
    Result.b.Unlock;
    FIndexBuffer.Add(LoDDependency, Result);
  end;
end;

procedure TTerrain.GridDataToVertexbuffer;
begin
  GridDataToVertexbuffer(Rect(0, 0, Size - 1, Size - 1));
end;

procedure TTerrain.GridDataEvaluation;
begin
  if FVertexbuffer = nil then FVertexbuffer := TVertexBuffer.CreateVertexBuffer(Size * Size * SizeOf(RVertexPositionTextureNormalTangentBinormal), [usWriteable], GFXD.Device3D);
  FVirtualBoundingBox := RAABB.Create(RVector3.EMPTY, RVector3.EMPTY);
  DoGridAction(GridActionComputeNormal);
  DoGridAction(GridActionSmoothNormal);
  GridDataToVertexbuffer;
  BuildQuadtree;
  if FVirtualBoundingBox.Min.IsEmpty then FVirtualBoundingBox := RAABB.Create(RVector3.Create(-0.5), RVector3.Create(0.5));
end;

procedure TTerrain.GridDataToVertexbuffer(SubRect : TRect);
begin
  FVertexbuffer.Lock;
  DoGridAction(SubRect, GridActionNodeToVertexbuffer);
  FVertexbuffer.Unlock;
end;

function TTerrain.GridNodeSize : single;
begin
  Result := (FScale.x * 2) / Size;
end;

function TTerrain.GridNodeToVertex(x, y : Integer) : RVertexPositionTextureNormalTangentBinormal;
begin
  Result.Position := FGridData[x, y].Position;
  Result.Normal := FGridData[x, y].Normal;
  Result.TextureCoordinate := Result.Position.xz + 0.5;
  Result.Tangent := -Result.Normal.Cross(RVector3.UNITX).Normalize; // -RVector3.UNITX;
  Result.Binormal := Result.Normal.Cross(Result.Tangent).Normalize; // -RVector3.UNITZ;
end;

function TTerrain.IndexToNormal(x, y : Integer) : RVector3;
begin
  Result := getGridNode(x, y).Normal / FScale;
end;

function TTerrain.IndexToNormal(xy : RIntVector2) : RVector3;
begin
  Result := IndexToNormal(xy.x, xy.y);
end;

function TTerrain.IndexToPosition(xy : RIntVector2) : RVector3;
begin
  Result := IndexToPosition(xy.x, xy.y);
end;

function TTerrain.IntersectRayTerrain(Ray : RRay; Normal : PRVector3 = nil) : RVector3;
begin
  Result := IntersectRayTerrain(Ray.Origin, Ray.Direction, Normal);
end;

function TTerrain.IntersectRayTerrain(Start, Direction : RVector3; Normal : PRVector3 = nil) : RVector3;
const
  MAXSTEPS = 1000;
  SUBSTEPS = 20;
var
  Step, i : Integer;
begin
  Result := RVector3.Create(0, 0, 0);
  Direction.InNormalize;
  Start := Start + Direction * (Start.Distance(Position) - (FScale.length / 2));
  Direction.length := GridNodeSize;
  for Step := 0 to MAXSTEPS - 1 do
  begin
    Start := Start + Direction;
    Result := GetTerrainHeight(Start, false, Normal);
    if Result.y >= Start.y then
    begin
      Start := Start - Direction;
      Direction := Direction / SUBSTEPS;
      for i := 0 to SUBSTEPS do
      begin
        Start := Start + Direction;
        Result := GetTerrainHeight(Start, false, Normal);
        if Result.y >= Start.y then break;
      end;
      exit;
    end;
  end;
end;

procedure TTerrain.Optimize;
begin
  GridDataEvaluation;
end;

function TTerrain.IndexToPosition(x, y : Integer) : RVector3;
begin
  Result := getGridNode(x, y).Position * FScale + FPosition;
end;

function TTerrain.PositionToIndex(pos : RVector3) : RIntVector2;
var
  Position : RVector2;
begin
  pos.x := pos.x / FScale.x - FPosition.x;
  pos.z := pos.z / FScale.z - FPosition.z;
  Position := RVector2.Create(pos.x, pos.z);
  Position := RVector2.Min(RVector2.Max(Position, RVector2.Create(-0.5, -0.5)), RVector2.Create(0.5, 0.5));
  // auf Index gehen
  Result.x := Min(Max(trunc((Position.x + 0.5) * (Size - 1)), 0), Size - 1);
  Result.y := Min(Max(trunc((Position.y + 0.5) * (Size - 1)), 0), Size - 1);
end;

function TTerrain.PositionToRelativeCoord(pos : RVector3; Clamp : boolean) : RVector2;
var
  Position : RVector2;
begin
  pos.x := pos.x / FScale.x - FPosition.x;
  pos.z := pos.z / FScale.z - FPosition.z;
  Position := RVector2.Create(pos.x, pos.z);
  if Clamp then
      Position := RVector2.Min(RVector2.Max(Position, RVector2.Create(-0.5, -0.5)), RVector2.Create(0.5, 0.5));
  Result := Position + 0.5;
end;

function TTerrain.GetTerrainHeight(Position : RVector2; ClampToBorder : boolean; Normal : PRVector3) : RVector3;
var
  xz, xz2 : RIntVector2;
  U, V : single;
  NodePos1, NodePos2, pos : RVector3;
  function PreventZero(s : single) : single;
  begin
    Result := s;
    if s = 0 then Result := 0.001;
  end;

begin
  xz := PositionToIndex(RVector3.Create(Position.x, 0, Position.y));
  xz2 := xz + RIntVector2.Create(1, 1);
  NodePos1 := IndexToPosition(xz.x, xz.y).SetY(0);
  NodePos2 := IndexToPosition(xz2.x, xz2.y).SetY(0);
  pos := RVector3.Create(Position.x, 0, Position.y);
  U := HMath.saturate((pos.x - NodePos1.x) / PreventZero(NodePos2.x - NodePos1.x));
  V := HMath.saturate((pos.z - NodePos1.z) / PreventZero(NodePos2.z - NodePos1.z));
  if 1 > U + V then Result := RVector3.BaryCentric(IndexToPosition(xz), IndexToPosition(xz + RIntVector2.Create(1, 0)), IndexToPosition(xz + RIntVector2.Create(0, 1)), U, V)
  else Result := RVector3.BaryCentric(IndexToPosition(xz2), IndexToPosition(xz2 - RIntVector2.Create(1, 0)), IndexToPosition(xz2 - RIntVector2.Create(0, 1)), 1 - U, 1 - V);
  if not ClampToBorder then
  begin
    Result.x := Position.x;
    Result.z := Position.y;
  end;
  if Normal <> nil then
  begin
    if 1 > U + V then Normal^ := RVector3.BaryCentric(IndexToNormal(xz), IndexToNormal(xz + RIntVector2.Create(1, 0)), IndexToNormal(xz + RIntVector2.Create(0, 1)), U, V).Normalize
    else Normal^ := RVector3.BaryCentric(IndexToNormal(xz2), IndexToNormal(xz2 - RIntVector2.Create(1, 0)), IndexToNormal(xz2 - RIntVector2.Create(0, 1)), 1 - U, 1 - V).Normalize;
  end;
end;

function TTerrain.GetTerrainHeight(Position : RVector3; ClampToBorder : boolean; Normal : PRVector3) : RVector3;
begin
  Result := GetTerrainHeight(Position.xz, ClampToBorder, Normal);
end;

procedure TTerrain.GridActionComputeNormal(x, y : Integer);
var
  tempNormal : RVector3;
begin
  tempNormal := RVector3.ZERO;
  tempNormal := tempNormal + (getGridNode(x - 1, y).Position - getGridNode(x, y).Position).Cross(getGridNode(x, y - 1).Position - getGridNode(x, y).Position).Normalize;
  tempNormal := tempNormal + (getGridNode(x, y - 1).Position - getGridNode(x, y).Position).Cross(getGridNode(x + 1, y).Position - getGridNode(x, y).Position).Normalize;
  tempNormal := tempNormal + (getGridNode(x + 1, y).Position - getGridNode(x, y).Position).Cross(getGridNode(x, y + 1).Position - getGridNode(x, y).Position).Normalize;
  tempNormal := tempNormal + (getGridNode(x, y + 1).Position - getGridNode(x, y).Position).Cross(getGridNode(x - 1, y).Position - getGridNode(x, y).Position).Normalize;
  FGridData[x, y].Normal := -tempNormal.Normalize;
end;

procedure TTerrain.GridActionNodeToVertexbuffer(x, y : Integer);
var
  Vertex : RVertexPositionTextureNormalTangentBinormal;
begin
  Vertex := GridNodeToVertex(x, y);
  FVertexbuffer.setElement(x + y * Integer(Size), Vertex);

  if FVirtualBoundingBox.Min.IsEmpty then FVirtualBoundingBox := RAABB.Create(Vertex.Position)
  else FVirtualBoundingBox.Extend(Vertex.Position);
end;

procedure TTerrain.GridActionSmoothHeight(x, y : Integer);
var
  dx, dy : Integer;
  s : single;
begin
  s := 0;
  for dx := -1 to 1 do
    for dy := -1 to 1 do
    begin
      s := s + getGridNode(x + dx, y + dy).Position.y;
    end;
  FGridData[x, y].Position.y := s / 9;
end;

procedure TTerrain.GridActionSmoothNormal(x, y : Integer);
var
  tempNormal : RVector3;
  dx, dy : Integer;
begin
  tempNormal := RVector3.ZERO;
  for dx := -1 to 1 do
    for dy := -1 to 1 do
    begin
      tempNormal := tempNormal + getGridNode(x + dx, y + dy).Normal;
    end;
  FGridData[x, y].Normal := tempNormal.Normalize;
end;

procedure TTerrain.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
var
  World : RMatrix;
  RenderFlags : SetDefaultShaderFlags;
  Shader : TShader;
begin
  inherited;
  World := RMatrix.CreateTranslation(FPosition) * RMatrix.CreateScaling(FScale);

  GFXD.Device3D.SetVertexDeclaration(RVertexPositionTextureNormalTangentBinormal.BuildVertexdeclaration);
  GFXD.Device3D.SetStreamSource(0, FVertexbuffer, 0, SizeOf(RVertexPositionTextureNormalTangentBinormal));

  if TerrainSettings.DrawWireFramed then GFXD.Device3D.SetRenderState(EnumRenderstate.rsFILLMODE, fmWireframe);
  RenderFlags := [sfDiffuseTexture, sfTextureTransform, sfNormalmapping, sfMaterial, sfMaterialTexture, sfAllowLighting];
  if RenderContext.ShadowMapping.Enabled then RenderFlags := RenderFlags + [sfShadowMapping];

  GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amClamp);
  Shader := Scene.CreateAndSetDefaultShader(RenderFlags);
  if not RenderContext.DrawGBuffer and RenderContext.ShadowMapping.Enabled then RenderContext.SetShadowmapping(Shader);
  Shader.SetWorld(World);
  Shader.SetShaderConstant<single>(dcSpecularpower, 0);
  Shader.SetShaderConstant<single>(dcSpecularintensity, 1);
  Shader.SetShaderConstant<single>(dcShadingReduction, FShadingReduction);

  FQuadTree.RenderTiles(RenderContext, True);

  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TTerrain.RenderShadowContribution(RenderContext : TRenderContext);
var
  Shader : TShader;
  ShaderFlags : SetDefaultShaderFlags;
  World : RMatrix;
begin
  if CastsNoShadow or (Scene.MainDirectionalLight = nil) then exit;

  ShaderFlags := [sfDiffuseTexture, sfNormalmapping, sfMaterial, sfMaterialTexture, sfTextureTransform];
  GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amClamp);
  GFXD.Device3D.SetRenderState(rsCULLMODE, cmCW);
  Shader := Scene.CreateAndSetDefaultShadowShader(ShaderFlags);

  Shader.SetShaderConstant<RVector3>(dcLightPosition, Scene.Camera.Position);

  World := RMatrix.CreateTranslation(FPosition) * RMatrix.CreateScaling(FScale);

  GFXD.Device3D.SetVertexDeclaration(RVertexPositionTextureNormalTangentBinormal.BuildVertexdeclaration);
  GFXD.Device3D.SetStreamSource(0, FVertexbuffer, 0, SizeOf(RVertexPositionTextureNormalTangentBinormal));

  Shader.SetWorld(World);

  FQuadTree.RenderTiles(RenderContext, false);

  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TTerrain.RenderBorders(ChunkID : Integer);
const
  LAYERS = 10;
var
  chunkRect : RRect;
  i : Integer;
  y, s : single;
begin
  if FChunkTextures.Extra.IsValidIndex(ChunkID) then
  begin
    chunkRect := FChunkTextures[ChunkID].FRect;
    for i := 0 to LAYERS - 1 do
    begin
      s := i / (LAYERS - 1);
      y := (Scale.y / 5) * s;
      LinePool.AddRect(IndexToPosition(chunkRect.Left, chunkRect.Top) + RVector3.Create(0, y, 0),
        IndexToPosition(chunkRect.Right, chunkRect.Top) + RVector3.Create(0, y, 0),
        IndexToPosition(chunkRect.Right, chunkRect.Bottom) + RVector3.Create(0, y, 0),
        IndexToPosition(chunkRect.Left, chunkRect.Bottom) + RVector3.Create(0, y, 0), RColor(RColor.CGREEN).SetAlphaF(1 - s));
    end;
  end;
end;

procedure TTerrain.RenderTile(StartIndex : Integer; LoDDependency : RLoDDependency);
var
  VertexCount : Integer;
  IndexBuffer : RTuple<cardinal, TIndexbuffer>;
begin
  VertexCount := TQuadTreeNode.TILESIZE * (Size + 1);
  IndexBuffer := getIndexbuffer(LoDDependency);
  GFXD.Device3D.SetIndices(IndexBuffer.b);
  GFXD.Device3D.DrawIndexedPrimitive(EnumPrimitveType.ptTrianglelist, StartIndex, 0, VertexCount, 0, IndexBuffer.A);
  FDrawCalls := FDrawCalls + 1;
  FDrawnTriangles := FDrawnTriangles + Integer(IndexBuffer.A);
end;

procedure TTerrain.ResetTextures;
var
  i : Integer;
begin
  if not assigned(FChunkTextures) then exit;
  FChunkTextures.Clear;
  for i := 0 to (sqr(1 shl TextureSplits) - 1) do FChunkTextures.Add(TChunkTexture.Create(i))
end;

procedure TTerrain.SaveToFile(TerrainFile : string);
var
  FileName : TString;
begin
  FileName := TString.Create(TerrainFile);
  HXMLSerializer.SaveObjectToFile(self, TerrainFile, [FileName]);
  FileName.Free;
end;

procedure TTerrain.LoadFromOBJ(ObjFile : string);
  function PosToIndex(pos : RVector2) : RIntVector2;
  var
    Position : RVector2;
  begin
    pos.x := pos.x / FScale.x - FPosition.x;
    pos.y := pos.y / FScale.z - FPosition.z;
    Position := pos;
    Position := RVector2.Min(RVector2.Max(Position, RVector2.Create(-0.5, -0.5)), RVector2.Create(0.5, 0.5));
    Result.x := Min(Max(round((Position.x + 0.5) * (Size - 1)), 0), Size - 1);
    Result.y := Min(Max(round((Position.y + 0.5) * (Size - 1)), 0), Size - 1);
  end;

var
  Content : string;
  Lines, Vector : TArray<string>;
  i : Integer;
  Position : RVector3;
  Index : RIntVector2;
begin
  Content := HFileIO.ReadAllText(ObjFile);
  Lines := Content.Split([sLineBreak]);
  for i := 0 to length(Lines) - 1 do
    if Lines[i].StartsWith('v') then
    begin
      Vector := Lines[i].Replace(',', EngineFloatFormatSettings.DecimalSeparator).Replace('.', EngineFloatFormatSettings.DecimalSeparator).Split([' '], TStringSplitOptions.ExcludeEmpty);
      Position.x := StrToFloat(Vector[1], EngineFloatFormatSettings);
      Position.y := StrToFloat(Vector[3], EngineFloatFormatSettings);
      Position.z := StrToFloat(Vector[2], EngineFloatFormatSettings);

      index := PosToIndex(Position.xz);
      FGridData[index.x, index.y].Position.y := (Position.y - self.Position.y) / Scale.y;
    end;
  GridDataEvaluation;
end;

procedure TTerrain.SaveToOBJ(ObjFile : string);
var
  f : textfile;
  x, y, v1, v2, v3 : Integer;
  Position, Normal : RVector3;
  TexCoord : RVector2;
begin
  AssignFile(f, ObjFile);
  Rewrite(f);
  for x := 0 to Size - 1 do
    for y := 0 to Size - 1 do
    begin
      Position := IndexToPosition(x, y);
      Normal := IndexToNormal(x, y);
      TexCoord := RVector2.Create(x / (Size - 1), y / (Size - 1));
      writeln(f, 'v ', Position.x, ' ', Position.y, ' ', Position.z);
      writeln(f, 'vt ', TexCoord.x, ' ', TexCoord.y);
      writeln(f, 'vn ', Normal.x, ' ', Normal.y, ' ', Normal.z);
    end;
  for x := 0 to Size - 2 do
    for y := 0 to Size - 2 do
    begin
      // add quad spanned by vertex, vertex index starts at 1
      v1 := x + y * Size + 1;
      v2 := x + (y + 1) * Size + 1;
      v3 := x + 1 + y * Size + 1;
      writeln(f, 'f ', v1, '/', v1, '/', v1, ' ', v2, '/', v2, '/', v2, ' ', v3, '/', v3, '/', v3);
      v1 := x + 1 + (y + 1) * Size + 1;
      v2 := x + 1 + y * Size + 1;
      v3 := x + (y + 1) * Size + 1;
      writeln(f, 'f ', v1, '/', v1, '/', v1, ' ', v2, '/', v2, '/', v2, ' ', v3, '/', v3, '/', v3);
    end;
  CloseFile(f);
end;

procedure TTerrain.setGridData(GridData : ASaveRawData);
var
  x, y : Integer;
begin
  SetGridSize(length(GridData));
  for x := 0 to Size - 1 do
    for y := 0 to Size - 1 do
    begin
      FGridData[x, y].Position.y := GridData[x, y].Height;
    end;
end;

procedure TTerrain.SetGridSize(Size : Integer);
var
  i, x, y : Integer;
begin
  if Naechste2erPotenz(Size) = Size then Size := Size + 1
  else Size := Naechste2erPotenz(Size) shr 1 + 1;
  FreeAndNil(FVertexbuffer);
  setLength(FGridData, Size);
  FGridSize := Size;
  for i := 0 to Size - 1 do setLength(FGridData[i], Size);
  for x := 0 to Size - 1 do
    for y := 0 to Size - 1 do
    begin
      FGridData[x, y].Position := RVector3.Create((x / (Size - 1)) - 0.5, 0.0, (y / (Size - 1)) - 0.5);
      FGridData[x, y].Normal := RVector3.Create(0, 1, 0);
    end;
end;

procedure TTerrain.setTextureSplits(const Value : byte);
begin
  FTextureSplits := Value;
  ResetTextures;
  if assigned(FQuadTree) then FQuadTree.SetChunkTextures(FChunkTextures);
end;

{ TTerrain.TQuadTreeNode }

function TTerrain.TQuadTreeNode.CheckVisibility(Cam : TCamera) : boolean;
var
  MinMaxBox : RAABB;
begin
  MinMaxBox := FBoundingBox;
  Result := Cam.IsAABBVisible(MinMaxBox);
end;

procedure TTerrain.TQuadTreeNode.ComputeLoDErrors;
var
  i : Integer;
  UrData, Data : ARawData;
  function getData : ARawData;
  var
    i : Integer;
  begin
    setLength(Result, FTile.Width);
    for i := 0 to length(Result) - 1 do
    begin
      Result[i] := Copy(FData[FTile.Left + i], FTile.Top, FTile.Height);
    end;
  end;
  procedure LoDDown(Level : Integer);
  var
    x, y, ux, ux2, uy, uy2 : Integer;
    U, V : single;
  begin
    Level := 1 shl Level;
    for x := 0 to length(Data) - 1 do
    begin
      if x mod Level = 0 then continue;
      ux := x - (x mod Level);
      ux2 := Min(ux + Level, length(Data) - 1);
      if ux = ux2 then ux := ux - Level;
      for y := 0 to length(Data[x]) - 1 do
      begin
        if y mod Level = 0 then continue;
        uy := y - (y mod Level);
        uy2 := Min(uy + Level, length(Data) - 1);
        if uy = uy2 then uy := uy - Level;
        U := (x - ux) / Level;
        V := (y - uy) / Level;
        // true if point lies in top left triangle of the quad, otherwise in the right bottom triangle
        if 1 < U + V then
        begin
          Data[x, y].Position := RVector3.BaryCentric(Data[ux, uy].Position, Data[ux2, uy].Position, Data[ux, uy2].Position, U, V);
          Data[x, y].Normal := RVector3.BaryCentric(Data[ux, uy].Normal, Data[ux2, uy].Normal, Data[ux, uy2].Normal, U, V).Normalize;
        end
        else
        begin
          Data[x, y].Position := RVector3.BaryCentric(Data[ux2, uy2].Position, Data[ux, uy2].Position, Data[ux2, uy].Position, 1 - U, 1 - V);
          Data[x, y].Normal := RVector3.BaryCentric(Data[ux2, uy2].Normal, Data[ux, uy2].Normal, Data[ux2, uy].Normal, 1 - U, 1 - V).Normalize;
        end;
      end;
    end;
  end;
  function getError : single;
  var
    x, y : Integer;
  begin
    Result := 0;
    for x := 0 to length(Data) - 1 do
      for y := 0 to length(Data[x]) - 1 do
      begin
        Result := Result + sqr(UrData[x, y].Position.Distance(Data[x, y].Position)) + sqr(UrData[x, y].Normal.Dot(Data[x, y].Normal) - 1);
      end;
  end;

begin
  UrData := getData;
  Data := getData;
  FLoDError.Clear;
  for i := 1 to Log2Aufgerundet(TILESIZE) + 1 do
  begin
    FLoDError.Add(getError);
    if Log2Aufgerundet(TILESIZE) + 1 <> i then LoDDown(i);
  end;
end;

constructor TTerrain.TQuadTreeNode.Create(SubRect : TRect; Data : ARawData; Terrain : TTerrain; Parent : TQuadTreeNode; Tilemap : ANodeMap);
var
  i : Integer;
  tempRect : TRect;
begin
  if Tilemap = nil then
  begin
    setLength(Tilemap, SubRect.Width div TILESIZE);
    for i := 0 to length(Tilemap) - 1 do setLength(Tilemap[i], SubRect.Height div TILESIZE);
  end;
  FParent := Parent;
  FTileMap := Tilemap;
  FTile := SubRect;
  FData := Data;
  FTerrain := Terrain;
  FBoundingBox := TileRectToMinMaxBox(SubRect);

  if SubRect.Width > TILESIZE then
  begin
    for i := 0 to 3 do
    begin
      case i of
        0 : tempRect := Rect(SubRect.Left, SubRect.Top, SubRect.Left + SubRect.Width div 2, SubRect.Top + SubRect.Height div 2);
        1 : tempRect := Rect(SubRect.Left + SubRect.Width div 2, SubRect.Top, SubRect.Right, SubRect.Top + SubRect.Height div 2);
        2 : tempRect := Rect(SubRect.Left, SubRect.Top + SubRect.Height div 2, SubRect.Left + SubRect.Width div 2, SubRect.Bottom);
        3 : tempRect := Rect(SubRect.Left + SubRect.Width div 2, SubRect.Top + SubRect.Height div 2, SubRect.Right, SubRect.Bottom);
      end;
      FChildren[i] := TQuadTreeNode.Create(tempRect, Data, Terrain, self, Tilemap);
    end;
  end
  else
  begin
    FLoDError := TList<single>.Create;
    ComputeLoDErrors;
    Tilemap[FTile.Left div TILESIZE, FTile.Top div TILESIZE] := self;
  end;
end;

destructor TTerrain.TQuadTreeNode.Destroy;
var
  i : Integer;
begin
  FLoDError.Free;
  for i := 0 to 3 do FChildren[i].Free;
  inherited;
end;

function TTerrain.TQuadTreeNode.getChildID : byte;
var
  i : Integer;
begin
  if not assigned(FParent) then exit(0)
  else
    for i := 0 to 3 do
      if FParent.FChildren[i] = self then exit(i);
  assert(false, 'TTerrain.TQuadTreeNode.getChildID: This node isn''t a child of its parent.');
  Result := 0;
end;

function TTerrain.TQuadTreeNode.getDepth : byte;
begin
  if not assigned(FParent) then Result := 0
  else Result := FParent.getDepth() + 1;
end;

function TTerrain.TQuadTreeNode.getLayerID : cardinal;
var
  parentLayerID : byte;
  rowCount, newrowCount : Integer;
begin
  Result := 0;
  if not assigned(FParent) then exit
  else
  begin
    parentLayerID := FParent.getLayerID;
    rowCount := 1 shl (self.getDepth - 1);
    newrowCount := 1 shl self.getDepth;
    parentLayerID := (parentLayerID div rowCount) * (newrowCount * 2) + (parentLayerID mod rowCount) * 2;
    case self.getChildID of
      0 : Result := parentLayerID;
      1 : Result := parentLayerID + 1;
      2 : Result := parentLayerID + newrowCount;
      3 : Result := parentLayerID + newrowCount + 1;
    end;
  end;
end;

function TTerrain.TQuadTreeNode.getLoDDependency : RLoDDependency;
begin
  Result.Middle := getLoDLevel;
  Result.Left := getNeighbour(Left).getLoDLevel;
  Result.Top := getNeighbour(Top).getLoDLevel;
  Result.Right := getNeighbour(Right).getLoDLevel;
  Result.Bottom := getNeighbour(Bottom).getLoDLevel;
end;

function TTerrain.TQuadTreeNode.getLoDLevel : Integer;
var
  err : single;
begin
  err := Min(sqrt(FBoundingBox.DistanceToPoint(FTerrain.Scene.Camera.Position)) * FTerrain.TerrainSettings.Geomipmapdistanceerror, (abs(RVector3.UNITY.Dot((FTerrain.Scene.Camera.Position - FBoundingBox.Center).Normalize))) * FTerrain.TerrainSettings.Geomipmapnormalerror);
  Result := FLoDError.Count - 1;
  while FLoDError[Result] > err do
  begin
    Result := Result - 1;
    if Result = 0 then break;
  end;
  Result := Result + 1;
end;

function TTerrain.TQuadTreeNode.getNeighbour(Neighbour : EnumNeighbour) : TQuadTreeNode;
var
  x, y : Integer;
begin
  x := FTile.Left div TILESIZE;
  y := FTile.Top div TILESIZE;
  case Neighbour of
    Middle :;
    Left : dec(x);
    Top : dec(y);
    Right : inc(x);
    Bottom : inc(y);
  end;
  Result := getTilePerIndex(x, y);
end;

function TTerrain.TQuadTreeNode.getRelativeRect : RRectFloat;
begin
  Result := RRectFloat.Create(FTile.Left / (FTerrain.Size - 1), FTile.Top / (FTerrain.Size - 1), FTile.Right / (FTerrain.Size - 1), FTile.Bottom / (FTerrain.Size - 1))
end;

function TTerrain.TQuadTreeNode.getTilePerIndex(x, y : Integer) : TQuadTreeNode;
begin
  Result := FTileMap[Max(0, Min(length(FTileMap) - 1, x)), Max(0, Min(length(FTileMap) - 1, (y)))];
end;

function TTerrain.TQuadTreeNode.HasChildren : boolean;
begin
  Result := FChildren[0] <> nil;
end;

procedure TTerrain.TQuadTreeNode.RenderTiles(RenderContext : TRenderContext; ComputeLOD : boolean);
var
  i : Integer;
  relRect : RRectFloat;
begin
  if CheckVisibility(FTerrain.Scene.Camera) then
  begin
    if self.getDepth = FTerrain.TextureSplits then
    begin
      GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amClamp);
      GFXD.Device3D.SetSamplerState(tsNormal, tfAuto, amClamp);
      GFXD.Device3D.SetSamplerState(tsMaterial, tfAuto, amClamp);

      RenderContext.CurrentShader.SetTexture(tsColor, self.FChunkTexture.DiffuseMap);
      RenderContext.CurrentShader.SetTexture(tsNormal, self.FChunkTexture.NormalMap);
      RenderContext.CurrentShader.SetTexture(tsMaterial, self.FChunkTexture.MaterialMap);

      relRect := getRelativeRect;

      RenderContext.CurrentShader.SetShaderConstant<RVector2>(dcTextureOffset, -relRect.LeftTop / relRect.Size);
      RenderContext.CurrentShader.SetShaderConstant<RVector2>(dcTextureScale, 1 / relRect.Size);

      RenderContext.CurrentShader.ShaderBegin;
    end;

    if HasChildren then
    begin
      for i := 0 to 3 do FChildren[i].RenderTiles(RenderContext, ComputeLOD);
    end
    else
    begin
      if ComputeLOD then
      begin
        if not UseGeoMipMapping then FLastTileLoDLevel := RLoDDependency.Create(1, 1, 1, 1, 1)
        else FLastTileLoDLevel := getLoDDependency;
      end
      else
        if FLastTileLoDLevel.Middle = 0 then FLastTileLoDLevel := RLoDDependency.Create(1, 1, 1, 1, 1);

      FTerrain.RenderTile(FTile.Left + FTile.Top * Integer(FTerrain.Size), FLastTileLoDLevel);
    end;

    if assigned(FChunkTexture) then
    begin
      RenderContext.CurrentShader.ShaderEnd;
    end;
  end;
end;

procedure TTerrain.TQuadTreeNode.SetChunkTextures(Textures : TUltimateObjectList<TChunkTexture>);
var
  i : Integer;
begin
  if self.getDepth = FTerrain.TextureSplits then
  begin
    FChunkTexture := Textures[self.getLayerID];
    FChunkTexture.FRect := self.FTile;
    FChunkTexture.FRelRect := self.getRelativeRect;
  end
  else if HasChildren then
    for i := 0 to 3 do
        self.FChildren[i].SetChunkTextures(Textures);
end;

function TTerrain.TQuadTreeNode.TileRectToMinMaxBox(TileRect : TRect) : RAABB;
var
  x, y : Integer;
begin
  Result := RAABB.Create(FData[TileRect.Left, TileRect.Top].Position);
  // compute BoundingBox
  for x := TileRect.Left to TileRect.Right do
    for y := TileRect.Top to TileRect.Bottom do Result.Extend(FData[x, y].Position);
  Result.Min := Result.Min * FTerrain.FScale + FTerrain.FPosition;
  Result.Max := Result.Max * FTerrain.FScale + FTerrain.FPosition;
end;

{ TTerrain.RLoDDependency }

constructor TTerrain.RLoDDependency.Create(Middle, Left, Top, Right,
  Bottom : cardinal);
begin
  self.Middle := Middle;
  self.Left := Left;
  self.Top := Top;
  self.Right := Right;
  self.Bottom := Bottom;
end;

{ TTerrainManipulator }

procedure TTerrainEditor.ClearMap(MapType : EnumMapType);
var
  i : Integer;
begin
  for i := 0 to Terrain.FChunkTextures.Count - 1 do
  begin
    case MapType of
      mtDiffuse : Terrain.FChunkTextures[i].ClearTexture(MapType, ExtraColor);
      mtNormal : Terrain.FChunkTextures[i].ClearTexture(MapType, RColor.CDEFAULTNORMAL);
      mtMaterial : Terrain.FChunkTextures[i].ClearTexture(MapType, ExtraMaterial);
    end;
  end;
end;

constructor TTerrainEditor.Create(Terrain : TTerrain);
begin
  self.Terrain := Terrain;
  Brushcore := 5;
  Brushedge := 5;
  Strength := 0.1;
end;

destructor TTerrainEditor.Destroy;
begin
  FDiffuse.Free;
  FNormal.Free;
  FMaterial.Free;
  inherited;
end;

procedure TTerrainEditor.DoAction(Position : RVector3; Action : ProcTerrainEditAction);
var
  x, y : Integer;
  MinIndex, MaxIndex : RIntVector2;
  SubRect : TRect;
  Dist : single;
begin
  Position.y := 0;
  MinIndex := Terrain.PositionToIndex(Position + (RVector3.Create(-1, 0, -1) * (self.Brushcore + self.Brushedge)));
  MaxIndex := Terrain.PositionToIndex(Position + (RVector3.Create(1, 0, 1) * (self.Brushcore + self.Brushedge))) + RIntVector2.Create(1, 1);
  SubRect := Rect(MinIndex.x, MinIndex.y, MaxIndex.x, MaxIndex.y);
  for x := MinIndex.x to MaxIndex.x do
    for y := MinIndex.y to MaxIndex.y do
    begin
      if (x > Terrain.Size - 1) or (y > Terrain.Size - 1) then continue;
      Dist := Terrain.IndexToPosition(x, y).SetY(0).Distance(Position);
      Action(x, y, CosFactor(Max(0, (1 - (Max(0, Dist - Brushcore) / Brushedge)))), Terrain.GetTerrainHeight(Position));
    end;
  Terrain.DoGridAction(SubRect, Terrain.GridActionComputeNormal);
  Terrain.DoGridAction(SubRect, Terrain.GridActionSmoothNormal);
  Terrain.GridDataToVertexbuffer(SubRect);
end;

procedure TTerrainEditor.DrawTexture(Position : RVector3);
var
  x, y, TextureSize : Integer;
  RelPosition, RelSize, WorldPos : RVector2;
  Normal, newnormal : RVector3;
  SubRect, TexelRelRect : RRectFloat;
  TexelRect : RRect;
  Dist : single;
  Color, DrawedColor : RColor;
  Brushstrength : single;
  i : Integer;
  CurrentTexture : TChunkTexture;

  function TexelToWorldPosition(x, y : Integer) : RVector3;
  var
    Position : RVector2;
  begin
    Position := RVector2.Create(x, y).Min(CurrentTexture.FDiffusemap.Size - 1).Max(0);
    Position := Position / (CurrentTexture.FDiffusemap.Size - 1);
    Position := (Position * CurrentTexture.FRelRect.Size) + CurrentTexture.FRelRect.LeftTop - RVector2.Create(0.5, 0.5);
    Result := Position.X0Y * Terrain.Scale + Terrain.Position;
  end;

begin
  Position.y := 0;
  RelPosition := Terrain.PositionToRelativeCoord(Position, false);
  RelSize := Terrain.PositionToRelativeCoord(Position + (RVector3.Create(1, 0, 1) * (self.Brushcore + self.Brushedge)), false) - RelPosition;
  SubRect := RRectFloat.CreateWidthHeight(RelPosition - RelSize, 2 * RelSize);

  // draw in every texture which intersects with the brush
  for i := 0 to Terrain.FChunkTextures.Count - 1 do
    if Terrain.FChunkTextures[i].FRelRect.Intersects(SubRect) then
    begin
      CurrentTexture := Terrain.FChunkTextures[i];
      CurrentTexture.MakeEditable;
      CurrentTexture.FDiffusemap.Lock;
      CurrentTexture.FNormalmap.Lock;
      CurrentTexture.FMaterialmap.Lock;
      if assigned(Diffuse) and not OverwriteColor then Diffuse.Lock;
      // determine texels which intersects with brush
      TextureSize := CurrentTexture.TextureSize;
      TexelRelRect := CurrentTexture.FRelRect.Intersection(SubRect);
      TexelRelRect := RRectFloat.Create((TexelRelRect.LeftTop - CurrentTexture.FRelRect.LeftTop) / CurrentTexture.FRelRect.Width * TextureSize,
        (TexelRelRect.RightBottom - CurrentTexture.FRelRect.LeftTop) / CurrentTexture.FRelRect.Width * TextureSize);
      TexelRect := TexelRelRect.round.Inflate(1, 1, 1, 1);

      // iterate over texels adjusting them
      for x := TexelRect.Left to TexelRect.Right do
        for y := TexelRect.Top to TexelRect.Bottom do
        begin
          if (x < 0) or (y < 0) or (x > CurrentTexture.FDiffusemap.Width - 1) or (y > CurrentTexture.FDiffusemap.Height - 1) then continue;
          WorldPos := TexelToWorldPosition(x, y).xz;
          Dist := WorldPos.Distance(Position.xz);
          Brushstrength := CosFactor(Max(0, (1 - (Max(0, Dist - Brushcore) / Brushedge)))) * (self.Strength * 10);
          // Color
          if OverwriteColor or assigned(FDiffuse) then
          begin
            Color := CurrentTexture.FDiffusemap.getTexel<cardinal>(x, y, amClamp);
            if OverwriteColor then DrawedColor := self.ExtraColor.SetAlphaF(1.0)
            else DrawedColor := Diffuse.GetColor(WorldPos / BrushTextureScale, amWrap, tfPoint);
            Color := Color.Lerp(DrawedColor, HMath.saturate(self.Alpha * Brushstrength * DrawedColor.A));
            Color.A := 1.0;
            CurrentTexture.FDiffusemap.setTexel<cardinal>(x, y, Color.AsCardinal);
          end;
          // normal
          if assigned(FNormal) then
          begin
            Color := CurrentTexture.FNormalmap.getTexel<cardinal>(x, y, amClamp);
            Normal := Color.RGB * 2 - 1;
            Color := FNormal.GetColor(WorldPos / BrushTextureScale, amWrap, tfPoint);
            newnormal := Color.RGB * 2 - 1;
            Color := ((Normal.Lerp(newnormal, self.Alpha * Brushstrength).Normalize + 1) / 2).xyz1;
            CurrentTexture.FNormalmap.setTexel<cardinal>(x, y, Color.AsCardinal);
          end;
          // Material
          if OverwriteMaterial or assigned(FMaterial) then
          begin
            Color := CurrentTexture.FMaterialmap.getTexel<cardinal>(x, y, amClamp);
            if OverwriteMaterial then DrawedColor := self.ExtraMaterial
            else DrawedColor := FMaterial.GetColor(WorldPos / BrushTextureScale, amWrap, tfPoint);
            Color := Color.Lerp(DrawedColor, self.Alpha * Brushstrength);
            CurrentTexture.FMaterialmap.setTexel<cardinal>(x, y, Color.AsCardinal);
          end;
        end;
      if assigned(Diffuse) and not OverwriteColor then Diffuse.Unlock;
      CurrentTexture.FMaterialmap.Unlock;
      CurrentTexture.FNormalmap.Unlock;
      CurrentTexture.FDiffusemap.Unlock;
    end;
end;

procedure TTerrainEditor.EditActionNoise(x, y : Integer; Brushstrength : single; Center : RVector3);
begin
  Terrain.FGridData[x, y].Position.y := Max(Min(Terrain.FGridData[x, y].Position.y + Brushstrength * Strength * (2 * random - 1), 0.5), -0.5);
end;

procedure TTerrainEditor.EditActionPlane(x, y : Integer; Brushstrength : single; Center : RVector3);
begin
  Terrain.FGridData[x, y].Position.y := Max(Min((Terrain.FGridData[x, y].Position.y * (1 - Brushstrength * Strength) + (Center.y / Terrain.Scale.y) * Strength * Brushstrength), 0.5), -0.5);
end;

procedure TTerrainEditor.EditActionSetHeight(x, y : Integer; Brushstrength : single; Center : RVector3);
begin
  Terrain.FGridData[x, y].Position.y := Max(Min((Terrain.FGridData[x, y].Position.y * (1 - Brushstrength) + (Strength / Terrain.Scale.y) * Brushstrength), 0.5), -0.5);
end;

procedure TTerrainEditor.EditActionSmooth(x, y : Integer; Brushstrength : single; Center : RVector3);
var
  s : single;
  i, i2 : Integer;
begin
  s := 0;
  for i := -1 to 1 do
    for i2 := -1 to 1 do s := s + Terrain.getGridNode(x + i, y + i2).Position.y;
  s := s / 9;
  Terrain.FGridData[x, y].Position.y := Max(Min(Terrain.FGridData[x, y].Position.y + Brushstrength * (Strength * 10) * ((s - Terrain.FGridData[x, y].Position.y)), 0.5), -0.5);
end;

procedure TTerrainEditor.EditActionTransform(x, y : Integer; Brushstrength : single; Center : RVector3);
begin
  Terrain.FGridData[x, y].Position.y := Max(Min(Terrain.FGridData[x, y].Position.y + Brushstrength * Strength, 0.5), -0.5);
end;

procedure TTerrainEditor.Flatten(HeightReference : single);
var
  x, y : Integer;
begin
  HeightReference := HeightReference / Terrain.Scale.y;
  for x := 0 to length(Terrain.FGridData) - 1 do
    for y := 0 to length(Terrain.FGridData[x]) - 1 do
      if (Terrain.FGridData[x, y].Position.y <= HeightReference) and (Terrain.FGridData[x, y].Position.y >= 0) then
          Terrain.FGridData[x, y].Position.y := 0;
  Terrain.GridDataEvaluation;
end;

function TTerrainEditor.GetColor(Position : RVector3) : RColor;
var
  RelPosition : RVector2;
  i : Integer;
begin
  Result := RColor.CBLACK;

  Position.y := 0;
  RelPosition := Terrain.PositionToRelativeCoord(Position, True);

  // search matching chunk
  for i := 0 to Terrain.FChunkTextures.Count - 1 do
    if Terrain.FChunkTextures[i].FRelRect.ContainsPoint(RelPosition) then
    begin
      Terrain.FChunkTextures[i].MakeEditable;
      Terrain.FChunkTextures[i].FDiffusemap.Lock;

      RelPosition := (RelPosition - Terrain.FChunkTextures[i].FRelRect.LeftTop) / Terrain.FChunkTextures[i].FRelRect.Size;
      Result := Terrain.FChunkTextures[i].FDiffusemap.GetColor(RelPosition, amClamp);
      Result.A := 1.0;

      Terrain.FChunkTextures[i].FDiffusemap.Unlock;
      break;
    end;
end;

procedure TTerrainEditor.Noise(Position : RVector3);
begin
  DoAction(Position, EditActionNoise);
end;

procedure TTerrainEditor.Plane(Position : RVector3);
begin
  DoAction(Position, EditActionPlane);
end;

procedure TTerrainEditor.AxisReflection(MirrorType : EnumMirrorType; InvertDirection : boolean);
var
  x, y : Integer;
  RangeX, RangeY : RIntVector2;
begin
  case MirrorType of
    mtX :
      begin
        if InvertDirection then
        begin
          RangeX.x := length(Terrain.FGridData) div 2 + 1;
          RangeX.y := length(Terrain.FGridData);
        end
        else
        begin
          RangeX.x := 0;
          RangeX.y := length(Terrain.FGridData) div 2 - 1;
        end;
        RangeY := RIntVector2.Create(0, length(Terrain.FGridData));
      end;
    mtY :
      begin
        RangeX := RIntVector2.Create(0, length(Terrain.FGridData));
        if InvertDirection then
        begin
          RangeY.x := length(Terrain.FGridData) div 2 + 1;
          RangeY.y := length(Terrain.FGridData);
        end
        else
        begin
          RangeY.x := 0;
          RangeY.y := length(Terrain.FGridData) div 2 - 1;
        end;
      end;
  end;

  for x := RangeX.x to RangeX.y - 1 do
    for y := RangeY.x to RangeY.y - 1 do
    begin
      if MirrorType = mtY then
          Terrain.FGridData[x, y].Position.y := Terrain.FGridData[x, Terrain.Size - 1 - y].Position.y
      else
          Terrain.FGridData[x, y].Position.y := Terrain.FGridData[Terrain.Size - 1 - x, y].Position.y;
    end;
  Terrain.GridDataEvaluation;
end;

procedure TTerrainEditor.PointReflection(MirrorType : EnumMirrorType; InvertDirection : boolean);
var
  x, y : Integer;
  RangeX, RangeY : RIntVector2;
begin
  case MirrorType of
    mtX :
      begin
        if InvertDirection then
        begin
          RangeX.x := length(Terrain.FGridData) div 2 + 1;
          RangeX.y := length(Terrain.FGridData);
        end
        else
        begin
          RangeX.x := 0;
          RangeX.y := length(Terrain.FGridData) div 2 - 1;
        end;
        RangeY := RIntVector2.Create(0, length(Terrain.FGridData));
      end;
    mtY :
      begin
        RangeX := RIntVector2.Create(0, length(Terrain.FGridData));
        if InvertDirection then
        begin
          RangeY.x := length(Terrain.FGridData) div 2 + 1;
          RangeY.y := length(Terrain.FGridData);
        end
        else
        begin
          RangeY.x := 0;
          RangeY.y := length(Terrain.FGridData) div 2 - 1;
        end;
      end;
  end;

  for x := RangeX.x to RangeX.y - 1 do
    for y := RangeY.x to RangeY.y - 1 do
    begin
      Terrain.FGridData[x, y].Position.y := Terrain.FGridData[Terrain.Size - 1 - x, Terrain.Size - 1 - y].Position.y;
    end;
  Terrain.GridDataEvaluation;
end;

procedure TTerrainEditor.setDiffuse(const Value : TTexture);
begin
  FDiffuse.Free;
  FDiffuse := Value;
  if assigned(FDiffuse) then FDiffuse.MakeLockable;
end;

procedure TTerrainEditor.setMaterial(const Value : TTexture);
begin
  FMaterial.Free;
  FMaterial := Value;
  if assigned(FMaterial) then FMaterial.MakeLockable;
end;

procedure TTerrainEditor.setNormal(const Value : TTexture);
begin
  FNormal.Free;
  FNormal := Value;
  if assigned(FNormal) then FNormal.MakeLockable;
end;

procedure TTerrainEditor.Smooth(Position : RVector3);
begin
  DoAction(Position, EditActionSmooth);
end;

procedure TTerrainEditor.Transform(Position : RVector3; SetToHeight : boolean);
begin
  if not SetToHeight then
  begin
    DoAction(Position, EditActionTransform);
  end
  else DoAction(Position, EditActionSetHeight);
end;

{ TLinePoolTerrainHelper }

procedure TLinePoolTerrainHelper.DrawCircleOnTerrain(Terrain : TTerrain; Position : RVector3; Radius : single; Color : RColor; Samplingrate : Integer);
var
  i : Integer;
  Circlevec, NextCirclevec : RVector3;
begin
  for i := 0 to Samplingrate - 1 do
  begin
    Circlevec := RVector3.Create(0, 0, 1).RotatePitchYawRoll(0, PI * 2 * (i / Samplingrate), 0);
    NextCirclevec := RVector3.Create(0, 0, 1).RotatePitchYawRoll(0, PI * 2 * ((i + 1) / Samplingrate), 0);
    DrawLineOnTerrain(Terrain, (Circlevec * Radius) + Position, (NextCirclevec * Radius) + Position, Color);
  end;
end;

procedure TLinePoolTerrainHelper.DrawCircleOnTerrain(Terrain : TTerrain; Position : RVector3; Radius, Radius2 : single; Color : RColor; Rings : Integer; Samplingrate : Integer);
var
  i : Integer;
begin
  for i := 0 to Rings - 1 do DrawCircleOnTerrain(Terrain, Position, SLinLerp(Radius, Radius2, (i / (Rings - 1))), Color.SetAlphaF(1 - (i / (Rings - 1))), Samplingrate);
end;

procedure TLinePoolTerrainHelper.DrawFixedGridOnTerrain(Terrain : TTerrain; Position : RVector3; Radius : single; Color : RColor; Samplingrate : single);
const
  HIGHLIGHTSAMPLE = 5;
var
  Circle : RCircle;
  Line : RLine2D;
  i, Count : Integer;
  CurrentColor : RColor;
  Startpos, Endpos, Offset, pos : RVector2;
  procedure DrawEndings();
  begin
    Startpos := Line.Origin;
    Endpos := Line.Origin - Line.Direction.Normalize * Samplingrate;
    DrawLineOnTerrain(Terrain, Startpos.X0Y, Endpos.X0Y, CurrentColor, CurrentColor.SetAlphaF(0));
    Startpos := Line.Endpoint;
    Endpos := Line.Endpoint + Line.Direction.Normalize * Samplingrate;
    DrawLineOnTerrain(Terrain, Startpos.X0Y, Endpos.X0Y, CurrentColor, CurrentColor.SetAlphaF(0));

  end;

begin
  Circle := RCircle.Create(Position.xz, Radius);
  Count := Math.Ceil(Radius / Samplingrate);
  Offset := (Position.xz / Samplingrate).Frac * Samplingrate;
  pos := (Position.xz / Samplingrate).trunc * Samplingrate;
  for i := -Count to Count do
  begin
    Startpos := (RVector2.Create(Samplingrate, 0) * i) + pos - RVector2.Create(0, Radius + Offset.x);
    Endpos := (RVector2.Create(Samplingrate, 0) * i) + pos + RVector2.Create(0, Radius + Offset.x);
    Line := RLine2D.CreateFromPoints(Startpos, Endpos);
    Line := Circle.IntersectionRay(Line.ToRay);
    CurrentColor := Color;
    if trunc(Startpos.x / Samplingrate) mod HIGHLIGHTSAMPLE = 0 then CurrentColor := Color.Lerp(RColor.CBLACK, 0.5);
    DrawLineOnTerrain(Terrain, Line.Origin.X0Y, Line.Endpoint.X0Y, CurrentColor, Samplingrate);
    DrawEndings();

    Startpos := (RVector2.Create(0, Samplingrate) * i) + pos - RVector2.Create(Radius + Offset.y, 0);
    Endpos := (RVector2.Create(0, Samplingrate) * i) + pos + RVector2.Create(Radius + Offset.y, 0);
    Line := RLine2D.CreateFromPoints(Startpos, Endpos);
    Line := Circle.IntersectionRay(Line.ToRay);
    CurrentColor := Color;
    if trunc(Startpos.y / Samplingrate) mod HIGHLIGHTSAMPLE = 0 then CurrentColor := Color.Lerp(RColor.CBLACK, 0.5);
    DrawLineOnTerrain(Terrain, Line.Origin.X0Y, Line.Endpoint.X0Y, CurrentColor, Samplingrate);
    DrawEndings();
  end;
end;

procedure TLinePoolTerrainHelper.DrawLineOnTerrain(Terrain : TTerrain; StartPosition, EndPosition : RVector3; StartColor, EndColor : RColor; Samplingrate : single; YEpsilon : single);
var
  i, Count : Integer;
  s1, s2 : single;
  Color1, Color2 : RColor;
begin
  if Samplingrate <= 0 then Count := 1
  else Count := Math.Ceil(StartPosition.Distance(EndPosition) / Samplingrate);
  inc(Count);
  for i := 0 to Count - 2 do
  begin
    s1 := i / (Count - 1);
    s2 := (i + 1) / (Count - 1);
    Color1 := StartColor.Lerp(EndColor, s1);
    Color2 := StartColor.Lerp(EndColor, s2);
    AddLine(Terrain.GetTerrainHeight(StartPosition.Lerp(EndPosition, s1), True) + (RVector3.UNITY * YEpsilon), Terrain.GetTerrainHeight(StartPosition.Lerp(EndPosition, s2), True) + (RVector3.UNITY * YEpsilon), Color1, Color2);
  end;
end;

procedure TLinePoolTerrainHelper.DrawMultiPolyOnTerrain(Terrain : TTerrain; Polygon : TMultipolygon; Color : RColor; Samplingrate : single; YEpsilon : single);
var
  i : Integer;
begin
  for i := 0 to Polygon.Polygons.Count - 1 do
  begin
    if Polygon.Polygons[i].Subtractive then DrawPolyOnTerrain(Terrain, Polygon.Polygons[i].Polygon, Color.Lerp(RColor.CBLACK, 0.25), Samplingrate, YEpsilon)
    else DrawPolyOnTerrain(Terrain, Polygon.Polygons[i].Polygon, Color, Samplingrate, YEpsilon);
  end;
end;

procedure TLinePoolTerrainHelper.DrawPolyOnTerrain(Terrain : TTerrain; Polygon : TPolygon; Color : RColor; Samplingrate : single; YEpsilon : single);
var
  i : Integer;
begin
  for i := 0 to Polygon.Nodes.Count - HGeneric.TertOp<Integer>(Polygon.Closed, 1, 2) do
  begin
    DrawLineOnTerrain(Terrain, Polygon.Nodes[i].X0Y, Polygon.Nodes[(i + 1) mod (Polygon.Nodes.Count)].X0Y, Color, Samplingrate, YEpsilon);
  end;
end;

procedure TLinePoolTerrainHelper.DrawLineOnTerrain(Terrain : TTerrain; StartPosition, EndPosition : RVector3; Color : RColor; Samplingrate : single; YEpsilon : single);
begin
  DrawLineOnTerrain(Terrain, StartPosition, EndPosition, Color, Color, Samplingrate, YEpsilon);
end;

initialization

TChunkTexture.ClassName;

end.

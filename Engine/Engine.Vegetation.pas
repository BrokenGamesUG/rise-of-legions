unit Engine.Vegetation;

interface

uses
  System.Math,
  System.Rtti,
  System.Hash,
  System.Classes,
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  /// ///////////////////////////////////////////////////////////
  Engine.Helferlein.DataStructures,
  {$IFDEF DEBUG}
  Engine.Helferlein.DataStructures.Helper,
  {$ENDIF}
  Engine.Helferlein.VCLUtils,
  Engine.Core,
  Engine.Core.Types,
  Engine.GFXApi,
  Engine.GFXApi.Types,
  Engine.Vertex,
  Engine.Math,
  Engine.Mesh,
  Engine.Core.Mesh,
  Engine.Math.Collision2D,
  Engine.Math.Collision3D,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Serializer,
  Engine.Serializer.Types,
  Engine.Log,
  Engine.AssetLoader,
  Engine.AssetLoader.MeshAsset,
  Engine.AssetLoader.FBXLoader,
  Engine.AssetLoader.AssimpLoader;

type

  {$RTTI EXPLICIT METHODS([vcProtected, vcPublic]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}
  PVertexPositionTextureNormalCustom = ^RVertexPositionTextureNormalCustom;

  RVertexPositionTextureNormalCustom = packed record
    strict private
      class var FDeclaration : TVertexdeclaration;
    public
      Position : RVector3;
      TextureCoordinate : RVector2;
      Normal : RVector3;
      Custom : RVector4;
      class function BuildVertexdeclaration() : TVertexdeclaration; static;
  end;

  TVegetationManager = class;

  RVegetationTexture = record
    AlphaTested, FlipCullNormals, CastsShadows : boolean;
    Texture : string;
    constructor Create(Texture : string; AlphaTested, FlipCullNormals, CastsShadows : boolean);
    function Hash() : integer;
    class operator equal(a, b : RVegetationTexture) : boolean;
  end;

  [XMLExcludeAll]
  TVegetationObject = class abstract
    private
      procedure setGroundNormal(const Value : RVector3);
      procedure setPosition(const Value : RVector3);
      procedure setCastsNoShadows(const Value : boolean);
    protected
      FDirty : boolean;
      [XMLIncludeElement]
      FRandSeed : integer;
      [XMLIncludeElement]
      FPosition, FGroundNormal : RVector3;
      [XMLIncludeElement]
      FCastsNoShadows : boolean;
      function Clone(ClonedObject : TVegetationObject = nil) : TVegetationObject; virtual;
      procedure SetDirty;
      property IsDirty : boolean read FDirty;
      procedure Clean;
      function GetPartCount : integer; virtual; abstract;
      function GetPartTexture(Part : integer) : RVegetationTexture; virtual; abstract;
      /// <summary> X - Vertex count, Y - Index count </summary>
      function GetNeededBufferSize(Part : integer) : RIntVector2; virtual; abstract;
      procedure ComputeAndSave(Part : integer; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>); virtual; abstract;
    public
      property GroundNormal : RVector3 read FGroundNormal write setGroundNormal;
      property Position : RVector3 read FPosition write setPosition;
      [VCLBooleanField]
      property CastsNoShadows : boolean read FCastsNoShadows write setCastsNoShadows;
      [VCLCallable('Randomize')]
      procedure ReRoll; virtual;
      function GetBoundingSphere() : RSphere; virtual; abstract;
  end;

  [XMLIncludeAll([XMLIncludeProperties])]
  TTree = class(TVegetationObject)
    private
      procedure setLeaveGravity(const Value : RVector2);
      procedure setHeight(const Value : RVariedSingle);
      procedure setLeaveSize(const Value : RVariedVector2);
      procedure setTrunkThickness(const Value : RVariedSingle);
      procedure setLeaveCount(const Value : RVariedInteger);
      procedure setLeaveRange(const Value : RVariedSingle);
      procedure setLeaveSegments(const Value : integer);
      procedure setLeaveSlices(const Value : integer);
      procedure setTrunkLayers(const Value : integer);
      procedure setTrunkSegments(const Value : integer);
      procedure LoadLeaveTexture(const Value : string);
      procedure LoadTrunkTexture(const Value : string);
      procedure setNoLeaveAngle(const Value : single);
      procedure setScale(const Value : single);
    protected
      FTrunkDiffuse, FLeaveDiffuse : string;
      [XMLIncludeElement]
      FLeaveRandSeed : integer;
      // Parameters
      FLeaveCount : RVariedInteger;
      FHeight, FTrunkThickness, FLeaveRange : RVariedSingle;
      FLeaveSize : RVariedVector2;
      FTrunk : RVariedHermiteSpline;
      FNoLeaveAngle : single;
      // Constants
      [XMLIncludeElement]
      FGravityDirection : RVector3;
      FLeaveGravity : RVector2;
      FScale : single;
      FLeaveSegments, FLeaveSlices, FTrunkLayer, FTrunkSegments : integer;
      // Determined parameters
      FRealTrunk : RHermiteSpline;
      FRealHeight, FRealTrunkThickness : single;
      function Clone(ClonedObject : TVegetationObject = nil) : TVegetationObject; override;
      /// <summary> (Vertexcount, Indexcount) </summary>
      function GetTrunkNeededBufferSize : RIntVector2;
      function GetLeaveNeededBufferSize : RIntVector2;
      procedure ComputeAndSaveTrunk(Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
      procedure ComputeAndSaveLeaves(Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
      procedure GenerateLeave(Position, Direction : RVector3; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
      procedure EvaluateTrunk;
      constructor Create; overload;
      function GetPartCount : integer; override;
      function GetPartTexture(Part : integer) : RVegetationTexture; override;
      function GetNeededBufferSize(Part : integer) : RIntVector2; override;
      procedure ComputeAndSave(Part : integer; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>); override;
    public
      [VCLSingleField(10)]
      property Scale : single read FScale write setScale;
      [VCLVariedSingleField(20, 20)]
      property Height : RVariedSingle read FHeight write setHeight;
      [VCLVariedSingleField(5, 5)]
      property TrunkThickness : RVariedSingle read FTrunkThickness write setTrunkThickness;
      [VCLVariedRVector2Field(10, 10, 10, 10)]
      property LeaveSize : RVariedVector2 read FLeaveSize write setLeaveSize;
      [VCLVariedIntegerField(0, 100, 100)]
      property LeaveCount : RVariedInteger read FLeaveCount write setLeaveCount;
      [VCLVariedSingleField(2, 0.5)]
      property LeaveRange : RVariedSingle read FLeaveRange write setLeaveRange;
      [VCLIntegerField(2, 50)]
      property LeaveSegments : integer read FLeaveSegments write setLeaveSegments;
      [VCLIntegerField(2, 50)]
      property LeaveSlices : integer read FLeaveSlices write setLeaveSlices;
      [VCLIntegerField(2, 50)]
      property TrunkLayers : integer read FTrunkLayer write setTrunkLayers;
      [VCLIntegerField(2, 50)]
      property TrunkSegments : integer read FTrunkSegments write setTrunkSegments;
      [VCLFileField]
      property TrunkDiffuse : string read FTrunkDiffuse write LoadTrunkTexture;
      [VCLFileField]
      property LeaveDiffuse : string read FLeaveDiffuse write LoadLeaveTexture;
      [VCLRVector2Field(10, 50)]
      property LeaveGravity : RVector2 read FLeaveGravity write setLeaveGravity;
      [VCLSingleField(PI)]
      property NoLeaveAngle : single read FNoLeaveAngle write setNoLeaveAngle;
      constructor Create(Position, GroundNormal, GravityDirection : RVector3); overload;
      function GetBoundingSphere() : RSphere; override;
      procedure ReRoll; override;
      destructor Destroy; override;
  end;

  [XMLIncludeAll([XMLIncludeProperties])]
  TVegetationPlaceable = class abstract(TVegetationObject)
    private
      procedure setScale(const Value : single);
    protected
      // Parameters
      FScale : single;
      FDiffuse : string;
      function Clone(ClonedObject : TVegetationObject = nil) : TVegetationObject; override;
      constructor CreateIntern; virtual;
      procedure LoadDiffuseTexture(const Value : string);
      function GetPartCount : integer; override;
      function GetPartTexture(Part : integer) : RVegetationTexture; override;
    public
      [VCLFileField]
      property Diffuse : string read FDiffuse write LoadDiffuseTexture;
      [VCLSingleField(100)]
      property Scale : single read FScale write setScale;
      constructor Create(Position, Normal : RVector3);
  end;

  [XMLIncludeAll([XMLIncludeProperties])]
  TGrassTuft = class(TVegetationPlaceable)
    private
      procedure setAngle(const Value : RVariedSingle);
      procedure setSize(const Value : RVariedVector2);
      procedure setTrapezial(const Value : RVariedSingle);
      procedure setMidOffset(const Value : single);
      procedure setNormalAdjustment(const Value : single);
    protected
      // Parameters
      FNormalAdjustment : single;
      FMidOffset : single;
      FTrapezial, FAngle : RVariedSingle;
      FSize : RVariedVector2;
      function Clone(ClonedObject : TVegetationObject = nil) : TVegetationObject; override;
      constructor CreateIntern; override;
      function GetNeededBufferSize(Part : integer) : RIntVector2; override;
      procedure ComputeAndSave(Part : integer; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>); override;
    public
      [VCLVariedSingleField(1.0, 1.0)]
      property Trapezial : RVariedSingle read FTrapezial write setTrapezial;
      [VCLVariedSingleField(PI, PI)]
      property Angle : RVariedSingle read FAngle write setAngle;
      [VCLVariedRVector2Field(1, 1, 1, 1)]
      property Size : RVariedVector2 read FSize write setSize;
      [VCLSingleField(1)]
      property MidOffset : single read FMidOffset write setMidOffset;
      [VCLSingleField(1)]
      property NormalAdjustment : single read FNormalAdjustment write setNormalAdjustment;
      function GetBoundingSphere() : RSphere; override;
  end;

  TCachedMeshData = class
    VertexData : TList<RVertexPositionTextureNormalCustom>;
    IndexData : TList<LongWord>;
    Boundings : RSphere;
    destructor Destroy; override;
  end;

  HMeshLoaderHelper = class abstract
    strict private
      class var FData : TObjectDictionary<string, TCachedMeshData>;
      class procedure LoadAndConvertMesh(Filename : string);
      class function CalculateBoundings(InData : TList<RVertexPositionTextureNormalCustom>) : RSphere;
      class procedure ComputeIndexedVertexData(InData : TList<RVertexPositionTextureNormalCustom>; IndexedVertexData : TList<RVertexPositionTextureNormalCustom>; IndexedIndexData : TList<LongWord>);
    public
      class function GetMeshData(Filename : string) : TCachedMeshData;
      class constructor Create;
      class destructor Destroy;
  end;

  [XMLIncludeAll([XMLIncludeProperties])]
  TVegetationMesh = class(TVegetationPlaceable)
    private
      procedure setSize(const Value : RVariedSingle);
      procedure setRotation(const Value : RVariedVector3);
    protected
      FSize : RVariedSingle;
      FRotation : RVariedVector3;
      FMeshes : string;
      FMeshList : TList<string>;
      FMeshBuilt : boolean;
      FVertexData : TList<RVertexPositionTextureNormalCustom>;
      FIndexData : TList<integer>;
      function Clone(ClonedObject : TVegetationObject = nil) : TVegetationObject; override;
      procedure BuildMeshList;
      constructor Create;
      constructor CreateIntern; override;
      function GetNeededBufferSize(Part : integer) : RIntVector2; override;
      procedure ComputeAndSave(Part : integer; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>); override;
    public
      [VCLStringField(scMemo)]
      property Meshes : string read FMeshes write FMeshes;
      [VCLVariedSingleField(1.0, 1.0)]
      property Size : RVariedSingle read FSize write setSize;
      [VCLVariedRVector3Field(PI, PI, PI, PI, PI, PI)]
      property Rotation : RVariedVector3 read FRotation write setRotation;
      function GetBoundingSphere() : RSphere; override;
      destructor Destroy; override;
  end;

  TVegetationChunk = class
    Vertexbuffer : TVertexbuffer;
    Indexbuffer : TIndexbuffer;
    NeededResources : RIntVector2;
    Texture : RVegetationTexture;
    destructor Destroy; override;
  end;

  [XMLExcludeAll]
  TVegetationManager = class(TWorldObject)
    public
      const
      FILEEXTENSION = '.veg';
    protected
      FSpatial : TObjectDictionary<RVegetationTexture, TkdTree<TVegetationObject>>;
      [XMLIncludeElement]
      FVegetationObjects : TUltimateObjectList<TVegetationObject>;
      FTextures : TObjectDictionary<string, TTexture>;
      FChunks : TObjectDictionary<TkdTreeNode<TVegetationObject>, TVegetationChunk>;
      FBoundingSphere : RSphere;
      FBoundingBox : RAABB;
      FTrunkShader, FAlphaShader, FGrassShader : TShader;
      FTrunkShadowShader, FAlphaShadowShader, FGrassShadowShader : TShader;
      FMaxIndicesPerBuffer : integer;
      [XMLIncludeElement]
      FWindDirection : RVector3;
      procedure SetDirty;
      function getWindStrength : single;
      procedure setWindStrength(const Value : single);
      procedure BuildBuffers;
      procedure RawRender(RenderShadow : boolean; RenderContext : TRenderContext);
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
      procedure RenderShadowContribution(RenderContext : TRenderContext);
    public
      DrawWireframe, DrawkdTree : boolean;
      [VCLSingleField(10)]
      property WindStrength : single read getWindStrength write setWindStrength;
      property WindDirection : RVector3 read FWindDirection write FWindDirection;
      constructor Create(Scene : TRenderManager);
      constructor CreateFromFile(Scene : TRenderManager; VegetationFile : string; Editable : boolean = True);
      procedure AddVegetationObject(VegetationObject : TVegetationObject);
      procedure RemoveVegetationObject(VegetationObject : TVegetationObject);
      procedure Idle;
      procedure LoadFromFile(Filename : string; Editable : boolean = True);
      procedure SaveToFile(Filename : string);
      /// <summary> Removes all vegetation on the one side of the axis and copy&mirrors the other side on this side.
      /// If invert is false the positive side will be copied to the negative side. </summary>
      procedure Symmetry(Axis : integer; Invert, PointSymmetry : boolean);
      function GetBoundingBox() : RAABB; override;
      function GetBoundingSphere() : RSphere; override;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  Vegetation : TVegetationManager;

implementation

{ TVegetationManager }

procedure TVegetationManager.AddVegetationObject(VegetationObject : TVegetationObject);
begin
  FVegetationObjects.Add(VegetationObject);
  VegetationObject.SetDirty;
end;

procedure TVegetationManager.BuildBuffers;
var
  VegetationObject : TVegetationObject;
  kdTree : TkdTree<TVegetationObject>;
  kdTreeItem : RPositionWeightItem<TVegetationObject>;
  Node : TkdTreeNode<TVegetationObject>;
  Leaves : TList<TkdTreeNode<TVegetationObject>>;
  TreeList : TDictionary<TVegetationObject, integer>;
  Chunk : TVegetationChunk;
  ChunkDict : TObjectDictionary<RVegetationTexture, TDictionary<TVegetationObject, integer>>;
  ChunkKey : RVegetationTexture;
  i : integer;
  DataCollector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>;
begin
  // Clear all existing chunks
  FChunks.Clear;
  FSpatial.Clear;

  ChunkDict := TObjectDictionary < RVegetationTexture, TDictionary < TVegetationObject, integer >>.Create([doOwnsValues], TEqualityComparer<RVegetationTexture>.Construct(
    function(const Left, Right : RVegetationTexture) : boolean
    begin
      Result := Left = Right;
    end,
    function(const Value : RVegetationTexture) : integer
    begin
      Result := Value.Hash;
    end
    ));

  // iterate over all vegetation objects splitting for VegetationTexture
  for VegetationObject in FVegetationObjects do
  begin
    for i := 0 to VegetationObject.GetPartCount - 1 do
    begin
      // collect textures
      if not ChunkDict.TryGetValue(VegetationObject.GetPartTexture(i), TreeList) then
      begin
        TreeList := TDictionary<TVegetationObject, integer>.Create;
        ChunkDict.Add(VegetationObject.GetPartTexture(i), TreeList);
      end;
      TreeList.Add(VegetationObject, i);
    end;
  end;

  // create kdtrees for different VegetationTextures
  for ChunkKey in ChunkDict.Keys do
  begin
    kdTree := TkdTree<TVegetationObject>.Create(FMaxIndicesPerBuffer, True, False);
    FSpatial.Add(ChunkKey, kdTree);
    // build kd-Tree
    kdTree.AddItems(HArray.Map < TPair<TVegetationObject, integer>, RPositionWeightItem < TVegetationObject >> (ChunkDict[ChunkKey].ToArray,
      function(const item : TPair<TVegetationObject, integer>) : RPositionWeightItem<TVegetationObject>
      begin
        Result := RPositionWeightItem<TVegetationObject>.Create(item.Key.Position, item.Key.GetNeededBufferSize(item.Value).Y, item.Key);
      end));

    Leaves := kdTree.GetAllLeaves;
    for Node in Leaves do
    begin

      Chunk := TVegetationChunk.Create;
      Chunk.Texture := ChunkKey;

      for kdTreeItem in Node.items do
      begin
        Chunk.NeededResources := Chunk.NeededResources + kdTreeItem.item.GetNeededBufferSize(ChunkDict[ChunkKey][kdTreeItem.item]);
      end;

      // if chunk anyhow empty ignore it
      if Chunk.NeededResources.isZeroVector then
      begin
        Chunk.Free;
        continue;
      end;

      // load textures
      if not FTextures.ContainsKey(ChunkKey.Texture) then FTextures.Add(ChunkKey.Texture, TTexture.CreateTextureFromFile(FormatDateiPfad(ChunkKey.Texture), GFXD.Device3D, mhGenerate, True));

      // create and fill geometry buffers
      DataCollector := TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>.Create(
        SizeOf(RVertexPositionTextureNormalCustom) * Chunk.NeededResources.X,
        SizeOf(Cardinal) * Chunk.NeededResources.Y
        );

      for kdTreeItem in Node.items do
      begin
        kdTreeItem.item.ComputeAndSave(ChunkDict[ChunkKey][kdTreeItem.item], DataCollector);
      end;

      Chunk.Vertexbuffer := TVertexbuffer.CreateVertexBuffer(DataCollector.VertexDataSize, [], GFXD.Device3D, DataCollector.VertexData);
      Chunk.Indexbuffer := TIndexbuffer.CreateIndexBuffer(DataCollector.IndexDataSize, [], ifINDEX32, GFXD.Device3D, DataCollector.IndexData);

      DataCollector.Free;

      FChunks.Add(Node, Chunk);
    end;

    Leaves.Free;
  end;

  ChunkDict.Free;

  FVegetationObjects.Extra.Each(
    procedure(const item : TVegetationObject)
    begin
      item.Clean
    end);

  FBoundingSphere := RSphere.CreateWrapping(HArray.Map<TVegetationObject, RSphere>(FVegetationObjects.ToArray,
    function(const item : TVegetationObject) : RSphere
    begin
      Result := item.GetBoundingSphere;
    end));

  FBoundingBox := RAABB.CreateWrapping(HArray.Map<TVegetationObject, RAABB>(FVegetationObjects.ToArray,
    function(const item : TVegetationObject) : RAABB
    begin
      Result := RAABB.CreateWrapping(item.GetBoundingSphere);
    end));
end;

constructor TVegetationManager.Create(Scene : TRenderManager);
begin
  inherited Create(Scene);
  FMaxIndicesPerBuffer := 50000 * 3; // max 50k triangles per buffer
  FUseAlphaTest := True;
  FVegetationObjects := TUltimateObjectList<TVegetationObject>.Create;
  FTextures := TObjectDictionary<string, TTexture>.Create([doOwnsValues]);
  FChunks := TObjectDictionary<TkdTreeNode<TVegetationObject>, TVegetationChunk>.Create([doOwnsValues]);
  FSpatial := TObjectDictionary < RVegetationTexture, TkdTree < TVegetationObject >>.Create([doOwnsValues]);

  WindDirection := RVector3.Create(1, 0, 1).Normalize;

  Scene.Eventbus.Subscribe(geDrawOpaqueShadowmap, RenderShadowContribution);
end;

constructor TVegetationManager.CreateFromFile(Scene : TRenderManager; VegetationFile : string; Editable : boolean);
begin
  Create(Scene);
  LoadFromFile(VegetationFile, Editable);
end;

destructor TVegetationManager.Destroy;
begin
  Scene.Eventbus.Unsubscribe(geDrawOpaqueShadowmap, RenderShadowContribution);
  FSpatial.Free;
  FTextures.Free;
  FChunks.Free;
  FVegetationObjects.Free;
  inherited;
end;

function TVegetationManager.GetBoundingBox : RAABB;
begin
  Result := FBoundingBox;
end;

function TVegetationManager.GetBoundingSphere : RSphere;
begin
  Result := FBoundingSphere;
end;

function TVegetationManager.getWindStrength : single;
begin
  Result := FWindDirection.Length;
end;

procedure TVegetationManager.Idle;
begin

end;

procedure TVegetationManager.LoadFromFile(Filename : string; Editable : boolean);
begin
  if not FileExists(Filename) then raise Exception.Create('TVegetationManager.LoadFromFile: VegetationFile ' + Filename + ' does not exist!');
  FVegetationObjects.Clear;
  HXMLSerializer.LoadObjectFromFile(self, Filename, []);
  BuildBuffers;
  if not Editable then FVegetationObjects.Clear;
end;

procedure TVegetationManager.RawRender(RenderShadow : boolean; RenderContext : TRenderContext);
var
  ShaderFlags : SetDefaultShaderFlags;
  Shader, GrassShader, AlphaShader, TrunkShader : TShader;
  Key : TkdTreeNode<TVegetationObject>;
  Leaves : TList<TkdTreeNode<TVegetationObject>>;
  Chunk : TVegetationChunk;
  SpatialKey : RVegetationTexture;
  Spatial : TkdTree<TVegetationObject>;
  VertexCount, IndexCount : integer;
begin
  if not Visible or (FSpatial.Count <= 0) or ((RenderContext.MainDirectionalLight = nil) and RenderShadow) then exit;

  if RenderShadow then
  begin
    ShaderFlags := [sfDiffuseTexture];
    FTrunkShadowShader := RenderContext.CreateDefaultShadowShader(ShaderFlags, ['Vegetationshader.fx']);
    FTrunkShadowShader.SetWorld(RMatrix.IDENTITY);

    ShaderFlags := [sfDiffuseTexture, sfCullAdjustNormal, sfAlphaTest];
    FAlphaShadowShader := RenderContext.CreateDefaultShadowShader(ShaderFlags, ['Vegetationshader.fx']);
    FAlphaShadowShader.SetWorld(RMatrix.IDENTITY);
    FAlphaShadowShader.SetShaderConstant<single>(dcAlpha, 1);
    FAlphaShadowShader.SetShaderConstant<single>(dcAlphaTestRef, 0.5);

    ShaderFlags := [sfDiffuseTexture, sfAlphaTest];
    FGrassShadowShader := RenderContext.CreateDefaultShadowShader(ShaderFlags, ['Vegetationshader.fx']);
    FGrassShadowShader.SetWorld(RMatrix.IDENTITY);
    FGrassShadowShader.SetShaderConstant<single>(dcAlpha, 1);
    FGrassShadowShader.SetShaderConstant<single>(dcAlphaTestRef, 0.5);

    GrassShader := FGrassShadowShader;
    AlphaShader := FAlphaShadowShader;
    TrunkShader := FTrunkShadowShader;
  end
  else
  begin
    ShaderFlags := [sfAllowLighting, sfDiffuseTexture];
    if RenderContext.ShadowMapping.Enabled then include(ShaderFlags, sfShadowMapping);
    FTrunkShader := RenderContext.CreateDefaultShader(ShaderFlags, ['Vegetationshader.fx']);
    FTrunkShader.SetWorld(RMatrix.IDENTITY);
    if not RenderContext.DrawGBuffer and RenderContext.ShadowMapping.Enabled then RenderContext.SetShadowmapping(FTrunkShader);

    ShaderFlags := [sfAllowLighting, sfDiffuseTexture, sfCullAdjustNormal, sfAlphaTest];
    if RenderContext.ShadowMapping.Enabled then include(ShaderFlags, sfShadowMapping);
    FAlphaShader := RenderContext.CreateDefaultShader(ShaderFlags, ['Vegetationshader.fx']);
    FAlphaShader.SetWorld(RMatrix.IDENTITY);
    FAlphaShader.SetShaderConstant<single>(dcAlpha, 1);
    FAlphaShader.SetShaderConstant<single>(dcAlphaTestRef, 0.5);
    if not RenderContext.DrawGBuffer and RenderContext.ShadowMapping.Enabled then RenderContext.SetShadowmapping(FAlphaShader);

    ShaderFlags := [sfAllowLighting, sfDiffuseTexture, sfAlphaTest];
    if RenderContext.ShadowMapping.Enabled then include(ShaderFlags, sfShadowMapping);
    FGrassShader := RenderContext.CreateDefaultShader(ShaderFlags, ['Vegetationshader.fx']);
    FGrassShader.SetWorld(RMatrix.IDENTITY);
    FGrassShader.SetShaderConstant<single>(dcAlpha, 1);
    FGrassShader.SetShaderConstant<single>(dcAlphaTestRef, 0.5);
    if not RenderContext.DrawGBuffer and RenderContext.ShadowMapping.Enabled then RenderContext.SetShadowmapping(FGrassShader);

    GrassShader := FGrassShader;
    AlphaShader := FAlphaShader;
    TrunkShader := FTrunkShader;
  end;

  // rebuild buffers if any tree is dirty
  if FVegetationObjects.Extra.Any(
    function(item : TVegetationObject) : boolean
    begin
      Result := item.IsDirty;
    end) then BuildBuffers;

  // required Renderstates
  RenderContext.ApplyGlobalShaderConstants(GrassShader);
  RenderContext.ApplyGlobalShaderConstants(AlphaShader);
  RenderContext.ApplyGlobalShaderConstants(TrunkShader);

  if DrawWireframe then GFXD.Device3D.SetRenderState(EnumRenderstate.rsFILLMODE, fmWireframe);

  GFXD.Device3D.SetSamplerState(tsColor, tfAuto, amWrap);

  GFXD.Device3D.SetVertexDeclaration(RVertexPositionTextureNormalCustom.BuildVertexdeclaration);

  for SpatialKey in FSpatial.Keys do
  begin
    Spatial := FSpatial[SpatialKey];

    {$IFDEF DEBUG}
    if DrawkdTree then Spatial.RenderDebug;
    {$ENDIF}
    Leaves := Spatial.GetAllLeaves(RenderContext.Camera.ViewingFrustum);
    for Key in Leaves do
    begin
      Chunk := FChunks[Key];
      if not Chunk.Texture.CastsShadows and RenderShadow then continue;

      if Chunk.Texture.AlphaTested then
      begin
        GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, cmNone);
        if Chunk.Texture.FlipCullNormals then Shader := AlphaShader
        else Shader := GrassShader;
      end
      else
      begin
        GFXD.Device3D.ClearRenderState(EnumRenderstate.rsCULLMODE);
        Shader := TrunkShader;
      end;

      Shader := RenderContext.SetShader(Shader);
      Shader.SetWorld(RMatrix.IDENTITY);
      Shader.SetShaderConstant<single>(dcAlpha, 1);
      Shader.SetShaderConstant<single>(dcAlphaTestRef, 0.5);
      Shader.SetShaderConstant<single>('time', TimeManager.GetFloatingTimestamp / 1000);
      Shader.SetShaderConstant<RVector3>('WindDirection', WindDirection);
      if RenderShadow then
      begin
        Shader.SetShaderConstant<RVector3>(dcLightPosition, RenderContext.Camera.Position);
      end;

      Shader.SetTexture(tsColor, FTextures[Chunk.Texture.Texture]);

      GFXD.Device3D.SetStreamSource(0, Chunk.Vertexbuffer, 0, SizeOf(RVertexPositionTextureNormalCustom));
      GFXD.Device3D.SetIndices(Chunk.Indexbuffer);
      Shader.ShaderBegin;

      VertexCount := Chunk.Vertexbuffer.Size div SizeOf(RVertexPositionTextureNormalCustom);
      IndexCount := Chunk.Indexbuffer.Size div SizeOf(Cardinal);
      GFXD.Device3D.DrawIndexedPrimitive(ptTrianglelist, 0, 0, VertexCount, 0, IndexCount div 3);
      FDrawnTriangles := FDrawnTriangles + IndexCount div 3;
      inc(FDrawCalls);

      Shader.ShaderEnd;
    end;
    Leaves.Free;
  end;

  GFXD.Device3D.ClearRenderState();
  GFXD.Device3D.ClearSamplerStates;
end;

procedure TVegetationManager.RemoveVegetationObject(VegetationObject : TVegetationObject);
begin
  FVegetationObjects.Remove(VegetationObject);
  SetDirty;
end;

procedure TVegetationManager.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
begin
  RawRender(False, RenderContext);
end;

procedure TVegetationManager.RenderShadowContribution(RenderContext : TRenderContext);
begin
  RawRender(True, RenderContext);
end;

procedure TVegetationManager.SaveToFile(Filename : string);
begin
  HXMLSerializer.SaveObjectToFile(self, Filename);
end;

procedure TVegetationManager.SetDirty;
begin
  if FVegetationObjects.Count > 0 then FVegetationObjects.First.SetDirty;
end;

procedure TVegetationManager.setWindStrength(const Value : single);
begin
  FWindDirection.Length := Value;
end;

procedure TVegetationManager.Symmetry(Axis : integer; Invert, PointSymmetry : boolean);
var
  VegetationObject : TVegetationObject;
  i : integer;
begin
  for i := FVegetationObjects.Count - 1 downto 0 do
  begin
    VegetationObject := FVegetationObjects[i];
    if ((VegetationObject.Position.Element[Axis] <= 0) and not Invert)
      or ((VegetationObject.Position.Element[Axis] >= 0) and Invert) then
        FVegetationObjects.Delete(i)
    else
    begin
      VegetationObject := VegetationObject.Clone;
      VegetationObject.Position := VegetationObject.Position.NegateDim(Axis);
      VegetationObject.GroundNormal := VegetationObject.GroundNormal.NegateDim(Axis);
      if PointSymmetry then
      begin
        if Axis = 0 then Axis := 2
        else Axis := 0;
        VegetationObject.Position := VegetationObject.Position.NegateDim(Axis);
        VegetationObject.GroundNormal := VegetationObject.GroundNormal.NegateDim(Axis);
      end;
      AddVegetationObject(VegetationObject);
    end;
  end;
  SetDirty;
end;

{ TTree }

procedure TTree.ComputeAndSaveTrunk(Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
var
  Vertex : RVertexPositionTextureNormalCustom;
  i, VertexCount : integer;
  sy, sr : single;
  j : integer;
  side, Tangent, pos : RVector3;
  thickness : single;
begin
  VertexCount := Collector.TotalPushedVertexCount;
  EvaluateTrunk;
  FRealTrunkThickness := self.TrunkThickness.Random;
  for i := 0 to TrunkLayers - 1 do
  begin
    sy := i / (TrunkLayers - 1);
    for j := 0 to TrunkSegments - 1 do
    begin
      sr := j / (TrunkSegments - 1) * 2 * PI;
      Tangent := FRealTrunk.getLinearTangent(sy);
      thickness := SLinLerp(1 / (sy + 0.1) / 5, FRealTrunkThickness, sy);
      side := FRealTrunk.getLinearNormal(sy).RotateAxis(Tangent, sr);
      if i = TrunkLayers - 1 then side := RVector3.Create(0, 1, 0);
      pos := FRealTrunk.getLinearPosition(sy);
      Vertex.Position := pos + side * thickness;
      Vertex.Normal := side;
      Vertex.TextureCoordinate := RVector2.Create(sr / 2 / PI, sy * (FRealTrunk.Length / (2 * PI * FRealTrunkThickness)));
      // Vertex.Tangent := Tangent;
      // Vertex.Binormal := side.Cross(Tangent).Normalize;
      Vertex.Custom := RVector4(0); // RVector4.Create(1, 0, sy, 1 - sqr(sy));

      Vertex.Position := ((Vertex.Position - FPosition) * FScale) + FPosition;
      Collector.PushVertex(Vertex);
      if (j <> TrunkSegments - 1) and (i <> TrunkLayers - 1) then
      begin
        Collector.PushIndex(VertexCount);
        Collector.PushIndex(VertexCount + 1);
        Collector.PushIndex(VertexCount + 1 + TrunkSegments);

        Collector.PushIndex(VertexCount);
        Collector.PushIndex(VertexCount + 1 + TrunkSegments);
        Collector.PushIndex(VertexCount + TrunkSegments);
      end;
      VertexCount := VertexCount + 1;
    end;
  end;
end;

procedure TTree.EvaluateTrunk;
begin
  RandSeed := FRandSeed;
  FRealHeight := FHeight.Random;
  FTrunk := RVariedHermiteSpline.Create(RVariedVector3.Create(FPosition),
    RVariedVector3.Create(FPosition + (FGroundNormal * FRealHeight * 0.3) + (-FGravityDirection * FRealHeight * 0.7), RVector3.Create(-FRealHeight / 3)),
    FGroundNormal * (FRealHeight),
    -FGravityDirection * (FRealHeight));
  FRealTrunk := self.FTrunk.getRandomSpline;
end;

function TTree.Clone(ClonedObject : TVegetationObject) : TVegetationObject;
begin
  if not assigned(ClonedObject) then Result := TTree.Create
  else Result := ClonedObject;
  with (Result as TTree) do
  begin
    FTrunkDiffuse := self.FTrunkDiffuse;
    FLeaveDiffuse := self.FLeaveDiffuse;
    FLeaveRandSeed := self.FLeaveRandSeed;
    FLeaveCount := self.FLeaveCount;
    FHeight := self.FHeight;
    FTrunkThickness := self.FTrunkThickness;
    FLeaveRange := self.FLeaveRange;
    FLeaveSize := self.FLeaveSize;
    FTrunk := self.FTrunk;
    FNoLeaveAngle := self.FNoLeaveAngle;
    FGravityDirection := self.FGravityDirection;
    FLeaveGravity := self.FLeaveGravity;
    FScale := self.FScale;
    FLeaveSegments := self.FLeaveSegments;
    FLeaveSlices := self.FLeaveSlices;
    FTrunkLayer := self.FTrunkLayer;
    FTrunkSegments := self.FTrunkSegments;
    FRealTrunk := self.FRealTrunk;
    FRealHeight := self.FRealHeight;
    FRealTrunkThickness := self.FRealTrunkThickness;
  end;
  inherited Clone(Result);
end;

procedure TTree.ComputeAndSave(Part : integer; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
begin
  case Part of
    0 : ComputeAndSaveTrunk(Collector);
    1 : ComputeAndSaveLeaves(Collector);
  end;
end;

function TTree.GetNeededBufferSize(Part : integer) : RIntVector2;
begin
  case Part of
    0 : Result := GetTrunkNeededBufferSize;
    1 : Result := GetLeaveNeededBufferSize;
  end;
end;

function TTree.GetPartCount : integer;
begin
  Result := 2;
end;

function TTree.GetPartTexture(Part : integer) : RVegetationTexture;
begin
  case Part of
    0 : Result := RVegetationTexture.Create(TrunkDiffuse, False, False, not FCastsNoShadows);
    1 : Result := RVegetationTexture.Create(LeaveDiffuse, True, True, not FCastsNoShadows);
  end;
end;

procedure TTree.ComputeAndSaveLeaves(Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
var
  leaveindex : integer;
  pos, leavedirection : RVector3;
begin
  // Trunk precomputation for leave position
  EvaluateTrunk;
  RandSeed := FLeaveRandSeed;
  // leavecount firstly determined for presize computation
  for leaveindex := 0 to LeaveCount.Random - 1 do
  begin
    leavedirection := RVector3.getRandomPointInSphere(-1, FNoLeaveAngle, FNoLeaveAngle).Normalize;
    pos := FRealTrunk.getPosition(FLeaveRange.Random);
    GenerateLeave(pos, leavedirection, Collector);
  end;
end;

function TTree.GetTrunkNeededBufferSize : RIntVector2;
begin
  Result := RIntVector2.Create(TrunkLayers * TrunkSegments, (TrunkLayers - 1) * (TrunkSegments - 1) * 6);
end;

function TTree.GetLeaveNeededBufferSize : RIntVector2;
var
  realLeaveCount : integer;
begin
  RandSeed := FLeaveRandSeed;
  realLeaveCount := LeaveCount.Random;
  Result := RIntVector2.Create(LeaveSlices * LeaveSegments, (LeaveSlices - 1) * (LeaveSegments - 1) * 6) * realLeaveCount;
end;

procedure TTree.GenerateLeave(Position, Direction : RVector3; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
var
  VertexCount, leavesegment, leavebend : integer;
  Leave : RHermiteSpline;
  sy, sx, windPhase : single;
  pos, side, Tangent : RVector3;
  LeaveSize : RVector2;
  Vertex : RVertexPositionTextureNormalCustom;
begin
  // Leaves
  VertexCount := Collector.TotalPushedVertexCount;
  side := RVector3.ZERO;

  windPhase := Random;

  LeaveSize := FLeaveSize.getRandomVector;
  Leave := RHermiteSpline.Create(Position, Position + (Direction * LeaveSize.Y), -FGravityDirection * FLeaveGravity.Y, FGravityDirection * FLeaveGravity.Y);
  for leavesegment := 0 to LeaveSegments - 1 do
  begin
    sy := leavesegment / (LeaveSegments - 1);
    Tangent := Leave.getTangent(sy);
    if abs(Tangent.Y) <> 1.0 then side := RVector3.UNITY.Cross(Tangent).Normalize;
    for leavebend := 0 to LeaveSlices - 1 do
    begin
      sx := leavebend / (LeaveSlices - 1);
      pos := Leave.getPosition(sy);
      Vertex.Position := pos + (side * LeaveSize.X * (sx - 0.5));
      Vertex.Position.Y := Vertex.Position.Y + FLeaveGravity.X * sin(sx * PI);
      Vertex.Normal := Tangent.Cross(side);
      Vertex.TextureCoordinate := RVector2.Create(sx, sy);
      // Vertex.Tangent := Tangent;
      // Vertex.Binormal := side.Cross(Tangent).Normalize;
      Vertex.Custom := RVector4.Create(0, windPhase * 2 * PI, sy, 1 - sqr(sy));

      Vertex.Position := ((Vertex.Position - FPosition) * FScale) + FPosition;
      Collector.PushVertex(Vertex);

      if (leavesegment <> LeaveSegments - 1) and (leavebend <> LeaveSlices - 1) then
      begin
        Collector.PushIndex(VertexCount);
        Collector.PushIndex(VertexCount + 1 + LeaveSlices);
        Collector.PushIndex(VertexCount + 1);

        Collector.PushIndex(VertexCount);
        Collector.PushIndex(VertexCount + LeaveSlices);
        Collector.PushIndex(VertexCount + 1 + LeaveSlices);
      end;
      VertexCount := VertexCount + 1;
    end;
  end;
end;

constructor TTree.Create;
begin
  self.Scale := 1;
  self.NoLeaveAngle := PI / 12;
  self.Height := RVariedSingle.Create(10, 5);
  self.TrunkThickness := RVariedSingle.Create(0.5, 0.2);
  self.LeaveSize := RVariedVector2.Create(3, 8, 0.5, 2);
  self.LeaveCount := RVariedInteger.Create(20, 10);
  self.LeaveSegments := 7;
  self.LeaveSlices := 2;
  self.TrunkLayers := 10;
  self.TrunkSegments := 12;
  self.LeaveGravity := RVector2.Create(0.3, 15);
  ReRoll;
end;

constructor TTree.Create(Position, GroundNormal, GravityDirection : RVector3);
begin
  FPosition := Position;
  FGravityDirection := GravityDirection;
  FGroundNormal := GroundNormal;
  Create;
end;

destructor TTree.Destroy;
begin
  inherited;
end;

function TTree.GetBoundingSphere : RSphere;
begin
  Result := RSphere.CreateSphere(FRealTrunk.getPosition(0.5), FRealHeight / 2);
end;

procedure TTree.LoadLeaveTexture(const Value : string);
begin
  FLeaveDiffuse := RelativDateiPfad(Value);
  SetDirty;
end;

procedure TTree.LoadTrunkTexture(const Value : string);
begin
  FTrunkDiffuse := RelativDateiPfad(Value);
  SetDirty;
end;

procedure TTree.setHeight(const Value : RVariedSingle);
begin
  FHeight := Value;
  SetDirty;
end;

procedure TTree.setLeaveCount(const Value : RVariedInteger);
begin
  FLeaveCount := Value;
  SetDirty;
end;

procedure TTree.setLeaveGravity(const Value : RVector2);
begin
  FLeaveGravity := Value;
  SetDirty;
end;

procedure TTree.setLeaveRange(const Value : RVariedSingle);
begin
  FLeaveRange := Value;
  SetDirty;
end;

procedure TTree.setLeaveSegments(const Value : integer);
begin
  FLeaveSegments := Value;
  SetDirty;
end;

procedure TTree.setLeaveSize(const Value : RVariedVector2);
begin
  FLeaveSize := Value;
  SetDirty;
end;

procedure TTree.setLeaveSlices(const Value : integer);
begin
  FLeaveSlices := Value;
  SetDirty;
end;

procedure TTree.setNoLeaveAngle(const Value : single);
begin
  FNoLeaveAngle := Value;
  SetDirty;
end;

procedure TTree.setScale(const Value : single);
begin
  if Value = 0 then exit;
  FScale := Value;
  SetDirty;
end;

procedure TTree.setTrunkLayers(const Value : integer);
begin
  FTrunkLayer := Value;
  SetDirty;
end;

procedure TTree.setTrunkSegments(const Value : integer);
begin
  FTrunkSegments := Value;
  SetDirty;
end;

procedure TTree.setTrunkThickness(const Value : RVariedSingle);
begin
  FTrunkThickness := Value;
  SetDirty;
end;

procedure TTree.ReRoll;
begin
  randomize;
  FRandSeed := RandSeed;
  randomize;
  FLeaveRandSeed := RandSeed;
  SetDirty;
end;

{ TVegetationChunk }

destructor TVegetationChunk.Destroy;
begin
  Vertexbuffer.Free;
  Indexbuffer.Free;
  inherited;
end;

{ TVegetationObject }

procedure TVegetationObject.Clean;
begin
  FDirty := False;
end;

function TVegetationObject.Clone(ClonedObject : TVegetationObject) : TVegetationObject;
begin
  if not assigned(ClonedObject) then raise EInvalidOp.Create('TVegetationPlaceable.Clone: Tried to clone a base class!')
  else Result := ClonedObject;
  Result.FDirty := FDirty;
  Result.FRandSeed := FRandSeed;
  Result.FPosition := FPosition;
  Result.FGroundNormal := FGroundNormal;
  Result.FCastsNoShadows := FCastsNoShadows;
end;

procedure TVegetationObject.ReRoll;
begin
  randomize;
  FRandSeed := RandSeed;
  SetDirty;
end;

procedure TVegetationObject.setCastsNoShadows(const Value : boolean);
begin
  FCastsNoShadows := Value;
  SetDirty;
end;

procedure TVegetationObject.SetDirty;
begin
  FDirty := True;
end;

procedure TVegetationObject.setGroundNormal(const Value : RVector3);
begin
  FGroundNormal := Value;
  SetDirty;
end;

procedure TVegetationObject.setPosition(const Value : RVector3);
begin
  FPosition := Value;
  SetDirty;
end;

{ TVegetationMesh }

function TVegetationMesh.GetNeededBufferSize(Part : integer) : RIntVector2;
var
  MeshIndex : integer;
  Filename : string;
  Data : TCachedMeshData;
begin
  RandSeed := FRandSeed;
  BuildMeshList;
  MeshIndex := Random(FMeshList.Count);
  Filename := AbsolutePath(FMeshList[MeshIndex]);
  Data := HMeshLoaderHelper.GetMeshData(Filename);
  if not assigned(Data) then Result := RIntVector2.ZERO
  else Result := RIntVector2.Create(Data.VertexData.Count, Data.IndexData.Count);
end;

procedure TVegetationMesh.BuildMeshList;
begin
  FMeshList.Clear;
  FMeshList.AddRange(HString.Split(FMeshes, [sLineBreak, #10]));
end;

function TVegetationMesh.Clone(ClonedObject : TVegetationObject) : TVegetationObject;
begin
  if not assigned(ClonedObject) then Result := TVegetationMesh.CreateIntern
  else Result := ClonedObject;
  with (Result as TVegetationMesh) do
  begin
    FSize := self.FSize;
    FRotation := self.FRotation;
    FMeshes := self.FMeshes;
    FMeshList.AddRange(self.FMeshList);
    FMeshBuilt := self.FMeshBuilt;
    FVertexData.AddRange(self.FVertexData);
    FIndexData.AddRange(self.FIndexData);
  end;
  inherited Clone(Result);
end;

procedure TVegetationMesh.ComputeAndSave(Part : integer; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
var
  MeshIndex, VertexCount : integer;
  Filename : string;
  Data : TCachedMeshData;
  i : integer;
  FinalPosition, FinalRotation : RVector3;
  Transform, NormalTransform : RMatrix;
  FinalSize : single;
  Vertex : RVertexPositionTextureNormalCustom;
begin
  RandSeed := FRandSeed;
  MeshIndex := Random(FMeshList.Count);
  Filename := AbsolutePath(FMeshList[MeshIndex]);
  Data := HMeshLoaderHelper.GetMeshData(Filename);
  if not assigned(Data) then exit;
  FinalPosition := Position;
  FRotation.RadialVaried := False;
  FinalRotation := Rotation.getRandomVector;
  FinalSize := Size.Random * Scale / (Data.Boundings.Radius * 2);
  NormalTransform := RMatrix.CreateRotationPitchYawRoll(FinalRotation);
  Transform := RMatrix.CreateTranslation(FinalPosition) * NormalTransform * RMatrix.CreateScaling(FinalSize);
  NormalTransform := NormalTransform.Inverse.Transpose;
  VertexCount := Collector.TotalPushedVertexCount;
  for i := 0 to Data.VertexData.Count - 1 do
  begin
    Vertex := Data.VertexData[i];
    Vertex.Position := Transform * Vertex.Position;
    Vertex.Normal := NormalTransform * Vertex.Normal;
    Collector.PushVertex(Vertex);
  end;
  for i := 0 to Data.IndexData.Count - 1 do
      Collector.PushIndex(VertexCount + integer(Data.IndexData[i]));
end;

constructor TVegetationMesh.Create;
begin
  FVertexData := TList<RVertexPositionTextureNormalCustom>.Create;
  FIndexData := TList<integer>.Create;
  FMeshList := TList<string>.Create;
end;

constructor TVegetationMesh.CreateIntern;
begin
  inherited CreateIntern;
  Create;
  self.Rotation := RVariedVector3.Create(RVector3.ZERO, RVector3.Create(0, PI, 0));
  self.Size := RVariedSingle.Create(0.5, 0.1);
  self.Scale := 2.0;
  ReRoll;
end;

destructor TVegetationMesh.Destroy;
begin
  FVertexData.Free;
  FIndexData.Free;
  FMeshList.Free;
  inherited;
end;

function TVegetationMesh.GetBoundingSphere : RSphere;
begin
  Result := RSphere.CreateSphere(FPosition, Scale * Size.Mean);
end;

procedure TVegetationMesh.setRotation(const Value : RVariedVector3);
begin
  FRotation := Value;
  SetDirty;
end;

procedure TVegetationMesh.setSize(const Value : RVariedSingle);
begin
  FSize := Value;
  SetDirty;
end;

{ TGrassTuft }

function TGrassTuft.Clone(ClonedObject : TVegetationObject) : TVegetationObject;
begin
  if not assigned(ClonedObject) then Result := TGrassTuft.CreateIntern
  else Result := ClonedObject;
  with (Result as TGrassTuft) do
  begin
    FNormalAdjustment := self.FNormalAdjustment;
    FMidOffset := self.FMidOffset;
    FTrapezial := self.FTrapezial;
    FAngle := self.FAngle;
    FSize := self.FSize;
  end;
  inherited Clone(Result);
end;

procedure TGrassTuft.ComputeAndSave(Part : integer; Collector : TIndexedVertexDataCollector<RVertexPositionTextureNormalCustom, Cardinal>);
const
  GRASSSHIELDS = 3;
var
  VertexCount, i : integer;
  rAngle, Rotation, realTrapezial, timeOffset : single;
  realSize : RVector2;
  side, top, front, lt, rt, lb, rb, temp : RVector3;
  Vertex : RVertexPositionTextureNormalCustom;
begin
  RandSeed := FRandSeed;
  VertexCount := Collector.TotalPushedVertexCount;
  Rotation := Random * 2 * PI;

  top := FGroundNormal;
  side := top.GetArbitaryOrthogonalVector.Normalize;
  front := top.Cross(side).Normalize;
  top := top.RotateAxis(side, Angle.Random - PI / 2).Normalize;
  FSize.RadialVaried := False;
  realSize := Size.getRandomVector;
  realTrapezial := Trapezial.Random - 0.5;
  timeOffset := Random;

  for i := 0 to GRASSSHIELDS - 1 do
  begin
    rAngle := (i / GRASSSHIELDS) * 2 * PI + Rotation;

    Vertex.Normal := top.Cross(side).Normalize.RotateAxis(FGroundNormal, rAngle).Lerp(FGroundNormal, NormalAdjustment).Normalize;
    // Vertex.Tangent := RVector3.ZERO;
    // Vertex.Binormal := RVector3.ZERO;

    lt := ((side * realSize.X / 2 + top * realSize.Y + front * realSize.X * FMidOffset / 2) * FScale).RotateAxis(FGroundNormal, rAngle) + FPosition;
    rt := ((-side * realSize.X / 2 + top * realSize.Y + front * realSize.X * FMidOffset / 2) * FScale).RotateAxis(FGroundNormal, rAngle) + FPosition;
    lb := ((side * realSize.X / 2 + front * realSize.X * FMidOffset / 2) * FScale).RotateAxis(FGroundNormal, rAngle) + FPosition;
    rb := ((-side * realSize.X / 2 + front * realSize.X * FMidOffset / 2) * FScale).RotateAxis(FGroundNormal, rAngle) + FPosition;

    temp := lt;
    lt := lt.Lerp(rt, realTrapezial);
    rt := rt.Lerp(temp, realTrapezial);

    // lt
    Vertex.Position := lt;
    Vertex.TextureCoordinate := RVector2.Create(0, 0);
    Vertex.Custom := RVector4.Create(timeOffset, 0, 1, 1);
    Collector.PushVertex(Vertex);
    // rt
    Vertex.Position := rt;
    Vertex.TextureCoordinate := RVector2.Create(1, 0);
    Vertex.Custom := RVector4.Create(timeOffset, 0, 1, 1);
    Collector.PushVertex(Vertex);
    // lb
    Vertex.Position := lb;
    Vertex.TextureCoordinate := RVector2.Create(0, 1);
    Vertex.Custom := RVector4.Create(timeOffset, 0, 0, 1);
    Collector.PushVertex(Vertex);
    // rb
    Vertex.Position := rb;
    Vertex.TextureCoordinate := RVector2.Create(1, 1);
    Vertex.Custom := RVector4.Create(timeOffset, 0, 0, 1);
    Collector.PushVertex(Vertex);

    Collector.PushIndex(VertexCount);
    Collector.PushIndex(VertexCount + 2);
    Collector.PushIndex(VertexCount + 1);

    Collector.PushIndex(VertexCount + 1);
    Collector.PushIndex(VertexCount + 2);
    Collector.PushIndex(VertexCount + 3);

    VertexCount := VertexCount + 4;
  end;
end;

constructor TGrassTuft.CreateIntern;
begin
  inherited CreateIntern;
  self.Trapezial := RVariedSingle.Create(0.5, 0);
  self.Angle := RVariedSingle.Create(PI / 2, PI / 32);
  self.Size := RVariedVector2.Create(0.5, 0.5, 0.3, 0.3);
  self.MidOffset := 0.572;
  self.NormalAdjustment := 1.0;
  ReRoll;
end;

function TGrassTuft.GetBoundingSphere : RSphere;
begin
  Result := RSphere.CreateSphere(FPosition, Scale * Size.Mean.MaxAbsValue);
end;

function TGrassTuft.GetNeededBufferSize(Part : integer) : RIntVector2;
begin
  Result := RIntVector2.Create(4 * 3, 3 * 2 * 3);
end;

procedure TGrassTuft.setAngle(const Value : RVariedSingle);
begin
  FAngle := Value;
  SetDirty;
end;

procedure TGrassTuft.setMidOffset(const Value : single);
begin
  FMidOffset := Value;
  SetDirty;
end;

procedure TGrassTuft.setNormalAdjustment(const Value : single);
begin
  FNormalAdjustment := Value;
end;

procedure TGrassTuft.setSize(const Value : RVariedVector2);
begin
  FSize := Value;
  SetDirty;
end;

procedure TGrassTuft.setTrapezial(const Value : RVariedSingle);
begin
  FTrapezial := Value;
  SetDirty;
end;

{ TVegetationPlaceable }

constructor TVegetationPlaceable.CreateIntern;
begin
  self.Scale := 3.2;
end;

function TVegetationPlaceable.Clone(ClonedObject : TVegetationObject) : TVegetationObject;
begin
  if not assigned(ClonedObject) then raise EInvalidOp.Create('TVegetationPlaceable.Clone: Tried to clone a base class!')
  else Result := ClonedObject;
  with (Result as TVegetationPlaceable) do
  begin
    FScale := self.FScale;
    FDiffuse := self.FDiffuse;
  end;
  inherited Clone(Result);
end;

constructor TVegetationPlaceable.Create(Position, Normal : RVector3);
begin
  FPosition := Position;
  FGroundNormal := Normal;
  CreateIntern;
end;

function TVegetationPlaceable.GetPartCount : integer;
begin
  Result := 1;
end;

function TVegetationPlaceable.GetPartTexture(Part : integer) : RVegetationTexture;
begin
  Result := RVegetationTexture.Create(Diffuse, True, False, not FCastsNoShadows);
end;

procedure TVegetationPlaceable.LoadDiffuseTexture(const Value : string);
begin
  FDiffuse := RelativDateiPfad(Value);
  SetDirty;
end;

procedure TVegetationPlaceable.setScale(const Value : single);
begin
  FScale := Value;
  SetDirty;
end;

{ RVegetationTexture }

constructor RVegetationTexture.Create(Texture : string; AlphaTested, FlipCullNormals, CastsShadows : boolean);
begin
  self.Texture := Texture;
  self.AlphaTested := AlphaTested;
  self.FlipCullNormals := FlipCullNormals;
  self.CastsShadows := CastsShadows;
end;

class operator RVegetationTexture.equal(a, b : RVegetationTexture) : boolean;
begin
  Result := (a.AlphaTested = b.AlphaTested) and
    (a.FlipCullNormals = b.FlipCullNormals) and
    (a.Texture = b.Texture) and
    (a.CastsShadows = b.CastsShadows);
end;

function RVegetationTexture.Hash : integer;
begin
  Result := THashBobJenkins.GetHashValue(self.Texture);
  if self.AlphaTested then inc(Result);
  if self.FlipCullNormals then inc(Result, 4);
  if self.CastsShadows then inc(Result, 8);
end;

{ RVertexPositionNormalTextureCustomTangentBinormal }

class function RVertexPositionTextureNormalCustom.BuildVertexdeclaration() : TVertexdeclaration;
begin
  if not assigned(FDeclaration) then
  begin
    FDeclaration := TVertexdeclaration.CreateVertexDeclaration(GFXD.Device3D);
    FDeclaration.AddVertexElement(etFloat3, euPosition);
    FDeclaration.AddVertexElement(etFloat2, euTexturecoordinate);
    FDeclaration.AddVertexElement(etFloat3, euNormal);
    FDeclaration.AddVertexElement(etFloat4, euTexturecoordinate, emDefault, 0, 1);
    FDeclaration.EndDeclaration;
  end;
  Result := FDeclaration;
end;

{ HMeshLoaderHelper }

class function HMeshLoaderHelper.CalculateBoundings(InData : TList<RVertexPositionTextureNormalCustom>) : RSphere;
var
  j, positioncount : integer;
  VertexPosition : RVector3;
begin
  if InData.Count <= 0 then exit(RSphere.ZERO);
  VertexPosition := InData[0].Position;
  Result := RSphere.CreateSphere(VertexPosition, 0);
  positioncount := 1;
  for j := 1 to InData.Count - 1 do
  begin
    VertexPosition := InData[j].Position;
    Result.Center := Result.Center + VertexPosition;
    inc(positioncount);
  end;
  Result.Center := Result.Center / positioncount;
  for j := 0 to InData.Count - 1 do
  begin
    VertexPosition := InData[j].Position;
    Result.Radius := Max(Result.Radius, Result.Center.Distance(VertexPosition));
  end;
end;

class procedure HMeshLoaderHelper.ComputeIndexedVertexData(InData, IndexedVertexData : TList<RVertexPositionTextureNormalCustom>; IndexedIndexData : TList<LongWord>);
var
  VertexTable : TDictionary<RVertexPositionTextureNormalCustom, integer>;
  index, i : integer;
begin
  VertexTable := TDictionary<RVertexPositionTextureNormalCustom, integer>.Create(
    TEqualityComparer<RVertexPositionTextureNormalCustom>.Construct(
    function(const Left, Right : RVertexPositionTextureNormalCustom) : boolean
    begin
      Result := Left.Position.SimilarTo(Right.Position) and Left.Normal.SimilarTo(Right.Normal) and Left.TextureCoordinate.SimilarTo(Right.TextureCoordinate, 0.00001);
    end,
    function(const Value : RVertexPositionTextureNormalCustom) : integer
    begin
      Result := Value.Position.GetHashValue xor Value.Normal.GetHashValue xor Value.TextureCoordinate.GetHashValue;
    end));
  // build indextable and fill array with data
  index := 0;
  IndexedVertexData.Count := InData.Count;
  // set arraylength to max possible length, will adjust them later
  IndexedIndexData.Count := InData.Count;
  for i := 0 to InData.Count - 1 do
  begin
    if not VertexTable.ContainsKey(InData[i]) then
    begin
      VertexTable.Add(InData[i], index);
      IndexedIndexData[i] := index;
      IndexedVertexData[index] := InData[i];
      inc(index);
    end
    else IndexedIndexData[i] := VertexTable[InData[i]];
  end;
  IndexedVertexData.Count := index;
  VertexTable.Free;
end;

class constructor HMeshLoaderHelper.Create;
begin
  FData := TObjectDictionary<string, TCachedMeshData>.Create([doOwnsValues]);
end;

class destructor HMeshLoaderHelper.Destroy;
begin
  FData.Free;
end;

class function HMeshLoaderHelper.GetMeshData(Filename : string) : TCachedMeshData;
begin
  if LOAD_RAW_MESH then
      Filename := TEngineRawMesh.ConvertFileNameToRaw(Filename);
  LoadAndConvertMesh(Filename);
  if not FData.TryGetValue(Filename, Result) then Result := nil;
end;

class procedure HMeshLoaderHelper.LoadAndConvertMesh(Filename : string);
var
  MeshAsset : TMeshAsset;
  sourceData : TMeshAssetSubset;
  IndexData : TList<LongWord>;
  VertexData, IndexedVertexData : TList<RVertexPositionTextureNormalCustom>;
  Data : TCachedMeshData;
  meshTransformIT : RMatrix;
  i : integer;
  Vertex : RVertexPositionTextureNormalCustom;
  RawMesh : TEngineRawMesh;
  FileStream : TStream;
begin
  if FData.ContainsKey(Filename) then exit;
  if not FileExists(Filename) then
  begin
    HLog.Write(elWarning, 'HMeshLoaderHelper.LoadAndConvertMesh: File %s does not exist!', [Filename]);
    exit;
  end;
  if SameText(ENGINEMESH_FORMAT_EXTENSION, ExtractFileExt(Filename)) then
  begin
    Filename := TEngineRawMesh.ConvertFileNameToRaw(Filename);
    FileStream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
    try
      RawMesh := TEngineRawMesh.CreateFromStream(FileStream);
      if Length(RawMesh.VertexData) > 0 then
      begin
        Data := TCachedMeshData.Create;
        Data.IndexData := TList<LongWord>.Create;
        Data.IndexData.AddRange(RawMesh.IndexData);
        Data.Boundings := RawMesh.BoundingSphere;
        Data.VertexData := TList<RVertexPositionTextureNormalCustom>.Create;
        Data.VertexData.Capacity := Length(RawMesh.VertexData);
        assert(Length(RawMesh.VertexData) = Length(RawMesh.ColorData));
        for i := 0 to Length(RawMesh.VertexData) - 1 do
        begin
          Vertex.Position := RawMesh.VertexData[i].Position[0];
          Vertex.TextureCoordinate := RawMesh.VertexData[i].TextureCoordinate;
          Vertex.Normal := RawMesh.VertexData[i].Normal;
          Vertex.Custom := RawMesh.ColorData[i];
          Data.VertexData.Add(Vertex);
        end;
        FData.Add(Filename, Data);
      end;
      RawMesh.Free;
    finally
      FileStream.Free;
    end;
  end
  else
  begin
    MeshAsset := TAssetManager.LoadMesh(Filename);

    // first collapse all subsets of the mesh into one giant subset
    if MeshAsset.SubsetCount > 1 then
        MeshAsset.CollapseSubsets(True);

    // process all data to build buffers and animation data
    if MeshAsset.SubsetCount >= 1 then
    begin
      Data := TCachedMeshData.Create;
      IndexData := TList<LongWord>.Create;
      VertexData := TList<RVertexPositionTextureNormalCustom>.Create;
      // Build data from base mesh, ignoring morphtargets
      sourceData := MeshAsset.Subsets[0];

      // load all verticesdata into array
      VertexData.Count := sourceData.VertexCount;
      for i := 0 to sourceData.VertexCount - 1 do
      begin
        Vertex.Position := sourceData.VertexPositions[i];

        if sourceData.HasNormals then Vertex.Normal := sourceData.Normals[i].Normalize
        else Vertex.Normal := RTriangle.Create(sourceData.VertexPositions[i div 3], sourceData.VertexPositions[(i div 3) + 1], sourceData.VertexPositions[(i div 3) + 2]).GetNormal;
        if sourceData.HasTextureCoordinates then Vertex.TextureCoordinate := sourceData.TextureCoordinate[i]
        else Vertex.TextureCoordinate := RVector2.ZERO;
        if sourceData.HasColor then Vertex.Custom := sourceData.Colors[i]
        else Vertex.Custom := RVector4.ZERO;

        VertexData[i] := Vertex;
      end;

      // apply mesh offset matrix directly to the vertices, so even unanimated it is correctly displayed
      meshTransformIT := sourceData.MeshOffsetMatrix.Get3x3.Inverse.Transpose;
      for i := 0 to VertexData.Count - 1 do
      begin
        Vertex := VertexData[i];
        Vertex.Position := sourceData.MeshOffsetMatrix * Vertex.Position;
        Vertex.Normal := (meshTransformIT * Vertex.Normal).Normalize;
        VertexData[i] := Vertex;
      end;

      IndexedVertexData := TList<RVertexPositionTextureNormalCustom>.Create;
      // compute indexing for vertexdata
      ComputeIndexedVertexData(VertexData, IndexedVertexData, IndexData);
      VertexData.Free;

      Data.Boundings := CalculateBoundings(IndexedVertexData);
      Data.VertexData := IndexedVertexData;
      Data.IndexData := IndexData;
      FData.Add(Filename, Data);
    end;
    MeshAsset.Free;
  end;
end;

{ TCachedMeshData }

destructor TCachedMeshData.Destroy;
begin
  VertexData.Free;
  IndexData.Free;
  inherited;
end;

initialization

TTree.ClassName;
TGrassTuft.ClassName;
TVegetationMesh.ClassName;

end.

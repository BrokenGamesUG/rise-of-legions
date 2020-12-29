unit Engine.Mesh;

interface

uses
  // ========= Delphi =========
  System.SysUtils,
  System.Contnrs,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Rtti,
  System.Math,
  System.StrUtils,
  System.Classes,
  Vcl.Forms,
  Vcl.Dialogs,
  // ========= Third-Party =====
  WinApi.Windows,
  Xml.XMLIntf,
  // ========= Engine ========
  Engine.Collision,
  Engine.Math.Collision3D,
  Engine.Log,
  Engine.Core,
  Engine.Core.Mesh,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Helferlein.DataStructures,
  Engine.Helferlein.VCLUtils,
  Engine.Math,
  Engine.Serializer.Types,
  Engine.Serializer,
  Engine.Core.Types,
  Engine.Vertex,
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Animation,
  Engine.AssetLoader,
  Engine.AssetLoader.MeshAsset,
  Engine.AssetLoader.XFileLoader,
  Engine.AssetLoader.AssimpLoader,
  Engine.AssetLoader.FBXLoader;

const
  // Maximum number of bones for hardware skinning
  HW_MAX_BONES = 66;

type
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  EUnknownMeshFormat = class(Exception);
  EAnimationNotFound = class(Exception);
  EMeshError = class(Exception);

type

  TSkinnedMeshAnimationDriver = class;
  TMeshMorphAnimationDriver = class;

  TMeshAnimatedGeometry = class(TDeviceManagedObject)
    protected type
      AVertexData = AVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight;
      AIndexData = TArray<LongWord>;
      TBone = class;
      /// <summary> Maps from old bone reference to new bone reference.</summary>
      TBoneMapping = TDictionary<TBone, TBone>;

      TBone = class
        private const
          MAX_ANIMATIONS_PER_FRAME = 10;
        private type
          RWeightedBoneAnimation = record
            Translation : RVector3;
            Scale : RVector3;
            Rotation : RQuaternion;
            Weight : single;
          end;
        private
          // constant array saves all animations for this bone for one frame
          FBoneAnimations : array [0 .. MAX_ANIMATIONS_PER_FRAME - 1] of RWeightedBoneAnimation;
          // counts current added WeightedBoneAnimations in FBoneAnimations
          FBoneAnimationsCount : integer;
          // if true, animation is used from the set matrix and all data set in FBoneAnimations is ignored
          FOverwriteAnimation : boolean;
          FOverwriteTransformation : RMatrix4x3;
          // key to identifie if a new frame is computed or not
          FLastFrameKey : int64;
          FBoneLookup : TDictionary<string, TBone>;
          procedure ClearAnimatedMatricesIfOld; inline;
        public
          Name : string;
          CombinedMatrix : RMatrix4x3;
          OriginalMatrix : RMatrix4x3;
          ChildBones : TArray<TBone>;
          function GetBoneByName(const BoneName : string) : TBone;
          constructor Create(Source : TMeshAssetBone); overload;
          constructor Create(Data : TList<REngineRawMeshBone>); overload;
          constructor Create(); overload;
          procedure PassAnimationToHierarchy(const ParentMatrix : RMatrix4x3);
          /// <summary> Add a matrix to bone.
          /// <param name="Matrix"> Matrix to add</param>
          /// <param name="Weight"> Weight in range 0..1. Determine how many matrices influence bone.</param></summary>
          procedure AddBoneAnimation(const Translation, Scale : RVector3; const Rotation : RQuaternion; Weight : single);
          /// <summary> Will overwrite the complete animation of this bone and set the transformation as the only transformation
          /// of this bone. The overwrite will only work for one frame, after that the complete status is reseted.</summary>
          procedure OverwriteBoneAnimation(const Tranformation : RMatrix4x3);
          /// <summary> Creates and return a copy of a bone including all childbones.
          /// <param name="BoneMapping"> Dict in which the mapping will saved.</param></summary>
          function GetCopy(var BoneMapping : TBoneMapping) : TBone;
          /// <summary> Flatten the bone structure to array list. On top current bone and following child and subchilds.</summary>
          function ToArray : TArray<TBone>;
          destructor Destroy; override;
      end;

      RSkinBoneLink = record
        BoneSpaceOffsetMatrix : RMatrix4x3;
        TargetBone : TBone;
      end;

      TSkin = class
        private
          FSkinBoneLinks : TArray<TMeshAnimatedGeometry.RSkinBoneLink>;
          FOutDataComputeAnimatedMatrix : TArray<RMatrix4x3>;
        public
          constructor Create(SkinBoneLinkCount : integer);
          /// <summary> Creates a copy of instance and replace bone with new bones using bonemapping.</summary>
          function GetCopy(BoneMapping : TBoneMapping) : TSkin;
          function ComputeAnimatedMatrices : TArray<RMatrix4x3>;
      end;
    protected
      FRootBone : TBone;
      FFaceCount : integer;
      FVerticesCount : integer;
      FVertexBuffer : TVertexBuffer;
      FIndexBuffer : TIndexBuffer;
      FSkin : TSkin;
      FBoundingSphere : RSphere;
      FBoundingBox : RAABB;
      FSkinAnimationDriver : TSkinnedMeshAnimationDriver;
      FMorphAnimationdriver : TMeshMorphAnimationDriver;
      FMorphtargetCount : integer;
      FFileName : string;
      function GetFileName : string;
      procedure CalculateBoundings(VertexData : AVertexData);
      procedure ComputeSmoothedNormals(VertexData : AVertexData);
      procedure ComputeTangentsAndBinormals(VertexData : AVertexData; IndexData : AIndexData);
      procedure ComputeIndexedVertexData(InVertexData : AVertexData; InColorData : TArray<RVector4>; out IndexedVertexData : AVertexData; out IndexedIndexData : AIndexData; out IndexedColorData : TArray<RVector4>);
      procedure LoadData(const Filepath : string);
      procedure LoadRawMeshData(const Filepath : string);
      constructor CreateFromFileIntern(FileName : string; GFXD : TGFXD);
    public
      property SkinAnimationDriver : TSkinnedMeshAnimationDriver read FSkinAnimationDriver;
      property MorphAnimationDriver : TMeshMorphAnimationDriver read FMorphAnimationdriver;
      /// <summary> Returns filename for meshgeometrie. If not from file loaded, returns '' (empty string)</summary>
      property FileName : string read GetFileName;
      property BoundingSphere : RSphere read FBoundingSphere;
      property BoundingBox : RAABB read FBoundingBox;
      class function CreateFromFile(FileName : string; GFXD : TGFXD) : TMeshAnimatedGeometry;
      procedure Render(SubsetIndex : integer = 0);
      destructor Destroy; override;
  end;

  TSkinnedMeshAnimationDriver = class(TAnimationDriver)
    protected type
      // using here records for encapsulated structures, because in my opinion there
      // is to much data to give constructors to take with them like FTargetGeometry etc. and
      // so I decided to set up data at one postion (in TSkinnedMeshAnimationData.Create)
      RSkinnedMeshKeyFrame = record
        PointInTime : single;
        Translation : RVector3;
        Scale : RVector3;
        Rotation : RQuaternion;
      end;

      RSkinnedMeshSubAnimationData = record
        TargetBone : TMeshAnimatedGeometry.TBone;
        KeyFrames : array of RSkinnedMeshKeyFrame;
        procedure UpdateAnimation(Timekey : single; Direction : integer; Weight : single);
      end;

      TSkinnedMeshAnimationData = class(TAnimationData)
        protected
          SubAnimationData : array of RSkinnedMeshSubAnimationData;
        public
          constructor Create(Name : string; DefaultLength : int64; Data : TMeshAssetAnimationBone; RootBone : TMeshAnimatedGeometry.TBone); overload;
          /// <summary> Empty constructor for copy animation data.</summary>
          constructor Create(); overload;
          procedure UpdateAnimation(const Timekey : RTimeframe; Direction : integer; Weight : single); override;
          function ExtractPart(StartFrame, EndFrame : integer) : TAnimationData; override;
          function Clone : TAnimationData; override;
          destructor Destroy; override;
      end;
    protected
      FSkin : TMeshAnimatedGeometry.TSkin;
      FRootBone : TMeshAnimatedGeometry.TBone;
      FOwnsSkinAndRootBone : boolean;
      constructor Create(TargetGeometry : TMeshAnimatedGeometry; AnimationData : TArray<TMeshAssetAnimationBone>); overload;
      procedure UpdateAnimation(const Animation : string; const Timekey : RTimeframe; Direction : integer; Weight : single); override;
      procedure SetShaderSettings(RenderContext : TRenderContext); override;
      function GenerateShaderBitmask(CurrentStatus : EnumAnimationState) : SetDefaultShaderFlags; override;
      function HasSkin : boolean;
      function GetCopy : TSkinnedMeshAnimationDriver;
      procedure UpdateWithoutAnimation; override;
    public
      property RootBone : TMeshAnimatedGeometry.TBone read FRootBone;
      property Skin : TMeshAnimatedGeometry.TSkin read FSkin;
      procedure ImportAnimationFromFile(const FileName : string; const OverrideName : string = ''); override;
      destructor Destroy; override;
  end;

  TMeshMorphAnimationDriver = class(TAnimationDriver)
    protected type
      RMorphKeyFrame = record
        PointInTime : single;
        Weight : single;
        function Lerp(itemB : RMorphKeyFrame; Factor : single) : RMorphKeyFrame;
      end;

      TMorphAnimationData = class(TAnimationData)
        protected
          FCurves : TObjectDictionary<integer, TList<RMorphKeyFrame>>;
          FCurrentMorphweights : array [0 .. MAX_MORPH_TARGET_COUNT - 1] of single;
          procedure DoClone(Clone : TAnimationData); override;
          constructor Create; overload;
        public
          constructor Create(MorphData : TMeshAssetAnimationMorph; MorphtargetMapping : TArray<string>); overload;
          constructor CreateSlice(StartFrame, EndFrame : integer; Curves : TObjectDictionary < integer, TList < RMorphKeyFrame >> );
          procedure UpdateAnimation(const Timeframe : RTimeframe; Direction : integer; Weight : single); override;
          function ExtractPart(StartFrame, EndFrame : integer) : TAnimationData; override;
          function Clone : TAnimationData; override;
          destructor Destroy; override;
      end;
    protected
      FMorphtargetCount : integer;
      FCurrentMorphweights : array [0 .. MAX_MORPH_TARGET_COUNT - 1] of single;
      FLastFrameKey : int64;
      function HasMorph : boolean;
      constructor Create(TargetGeometry : TMeshAnimatedGeometry; AnimationData : TArray<TMeshAssetAnimationMorph>; MorphtargetMapping : TArray<string>); overload;
      procedure SetShaderSettings(RenderContext : TRenderContext); override;
      function GenerateShaderBitmask(CurrentStatus : EnumAnimationState) : SetDefaultShaderFlags; override;
      procedure UpdateWithoutAnimation; override;
      procedure UpdateAnimation(const Animation : string; const Timeframe : RTimeframe; Direction : integer; Weight : single); override;
      procedure ClearDataIfOld;
      function GetCopy : TMeshMorphAnimationDriver;
    public
      procedure ImportAnimationFromFile(const FileName : string; const OverrideName : string = ''); override;
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

  ProcSetUpShader = reference to procedure(CurrentShader : TShader; Stage : EnumRenderStage; PassIndex : integer);

  RMeshShader = record
    public
      Shader : string;
      SetUp : ProcSetUpShader;
      NeedsOwnPass : SetRenderStage;
      OwnPasses : integer;
      OwnPassHideOriginal : boolean;
      /// <summary> Only working in own pass. </summary>
      BlendMode : EnumBlendMode;
      Tag : NativeUInt;
      constructor Create(const ShaderPath : string; SetUp : ProcSetUpShader; NeedsOwnPass : SetRenderStage = []; OwnPasses : integer = 0; OwnPassHideOriginal : boolean = False; BlendMode : EnumBlendMode = BlendLinear; Tag : NativeUInt = 0);
      function RendersInOwnPass : boolean;
  end;

  /// <summary> Meshdata without any transfromation like translation or scale. With this property all visual data can adjust
  /// like textures or meshcolor overlay.</summary>
  [XMLIncludeAll([XMLIncludeProperties])]
  TRawMesh = class(TWorldObject)
    private
      function GetFurTexture : string;
      function GetMaterialTexture : string;
      function GetNormalTexture : string;
      function GetDiffuseTexture : string;
      function GetGlowTexture : string;
      procedure SetFurTexture(Value : string);
      procedure SetGlowTexture(Value : string);
      procedure SetMaterialTexture(Value : string);
      procedure SetNormalTexture(Value : string);
      procedure SetDiffuseTexture(Value : string);
    protected
      FFilePath : string;
      FDiffuseTexture : TTexture;
      FNormalTexture : TTexture;
      FMaterialTexture : TTexture;
      FGlowTexture : TTexture;
      FRootFilePath : string;
      FShowRealPath : boolean;
      FTransformationMatrix : RMatrix4x3;
      FMorphtargetCount : integer;
      FColorAdjustment : RVector3;
      FTextureAlpha : boolean;
      FAlpha : single;
      FAlphaTestTreshold : single;
      FGeometry : TMeshAnimatedGeometry;
      FAnimationDriverBone : TSkinnedMeshAnimationDriver;
      FAnimationDriverMorph : TMeshMorphAnimationDriver;
      FMaterial : boolean;
      FSpecularIntensity, FShadingReduction, FSpecularTint : single;
      FSpecularPower : Word;
      FCullmode, FFurCullmode : EnumCullmode;
      FAnimationController : TAnimationController;
      FOutline, FOnlyOutline : boolean;
      FOutlineColor, FColorOverride : RColor;
      FFurIterations : integer;
      FFurThickness : single;
      FFurTrackBone : string;
      FFurTexture : TTexture;
      FFurTrackLastPosition, FFurTrackVector, FFurAcceleration, FFurVelocity : RVector3;
      FFurAttenuation, FFurResponsivness, FFurAccelerationFactor, FFurAccelerationResponsivness, FFurMovementLength, FFurGravitation : single;
      /// <summary> Generate a bitmask that sets all nessecary shaderflags. Will not
      /// include bitmask for geometry.</summary>
      function GenerateShaderBitmask(Stage : EnumRenderStage) : SetDefaultShaderFlags; virtual;
      function GetTextureFileName(const SourceTexture : TTexture) : string;
      function DrawsAtStage : SetRenderStage; override;
      /// <summary> Sets all settings by shaderbitmask and sends geometrie to graphiccard.</summary>
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
      procedure RenderShadowContribution(RenderContext : TRenderContext); virtual;
      procedure SetColorAdjustment(const Value : RVector3);
      function GetColorAdjustment : RVector3;
      function HasMaterialSettings : boolean;
      function HasColorOverride : boolean;
      procedure SetAlpha(Value : single);
      procedure SetAlphaTestTreshold(Value : single);
      procedure SetDefaultMaterialSettings;
      procedure Init;
      procedure SetGeometryFile(Value : string); virtual;
      function GetGeometryFile : string;
      procedure LoadData(const Filepath : string);
      function GetScale() : single; virtual; abstract;
      function ResolveShaderArray : AString;
    public
      /// <summary> Replaces the resulting color with this color in HSV-Colorspace. The booleans determines which components are overwritten. </summary>
      AbsoluteHSV : RVector3;
      AbsoluteColorAdjustmentH, AbsoluteColorAdjustmentS, AbsoluteColorAdjustmentV : boolean;
      /// <summary> This is used, if shading reduction is zero. Useful for global shading reduction settings. </summary>
      ShadingReductionOverride : single;
      /// <summary> Sets a custom shader for rendering this model. The custom shader have to derive from the standardshader. </summary>
      CustomShader : TList<RMeshShader>;
      /// <summary> Controller for any animated content (textures, geometry) assigned.
      /// Controller owned by mesh, so if any extern targets added controller can't used
      /// after free mesh.</summary>
      [XMLExcludeElement]
      property AnimationController : TAnimationController read FAnimationController;
      [XMLExcludeElement]
      property AnimationDriverBone : TSkinnedMeshAnimationDriver read FAnimationDriverBone;
      [XMLExcludeElement]
      property AnimationDriverMorph : TMeshMorphAnimationDriver read FAnimationDriverMorph;
      /// <summary> Geometrydata used to render mesh. If new data is set, collidabledata
      /// will be updated. Any material information from geometry, if any will be ignored.</summary>
      property GeometryFile : string read GetGeometryFile write SetGeometryFile;
      /// <summary> Forces the Mesh to render with alpha if the texture contains alpha-information. </summary>
      [VCLBooleanField]
      property TextureSemiTransparency : boolean read FTextureAlpha write FTextureAlpha;
      /// <summary> Defines winding orders that may be used to identify back faces for culling.</summary>
      [VCLEnumField]
      property Cullmode : EnumCullmode read FCullmode write FCullmode;
      /// <summary> Alpha value for mesh describing opacity. Value Range [0.0,1.0].
      /// Value 1 = complete opaque, 0 = complete transparent. If Value = 1, alpharendering is disabled.</summary>
      [VCLSingleField(1.0)]
      property Alpha : single read FAlpha write SetAlpha;
      /// <summary> Alphatest value to discard all pixels with alphavalue below AlphaTestTreshold. Value Range [0.0,1.0].
      /// If value = 0, alphatest is disabled. </summary>
      [VCLSingleField(1.0)]
      property AlphaTestTreshold : single read FAlphaTestTreshold write SetAlphaTestTreshold;
      /// <summary> If > 0, Specular is enabled, Values from SpecularColor and SpecularPower are used</summary>
      [VCLSingleField(1.0)]
      property SpecularIntensity : single read FSpecularIntensity write FSpecularIntensity;
      /// <summary> Control the size of the highlight for specular. Higher values creates a smaller highlight.
      /// Commonly value is <= 255</summary>
      [VCLIntegerField(0, 255)]
      property SpecularPower : Word read FSpecularPower write FSpecularPower;
      [VCLSingleField(1.0)]
      property SpecularTint : single read FSpecularTint write FSpecularTint;
      [VCLSingleField(1.0)]
      property ShadingReduction : single read FShadingReduction write FShadingReduction;
      /// <summary> Adds this HSV-Vector on the resulting color. So it's useful for color transfer or lighting up the mesh.</summary>
      [XMLExcludeElement]
      property ColorAdjustment : RVector3 read GetColorAdjustment write SetColorAdjustment;
      /// <summary> Replaces the diffuse of the mesh with this color if it is not transparent black.</summary>
      [XMLExcludeElement]
      property ColorOverride : RColor read FColorOverride write FColorOverride;
      /// <summary> Set and Get textureFileName for DiffuseTetxure. If no texture set, property returns '' (empty String).
      /// Set a textureFileName will load this file. If file not exist, No texture now assigned to DiffuseTetxure.</summary>
      [VCLFileField]
      property DiffuseTetxure : string read GetDiffuseTexture write SetDiffuseTexture;
      /// <summary> Set and Get textureFileName for NormalTexture. If no texture set, property returns '' (empty String).
      /// Set a textureFileName will load this file. If file not exist, No texture now assigned to NormalTexture.</summary>
      [VCLFileField]
      property NormalTexture : string read GetNormalTexture write SetNormalTexture;
      /// <summary> Set and Get textureFileName for SpecularTexture. If no texture set, property returns '' (empty String).
      /// Set a textureFileName will load this file. If file not exist, No texture now assigned to SpecularTexture.
      /// SpecularTexture controls where specular is shown, e.g. an armor should shine but not the skin of the warrior.
      /// Channelmapping: argb = (Shading Reduction, Specularintensity, Specularpower, Specular Tinting)</summary>
      [VCLFileField]
      property SpecularTexture : string read GetMaterialTexture write SetMaterialTexture;
      /// <summary> If this is set, the mesh will be drawn at the glow stage. </summary>
      [VCLFileField]
      property GlowTexture : string read GetGlowTexture write SetGlowTexture;
      property Outline : boolean read FOutline write FOutline;
      property OutlineColor : RColor read FOutlineColor write FOutlineColor;
      property OnlyOutline : boolean read FOnlyOutline write FOnlyOutline;
      function HasFur : boolean;
      [VCLEnumField]
      property FurCullmode : EnumCullmode read FFurCullmode write FFurCullmode;
      /// <summary> If this is set, the mesh will be drawn additionally at the effect stage with fur. </summary>
      [VCLFileField]
      property FurTexture : string read GetFurTexture write SetFurTexture;
      [VCLIntegerField(0, 64)]
      property FurIterations : integer read FFurIterations write FFurIterations;
      [VCLSingleField(isEdit)]
      property FurThickness : single read FFurThickness write FFurThickness;
      [VCLStringField]
      property FurTrackBone : string read FFurTrackBone write FFurTrackBone;
      [VCLSingleField(isEdit)]
      property FurResponsivness : single read FFurResponsivness write FFurResponsivness;
      [VCLSingleField(isEdit)]
      property FurAcceleration : single read FFurAccelerationFactor write FFurAccelerationFactor;
      [VCLSingleField(isEdit)]
      property FurAccelerationResponsivness : single read FFurAccelerationResponsivness write FFurAccelerationResponsivness;
      [VCLSingleField(isEdit)]
      property FurAttenuation : single read FFurAttenuation write FFurAttenuation;
      [VCLSingleField(isEdit)]
      property FurMovementLength : single read FFurMovementLength write FFurMovementLength;
      [VCLSingleField(1.0)]
      property FurGravitation : single read FFurGravitation write FFurGravitation;
      /// <summary> Contains the root filepath for this mesh. This property declare the SourcePath of all resources
      /// (e.g. Textures, Mesh).</summary>
      [XMLExcludeElement]
      property RootFilePath : string read FRootFilePath;
      /// <summary> If property is true, all paths are returned (from textures etc.) complete. Otherwise they will adjusted.</summary>
      [XMLExcludeElement]
      property ShowRealPath : boolean read FShowRealPath write FShowRealPath;
      constructor CreateFromFile(Scene : TRenderManager; const FileName : string);
      constructor Create(Scene : TRenderManager; Geometry : TMeshAnimatedGeometry);
      function HasAlpha : boolean;
      function TryGetBonePosition(BoneName : string; out Base : RMatrix4x3) : boolean; virtual;
      function TrySetBoneTransformation(BoneName : string; const Transformation : RMatrix4x3) : boolean;
      function GetBoneList : TStrings;
      procedure SaveToFile(const Filepath : string);
      destructor Destroy; override;
    public
      class procedure PrecompileDefaultShaders;
  end;

  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

  [XMLBaseClass, XMLExcludeAll()]
  TMesh = class(TRawMesh)
    private
      function GetTransformationMatrix : RMatrix4x3;
      function getBoundingBoxTransformed : RAABB;
      function getBoundingSphereTransformed : RSphere;
    protected
      FRotation, FScale, FUp, FFront : RVector3;
      FTransformDirty : boolean;
      // already existing in TWorldObject
      // FPosition : RVector3
      FBoundingSphereTransformed : RSphere;
      FBoundingBoxTransformed : RAABB;
      function getLeft : RVector3;
      function GetScale() : single; override;
      procedure SetFront(const Value : RVector3);
      procedure SetUp(const Value : RVector3);
      procedure SetRotation(const Value : RVector3);
      procedure SetScale(const Value : single);
      procedure SetScaleImbalanced(const Value : RVector3);
      procedure SetPosition(const Value : RVector3); override;
      procedure ComputeTransformationMatrix;
      procedure BoundingTransformation;
      procedure SetGeometryFile(Value : string); override;
      procedure Render(Stage : EnumRenderStage; RenderContext : TRenderContext); override;
      procedure RenderShadowContribution(RenderContext : TRenderContext); override;
      /// <summary> Shared default initialize for mesh</summary>
      constructor InitCreate;
    public
      /// <summary> BoundingSphere transformed by any transformations like position, scale, new base etc.</summary>
      property BoundingSphereTransformed : RSphere read getBoundingSphereTransformed;
      /// <summary> Axis-Aligned BoundingBox affected by any transformations like position, scale, new base etc.
      /// so new BoundingBox is computed.</summary>
      property BoundingBoxTransformed : RAABB read getBoundingBoxTransformed;
      /// <summary> Direction in which the meshs top is</summary>
      property Up : RVector3 read FUp write SetUp;
      /// <summary> Direction in which the mesh looks</summary>
      property Front : RVector3 read FFront write SetFront;
      /// <summary> Cross Front and Up</summary>
      property Left : RVector3 read getLeft;
      // already existing in TWorldObject
      // property Position : RVector3 read FPosition write SetPosition;
      /// <summary> Set rotation for mesh. Rotation is appled before translation but after scale.</summary>
      property Rotation : RVector3 read FRotation write SetRotation;
      /// <summary> Set scale for mesh with uniform for all axis. Scale is applied first to meshdata.</summary>
      property Scale : single read GetScale write SetScale;
      /// <summary> Set the transformationmatrix used to render object and transfer model from object to
      /// worldspace.</summary>
      property TransformationMatrix : RMatrix4x3 read GetTransformationMatrix;
      /// <summary> Set scale for every axis for mesh, whereby imbalanced scaling is possible.
      /// ATTENTION!!! For imbalanced scaled meshes collisiondetection doesn't work reliable.</summary>
      property ScaleImbalanced : RVector3 read FScale write SetScaleImbalanced;
      /// <summary> Axis-Aligned BoundingBox affected by any transformations like position, scale, new base etc.
      /// so new BoundingBox is computed.</summary>
      function GetBoundingBox() : RAABB; override;
      /// <summary> Axis-Aligned BoundingBox affected by no transformations like position, scale, new base etc.</summary>
      function GetUntransformedBoundingBox() : RAABB;
      /// <summary> BoundingSphere transformed by any transformations like position, scale, new base etc.</summary>
      function GetBoundingSphere() : RSphere; override;
      /// <summary> Create mesh from file and load any material information (xml) and
      /// geometrydata (xfile) if provided.</summary>
      constructor CreateFromFile(Scene : TRenderManager; const Filepath : string);
      /// <summary> Create a default initalized mesh and set given geometry (and load e.g. bounding data).</summary>
      constructor Create(Scene : TRenderManager; Geometry : TMeshAnimatedGeometry);
      /// <summary> Free all allcoated memory.</summary>
      destructor Destroy; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

var
  // if true, raw meshfile is created whenever a normal mesh file is loaded
  CREATE_RAW_MESH : boolean = False;
  LOAD_RAW_MESH : boolean   = {$IFDEF DEBUG}False{$ELSE}True{$ENDIF};

implementation


{ TRawMesh }

procedure TRawMesh.Init;
begin
  CustomShader := TList<RMeshShader>.Create;
  SetDefaultMaterialSettings;
  Scene.Eventbus.Subscribe(geDrawOpaqueShadowmap, RenderShadowContribution);
end;

constructor TRawMesh.CreateFromFile(Scene : TRenderManager; const FileName : string);
const
  FILE_EXTENSIONS : array [0 .. 3] of string = ('.tga', '.png', '.jpg', '.psd');
var
  FileExt, TryFile : string;
  i : integer;
begin
  inherited Create(Scene);
  Init;
  FFilePath := AbsolutePath(FileName);
  if not FileExists(FFilePath) then
  begin
    raise EMeshError.Create('TRawMesh.CreateFromFile: Can''t find file ' + FFilePath + '!');
  end;
  FileExt := ExtractFileExt(FFilePath).ToLowerInvariant;
  FRootFilePath := ExtractFilePath(FFilePath);
  if (FileExt = '.x') or (FileExt = '.fbx') or (FileExt = '.binaryfbx') or (FileExt = '.morphfbx') or (FileExt = '.basefbx') or (FileExt = '.obj') or (FileExt = '.blend') or (FileExt = '.3ds') or (FileExt = '.dae') or (FileExt = '.msh') then
  begin
    GeometryFile := FFilePath;

    for i := 0 to length(FILE_EXTENSIONS) - 1 do
    begin
      // try to load textures with nameconvention
      if not assigned(FDiffuseTexture) and FileExists(ChangeFileExt(FFilePath, 'Diffuse' + FILE_EXTENSIONS[i])) then FDiffuseTexture := TTexture.CreateTextureFromFile(ChangeFileExt(FFilePath, 'Diffuse' + FILE_EXTENSIONS[i]), GFXD.Device3D, mhGenerate, True);
      if not assigned(FDiffuseTexture) and FileExists(ChangeFileExt(FFilePath.ToLowerInvariant, '_diffuse' + FILE_EXTENSIONS[i])) then FDiffuseTexture := TTexture.CreateTextureFromFile(ChangeFileExt(FFilePath.ToLowerInvariant, '_diffuse' + FILE_EXTENSIONS[i]), GFXD.Device3D, mhGenerate, True);
      // try to load normaltexture with nameconvention
      if not assigned(FNormalTexture) and FileExists(ChangeFileExt(FFilePath, 'Normal' + FILE_EXTENSIONS[i])) then FNormalTexture := TTexture.CreateTextureFromFile(ChangeFileExt(FFilePath, 'Normal' + FILE_EXTENSIONS[i]), GFXD.Device3D, mhGenerate, True);
      if not assigned(FNormalTexture) and FileExists(ChangeFileExt(FFilePath.ToLowerInvariant, '_normal' + FILE_EXTENSIONS[i])) then FNormalTexture := TTexture.CreateTextureFromFile(ChangeFileExt(FFilePath.ToLowerInvariant, '_normal' + FILE_EXTENSIONS[i]), GFXD.Device3D, mhGenerate, True);
      // try to load materialtextue with nameconvention
      if not assigned(FMaterialTexture) and FileExists(ChangeFileExt(FFilePath, 'Material' + FILE_EXTENSIONS[i])) then FMaterialTexture := TTexture.CreateTextureFromFile(ChangeFileExt(FFilePath, 'Material' + FILE_EXTENSIONS[i]), GFXD.Device3D, mhGenerate, True);
      if not assigned(FMaterialTexture) and FileExists(ChangeFileExt(FFilePath.ToLowerInvariant, '_material' + FILE_EXTENSIONS[i])) then FMaterialTexture := TTexture.CreateTextureFromFile(ChangeFileExt(FFilePath.ToLowerInvariant, '_material' + FILE_EXTENSIONS[i]), GFXD.Device3D, mhGenerate, True);
      // try to load glowtextue with nameconvention
      TryFile := ChangeFileExt(FFilePath, 'Glow' + FILE_EXTENSIONS[i]);
      if not assigned(FGlowTexture) and FileExists(TryFile) then FGlowTexture := TTexture.CreateTextureFromFile(TryFile, GFXD.Device3D, mhGenerate, True);
      TryFile := ChangeFileExt(FFilePath, '_glow' + FILE_EXTENSIONS[i]);
      if not assigned(FGlowTexture) and FileExists(TryFile) then FGlowTexture := TTexture.CreateTextureFromFile(TryFile, GFXD.Device3D, mhGenerate, True);
    end;
  end
  else if FileExt = '.xml' then
  begin
    ContentManager.SubscribeToFile(FFilePath, LoadData);
  end
  else
  begin
    Scene.Eventbus.Unsubscribe(geDrawOpaqueShadowmap, RenderShadowContribution);
    raise EUnknownMeshFormat.Create('TRawMesh.CreateFromFile: FFilePath ("' + FFilePath + '") has unknown fileextension.');
  end;
  assert(assigned(FGeometry));
end;

constructor TRawMesh.Create(Scene : TRenderManager; Geometry : TMeshAnimatedGeometry);
begin
  inherited Create(Scene);
  FGeometry := Geometry;
  Init;
end;

destructor TRawMesh.Destroy;
begin
  Scene.Eventbus.Unsubscribe(geDrawOpaqueShadowmap, RenderShadowContribution);
  ContentManager.UnSubscribeFromFile(FFilePath, LoadData);
  FAnimationDriverBone.Free;
  FAnimationDriverMorph.Free;
  FGeometry.Free;
  FDiffuseTexture.Free;
  FNormalTexture.Free;
  FMaterialTexture.Free;
  FGlowTexture.Free;
  FFurTexture.Free;
  CustomShader.Free;
  inherited;
end;

function TRawMesh.DrawsAtStage : SetRenderStage;
var
  i : integer;
begin
  if FOnlyOutline then exit([rsOutline]);
  Result := [];
  if not HasAlpha then
      Result := Result + [rsWorld];
  if assigned(FGlowTexture) then
      Result := Result + [rsGlow];
  if HasFur or HasAlpha then
      Result := Result + [rsEffects];
  if Outline then
      Result := Result + [rsOutline];
  for i := 0 to CustomShader.Count - 1 do
    if CustomShader[i].RendersInOwnPass then Result := Result + CustomShader[i].NeedsOwnPass;
end;

procedure TRawMesh.SetDefaultMaterialSettings;
begin
  // geometry can't provide any matrial data, therefore set default values
  SpecularIntensity := 0.0;
  SpecularPower := 128;
  ShadingReduction := 0.0;
  SpecularTint := 1.0;
  // disable alpha and alphagtest
  Alpha := 1;
  AlphaTestTreshold := 0;
  Cullmode := cmCCW;
  // fur
  FFurCullmode := cmCCW;
  FFurIterations := 10;
  FFurThickness := 10.1960;
  FFurAttenuation := 0.00388235;
  FFurAccelerationResponsivness := 0.030980;
  FFurResponsivness := 0.0081176;
  FFurAccelerationFactor := 1.0;
  FFurMovementLength := 1.0;
  FFurGravitation := 1.0;
end;

function TRawMesh.GenerateShaderBitmask(Stage : EnumRenderStage) : SetDefaultShaderFlags;
begin
  Result := AnimationController.GenerateShaderBitmask;
  Result := Result + [sfForceNormalmappingInput, sfForceSkinningInput, sfForceTexturecoordInput];
  if (AlphaTestTreshold > 0.0) then Result := Result + [EnumDefaultShaderFlags.sfAlphaTest];
  if HasColorOverride then Result := Result + [EnumDefaultShaderFlags.sfColorReplacement];

  if Stage = rsGlow then
  begin
    Result := Result + [EnumDefaultShaderFlags.sfUseAlpha];
    if assigned(FGlowTexture) then Result := Result + [EnumDefaultShaderFlags.sfDiffuseTexture];
  end
  else
    if Stage = rsOutline then
  begin
    Result := Result + [EnumDefaultShaderFlags.sfUseAlpha];
  end
  else
  begin
    if assigned(FDiffuseTexture) then Result := Result + [EnumDefaultShaderFlags.sfDiffuseTexture];
    if assigned(FNormalTexture) then Result := Result + [EnumDefaultShaderFlags.sfNormalmapping];
    if HasMaterialSettings then Result := Result + [EnumDefaultShaderFlags.sfMaterial];
    if assigned(FMaterialTexture) then Result := Result + [EnumDefaultShaderFlags.sfMaterialTexture];
    if HasAlpha then Result := Result + [EnumDefaultShaderFlags.sfUseAlpha];
    if (Stage = rsWorld) or ((Stage = rsEffects) and HasAlpha) then Result := Result + [EnumDefaultShaderFlags.sfShadowmapping];
  end;
  if (Stage <> rsOutline) and not ColorAdjustment.isZeroVector then
  begin
    Result := Result + [EnumDefaultShaderFlags.sfColorAdjustment];
    if not AbsoluteHSV.isZeroVector then
        Result := Result + [EnumDefaultShaderFlags.sfAbsoluteColorAdjustment];
  end;
end;

function TRawMesh.GetMaterialTexture : string;
begin
  Result := GetTextureFileName(FMaterialTexture);
end;

function TRawMesh.GetNormalTexture : string;
begin
  Result := GetTextureFileName(FNormalTexture);
end;

function TRawMesh.GetBoneList : TStrings;
  procedure AddBoneToList(CurrentBone : TMeshAnimatedGeometry.TBone);
  var
    ChildBone : TMeshAnimatedGeometry.TBone;
  begin
    Result.add(CurrentBone.Name);
    for ChildBone in CurrentBone.ChildBones do
    begin
      assert(assigned(ChildBone));
      AddBoneToList(ChildBone);
    end;
  end;

begin
  Result := TStringList.Create;
  if assigned(FGeometry.FRootBone) then
  begin
    AddBoneToList(FGeometry.FRootBone);
  end;
end;

function TRawMesh.GetColorAdjustment : RVector3;
begin
  Result := FColorAdjustment;
end;

function TRawMesh.GetDiffuseTexture : string;
begin
  Result := GetTextureFileName(FDiffuseTexture);
end;

function TRawMesh.GetFurTexture : string;
begin
  Result := GetTextureFileName(FFurTexture);
end;

function TRawMesh.TryGetBonePosition(BoneName : string; out Base : RMatrix4x3) : boolean;
var
  Bone : TMeshAnimatedGeometry.TBone;
begin
  Bone := AnimationDriverBone.RootBone.GetBoneByName(BoneName);
  if assigned(Bone) then
  begin
    Result := True;
    FAnimationController.UpdateAnimations;
    if Bone.CombinedMatrix.IsZero then Base := FTransformationMatrix * Bone.OriginalMatrix
    else Base := FTransformationMatrix * Bone.CombinedMatrix;
    Base.Column[0] := Base.Column[0].Normalize;
    Base.Column[1] := Base.Column[1].Normalize;
    Base.Column[2] := Base.Column[2].Normalize;
  end
  else
      Result := False;
end;

function TRawMesh.TrySetBoneTransformation(BoneName : string; const Transformation : RMatrix4x3) : boolean;
var
  Bone : TMeshAnimatedGeometry.TBone;
begin
  Bone := AnimationDriverBone.RootBone.GetBoneByName(BoneName);
  if assigned(Bone) then
  begin
    Bone.OverwriteBoneAnimation(Transformation);
    Result := True;
  end
  else Result := False;
end;

function TRawMesh.GetGeometryFile : string;
begin
  if assigned(FGeometry) then
  begin
    if FShowRealPath then
    begin
      Result := FGeometry.FileName;
    end
    else
    begin
      Result := ExtractFileName(FGeometry.FileName);
      if Result = '' then Result := 'Geometry in Memory';
    end;
  end
  else Result := '';
end;

function TRawMesh.GetGlowTexture : string;
begin
  Result := GetTextureFileName(FGlowTexture);
end;

function TRawMesh.GetTextureFileName(const SourceTexture : TTexture) : string;
begin
  if assigned(SourceTexture) then
  begin
    if FShowRealPath then
    begin
      Result := SourceTexture.FileName;
    end
    else
    begin
      Result := HFilepathManager.RelativeToRelative(SourceTexture.FileName, RootFilePath);
      if Result = '' then Result := 'Texture in Memory';
    end;
  end
  else Result := '';
end;

function TRawMesh.HasAlpha : boolean;
begin
  Result := (Alpha < 1) or TextureSemiTransparency;
end;

function TRawMesh.HasColorOverride : boolean;
begin
  Result := not FColorOverride.IsTransparentBlack;
end;

function TRawMesh.HasFur : boolean;
begin
  Result := assigned(FFurTexture) and (FurIterations > 0) and (FurThickness > 0.0);
end;

function TRawMesh.HasMaterialSettings : boolean;
begin
  Result := assigned(FMaterialTexture) or (SpecularIntensity > 0.0) or (ShadingReduction > 0.0) or (ShadingReductionOverride > 0.0);
end;

procedure TRawMesh.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
  procedure SetUpShader(Shader : TShader; OwnPass : boolean);
  var
    i : integer;
  begin
    if Stage <> rsOutline then
    begin
      if Stage = rsGlow then
      begin
        if assigned(FGlowTexture) then Shader.SetTexture(tsColor, FGlowTexture);
        GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHABLENDENABLE, 1);
        GFXD.Device3D.SetRenderState(EnumRenderstate.rsBLENDOP, boAdd);
        GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blSrcAlpha);
        GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blInvSrcAlpha);
        Shader.SetShaderConstant<single>(dcAlpha, Alpha);
      end
      else
      begin
        if assigned(FDiffuseTexture) then Shader.SetTexture(tsColor, FDiffuseTexture);
        if assigned(FNormalTexture) then Shader.SetTexture(tsNormal, FNormalTexture);
        if assigned(FMaterialTexture) then Shader.SetTexture(tsMaterial, FMaterialTexture);
        if HasMaterialSettings then
        begin
          Shader.SetShaderConstant<single>(dcSpecularpower, SpecularPower);
          Shader.SetShaderConstant<single>(dcSpecularintensity, SpecularIntensity);
          Shader.SetShaderConstant<single>(dcSpeculartint, SpecularTint);
          if ShadingReduction > 0.0 then
              Shader.SetShaderConstant<single>(dcShadingreduction, ShadingReduction)
          else
              Shader.SetShaderConstant<single>(dcShadingreduction, ShadingReductionOverride);
        end;

        if HasAlpha or ((AlphaTestTreshold > 0.0) and not GFXD.Settings.DeferredShading) then
        begin
          GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHABLENDENABLE, 1);
          GFXD.Device3D.SetRenderState(EnumRenderstate.rsBLENDOP, boAdd);
          GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blSrcAlpha);
          GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blInvSrcAlpha);
          Shader.SetShaderConstant<single>(dcAlpha, Alpha);
        end;

        if AlphaTestTreshold > 0.0 then
            Shader.SetShaderConstant<single>(dcAlphaTestRef, AlphaTestTreshold);
      end;

      if not AbsoluteHSV.isZeroVector then
      begin
        Shader.SetShaderConstant<RVector3>(dcHSVOffset, ColorAdjustment);
        Shader.SetShaderConstant<RVector3>(dcAbsoluteHSV, AbsoluteHSV);
      end
      else if not ColorAdjustment.isZeroVector then Shader.SetShaderConstant<RVector3>(dcHSVOffset, ColorAdjustment);

      if HasColorOverride then
          Shader.SetShaderConstant<RVector4>(dcReplacementColor, ColorOverride);

      if not RenderContext.DrawGBuffer and RenderContext.ShadowMapping.Enabled then RenderContext.SetShadowmapping(Shader);
    end;

    // shared render code
    AnimationController.UpdateAnimations;
    AnimationController.SetShaderSettings(RenderContext);

    Shader.SetWorld(FTransformationMatrix.To4x4);

    if not OwnPass then
    begin
      for i := CustomShader.Count - 1 downto 0 do
        if not CustomShader[i].RendersInOwnPass and assigned(CustomShader[i].SetUp) then CustomShader[i].SetUp(Shader, Stage, 0);
    end;
  end;

  function CustomShaderBlocks() : boolean;
  var
    i : integer;
  begin
    Result := False;
    for i := 0 to CustomShader.Count - 1 do
        Result := Result or CustomShader[i].OwnPassHideOriginal;
  end;

var
  Shader : TShader;
  pos : RVector3;
  i, j : integer;
  boneMat : RMatrix4x3;
  ShaderBitmask : SetDefaultShaderFlags;
begin
  AbsoluteHSV := RVector3.ZERO;
  if AbsoluteColorAdjustmentH then AbsoluteHSV.x := 1;
  if AbsoluteColorAdjustmentS then AbsoluteHSV.y := 1;
  if AbsoluteColorAdjustmentV then AbsoluteHSV.z := 1;

  if not CustomShaderBlocks and ((Stage in [rsWorld, rsGlow]) or ((Stage = rsEffects) and HasAlpha)) then
  begin
    ShaderBitmask := GenerateShaderBitmask(Stage);
    if not RenderContext.ShadowMapping.Enabled then
        exclude(ShaderBitmask, sfShadowmapping);
    if Stage <> rsGlow then
        include(ShaderBitmask, sfAllowLighting);
    Shader := RenderContext.CreateAndSetDefaultShader(ShaderBitmask, ResolveShaderArray);

    SetUpShader(Shader, False);

    GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, Ord(Cullmode));

    Shader.ShaderBegin;
    FGeometry.Render;
    Shader.ShaderEnd;
  end;

  for i := 0 to CustomShader.Count - 1 do
    if Stage in CustomShader[i].NeedsOwnPass then
    begin
      ShaderBitmask := GenerateShaderBitmask(Stage);
      if not RenderContext.ShadowMapping.Enabled then
          exclude(ShaderBitmask, sfShadowmapping);
      if Stage <> rsGlow then
          include(ShaderBitmask, sfAllowLighting);
      Shader := RenderContext.CreateAndSetDefaultShader(ShaderBitmask, [CustomShader[i].Shader]);

      SetUpShader(Shader, True);
      GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, cmNone);
      if Stage <> rsWorld then
      begin
        GFXD.Device3D.SetRenderState(EnumRenderstate.rsZWRITEENABLE, 0);
        GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHABLENDENABLE, 1);
        GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
        GFXD.Device3D.SetRenderState(rsDESTBLEND, blOne);
        case CustomShader[i].BlendMode of
          BlendAdditive : GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
          BlendSubtractive : GFXD.Device3D.SetRenderState(rsBLENDOP, boSubtract);
          BlendReverseSubtractive : GFXD.Device3D.SetRenderState(rsBLENDOP, boRevSubtract);
        else
          begin
            GFXD.Device3D.SetRenderState(rsSRCBLEND, blSrcAlpha);
            GFXD.Device3D.SetRenderState(rsDESTBLEND, blInvSrcAlpha);
            GFXD.Device3D.SetRenderState(rsBLENDOP, boAdd);
          end;
        end;
      end;

      for j := 0 to CustomShader[i].OwnPasses - 1 do
      begin
        if assigned(CustomShader[i].SetUp) then CustomShader[i].SetUp(Shader, Stage, j);

        Shader.ShaderBegin;
        FGeometry.Render;
        Shader.ShaderEnd;
      end;

      GFXD.Device3D.ClearRenderState();
    end;

  if Outline and (Stage in [rsOutline]) then
  begin
    ShaderBitmask := GenerateShaderBitmask(Stage);
    Shader := RenderContext.CreateAndSetDefaultShader(ShaderBitmask, ResolveShaderArray + ['MeshOutline.fx']);

    SetUpShader(Shader, False);

    Shader.SetShaderConstant<RVector4>('outline_color', FOutlineColor.RGBA);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, cmNone);

    Shader.ShaderBegin;
    FGeometry.Render;
    Shader.ShaderEnd;
  end;

  if HasFur and (Stage in [rsEffects, rsGlow]) then
  begin
    if Stage <> rsGlow then
        include(ShaderBitmask, sfAllowLighting);
    Shader := RenderContext.CreateAndSetDefaultShader(GenerateShaderBitmask(Stage), ResolveShaderArray + ['FurShader.fx']);

    SetUpShader(Shader, False);

    if assigned(FFurTexture) then
    begin
      Shader.SetTexture(tsVariable1, FFurTexture);
      Shader.SetTexture(tsVariable1, FFurTexture, stVertexShader);
    end;
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsZWRITEENABLE, 0);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHABLENDENABLE, 1);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsBLENDOP, boAdd);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsSRCBLEND, blSrcAlpha);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsDESTBLEND, blInvSrcAlpha);
    GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, FFurCullmode);

    if (FFurTrackBone <> '') and TryGetBonePosition(FFurTrackBone, boneMat) then pos := boneMat.Translation
    else pos := Position;

    // accelerate
    FFurAcceleration := ((FFurTrackLastPosition - pos) / GetScale).SetLengthMax(1.0) * FFurAccelerationFactor;

    FFurVelocity := (FFurVelocity + (FFurAcceleration - FFurTrackVector) * TimeManager.ZDiff * FFurAccelerationResponsivness
      - FFurVelocity * TimeManager.ZDiff * FFurAttenuation).SetLengthMax(1.0);

    FFurTrackVector := (FFurTrackVector + FFurVelocity * TimeManager.ZDiff * FFurResponsivness).SetLengthMax(1.0);

    FFurTrackLastPosition := pos;

    for i := 0 to FurIterations - 1 do
    begin
      Shader.SetShaderConstant<single>('fur_shell_factor', i / (FurIterations - 1));
      Shader.SetShaderConstant<single>('fur_thickness', FurThickness * GetScale);
      Shader.SetShaderConstant<single>('fur_gravitation_factor', FFurGravitation);
      Shader.SetShaderConstant<RVector3>('fur_move', FFurTrackVector * FFurMovementLength);

      Shader.ShaderBegin;
      FGeometry.Render;
      Shader.ShaderEnd;
    end;
  end;
end;

procedure TRawMesh.RenderShadowContribution(RenderContext : TRenderContext);
var
  Shader : TShader;
  ShaderFlags : SetDefaultShaderFlags;
  i : integer;
begin
  if CastsNoShadow or not Visible or (RenderContext.MainDirectionalLight = nil) or (not(rsWorld in DrawsAtStage) and not HasAlpha) then exit;
  ShaderFlags := GenerateShaderBitmask(rsWorld);
  // sanitize shader flags, remove not necessary flags
  ShaderFlags := ShaderFlags * DEFAULT_SHADOW_SHADER_ALLOWED_FLAGS;
  if FUseAlphaTest then
      ShaderFlags := ShaderFlags + [sfAlphaTest];
  Shader := RenderContext.CreateAndSetDefaultShadowShader(ShaderFlags, ResolveShaderArray);

  Shader.SetShaderConstant<RVector3>(dcLightPosition, RenderContext.Camera.Position);
  if assigned(FDiffuseTexture) then Shader.SetTexture(tsColor, FDiffuseTexture);

  if AlphaTestTreshold > 0.0 then
  begin
    if GFXD.Settings.DeferredShading then
    begin
      Shader.SetShaderConstant<single>(dcAlphaTestRef, AlphaTestTreshold);
    end
    else
    begin
      GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHATESTENABLE, 1);
      GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHAREF, byte(round(AlphaTestTreshold * 255)));
      GFXD.Device3D.SetRenderState(EnumRenderstate.rsALPHAFUNC, Ord(coGreaterEqual));
    end;
  end;

  // shared render code
  AnimationController.UpdateAnimations;
  AnimationController.SetShaderSettings(RenderContext);

  GFXD.Device3D.SetRenderState(EnumRenderstate.rsCULLMODE, Ord(Cullmode));

  Shader.SetWorld(FTransformationMatrix.To4x4);

  for i := CustomShader.Count - 1 downto 0 do
    if not CustomShader[i].RendersInOwnPass and assigned(CustomShader[i].SetUp) then CustomShader[i].SetUp(Shader, rsShadow, 0);

  Shader.ShaderBegin;
  FGeometry.Render;
  Shader.ShaderEnd;

  GFXD.Device3D.ClearRenderState();
end;

function TRawMesh.ResolveShaderArray : AString;
var
  i, Count : integer;
begin
  // collect all shaders, which renders not in an own pass
  Count := 0;
  for i := 0 to CustomShader.Count - 1 do
    if not CustomShader[i].RendersInOwnPass then inc(Count);
  setLength(Result, Count);
  dec(Count);
  for i := CustomShader.Count - 1 downto 0 do
    if not CustomShader[i].RendersInOwnPass then
    begin
      Result[Count] := CustomShader[i].Shader;
      dec(Count);
    end;
end;

procedure TRawMesh.SaveToFile(const Filepath : string);
begin
  HXMLSerializer.SaveObjectToFile(self, Filepath);
end;

procedure TRawMesh.SetMaterialTexture(Value : string);
begin
  FreeAndNil(FMaterialTexture);
  // empty String will only delete texture
  if (Value <> '') then
  begin
    // include string no drive, add path to file
    if HFilepathManager.IsRelative(Value) then Value := FRootFilePath + Value;
    FMaterialTexture := TTexture.CreateTextureFromFile(Value, GFXD.Device3D, mhGenerate, True);
    if not assigned(FMaterialTexture) then HLog.Log('TRawMesh.SetGlanzMap: Can''t find texture "' + Value + '".');
  end;
end;

procedure TRawMesh.SetNormalTexture(Value : string);
begin
  FreeAndNil(FNormalTexture);
  // empty String will only delete texture
  if (Value <> '') then
  begin
    // include string no drive, add path to file
    if HFilepathManager.IsRelative(Value) then Value := FRootFilePath + Value;
    FNormalTexture := TTexture.CreateTextureFromFile(Value, GFXD.Device3D, mhGenerate, True);
    if not assigned(FNormalTexture) then HLog.Log('TRawMesh.SetNormalMap: Can''t find texture "' + Value + '".');
  end;
end;

procedure TRawMesh.SetDiffuseTexture(Value : string);
begin
  FreeAndNil(FDiffuseTexture);
  // empty String will only delete texture
  if (Value <> '') then
  begin
    // if string includes no drive, add path to file
    if HFilepathManager.IsRelative(Value) then Value := FRootFilePath + Value;
    FDiffuseTexture := TTexture.CreateTextureFromFile(Value, GFXD.Device3D, mhGenerate, True);
    if not assigned(FDiffuseTexture) then HLog.Log('TRawMesh.SetDiffuseTexture: Can''t find texture "' + Value + '".');
  end;
end;

procedure TRawMesh.SetFurTexture(Value : string);
begin
  FreeAndNil(FFurTexture);
  // empty String will only delete texture
  if (Value <> '') then
  begin
    // include string no drive, add path to file
    if HFilepathManager.IsRelative(Value) then Value := FRootFilePath + Value;
    FFurTexture := TTexture.CreateTextureFromFile(Value, GFXD.Device3D, mhGenerate, True);
    if not assigned(FFurTexture) then HLog.Log('TRawMesh.SetFurTexture: Can''t find texture "' + Value + '".');
  end;
end;

procedure TRawMesh.SetGeometryFile(Value : string);
begin
  if assigned(FGeometry) and (AbsolutePath(RootFilePath + Value).ToLowerInvariant = FGeometry.FileName) then exit;

  if assigned(FAnimationDriverBone) then AnimationController.RemoveDriver(FAnimationDriverBone);
  if assigned(FAnimationDriverMorph) then AnimationController.RemoveDriver(FAnimationDriverMorph);
  FreeAndNil(FGeometry);
  FreeAndNil(FAnimationDriverBone);
  FreeAndNil(FAnimationDriverMorph);
  // empty String will only delete geometry
  if (Value <> '') then
  begin
    // the geometry file is searched relative to the xml
    if HFilepathManager.IsRelative(Value) then Value := RootFilePath + Value;
    FGeometry := TMeshAnimatedGeometry.CreateFromFile(Value, GFXD);
    if assigned(FGeometry.SkinAnimationDriver) then
        FAnimationDriverBone := FGeometry.SkinAnimationDriver.GetCopy;
    if assigned(FGeometry.MorphAnimationDriver) then
        FAnimationDriverMorph := FGeometry.MorphAnimationDriver.GetCopy;
    if assigned(FAnimationDriverBone) then AnimationController.AddDriver(FAnimationDriverBone);
    if assigned(FAnimationDriverMorph) then AnimationController.AddDriver(FAnimationDriverMorph);
  end;
end;

procedure TRawMesh.SetGlowTexture(Value : string);
begin
  FreeAndNil(FGlowTexture);
  // empty String will only delete texture
  if (Value <> '') then
  begin
    // include string no drive, add path to file
    if HFilepathManager.IsRelative(Value) then Value := FRootFilePath + Value;
    FGlowTexture := TTexture.CreateTextureFromFile(Value, GFXD.Device3D, mhGenerate, True);
    if not assigned(FGlowTexture) then HLog.Log('TRawMesh.SetGlowTexture: Can''t find texture "' + Value + '".');
  end;
end;

procedure TRawMesh.LoadData(const Filepath : string);
begin
  HXMLSerializer.LoadObjectFromFile(self, Filepath);
end;

class procedure TRawMesh.PrecompileDefaultShaders;
var
  FixedSet, DynamicSet : SetDefaultShaderFlags;
  Permutator : TGroupPermutator<SetDefaultShaderFlags>;
begin
  assert(assigned(GFXD), 'TRawMesh.PrecompileDefaultShaders: Graphics needs to be initialized!');
  FixedSet := [sfForceNormalmappingInput, sfForceSkinningInput, sfForceTexturecoordInput];
  DynamicSet := [sfSkinning, sfAlphaTest, sfUseAlpha, { sfColorReplacement, }sfLighting];

  Permutator := TGroupPermutator<SetDefaultShaderFlags>.Create;
  Permutator.AddFixedValue([FixedSet]);

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .AddValues(GFXD.DefaultShaderManager.SetDefaultShaderFlagsToArray(DynamicSet))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
    .AddValue(TArray<SetDefaultShaderFlags>.Create([]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfGBuffer, sfDeferredDrawColor, sfDeferredDrawPosition, sfDeferredDrawNormal, sfDeferredDrawMaterial]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfShadowmapping]))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
    .AddValue(TArray<SetDefaultShaderFlags>.Create([]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDiffuseTexture]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDiffuseTexture, sfMaterial]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDiffuseTexture, sfMaterial, sfMaterialTexture]))
    // we ignore normalmapping for now
    // .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDiffuseTexture, sfNormalmapping]))
    // .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDiffuseTexture, sfNormalmapping, sfMaterial]))
    // .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDiffuseTexture, sfNormalmapping, sfMaterialTexture]))
    // .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDiffuseTexture, sfNormalmapping, sfMaterial, sfMaterialTexture]))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
    .AddValue(TArray<SetDefaultShaderFlags>.Create([]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfColorAdjustment]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfColorAdjustment, sfAbsoluteColorAdjustment]))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
    .AddValue(TArray<SetDefaultShaderFlags>.Create([]))
    // we ignore morphtargets other than in use for now
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfMorphtarget1]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfMorphtarget2]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfMorphtarget3]))
    // .AddValue(TArray<SetDefaultShaderFlags>.Create([sfMorphtarget4]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfMorphtarget5]))
    // .AddValue(TArray<SetDefaultShaderFlags>.Create([sfMorphtarget6]))
    // .AddValue(TArray<SetDefaultShaderFlags>.Create([sfMorphtarget7]))
    // .AddValue(TArray<SetDefaultShaderFlags>.Create([sfMorphtarget8]))
    );

  GFXD.DefaultShaderManager.PrecompileSet(Permutator, False);
  Permutator.Free;

  // shadow shader
  Permutator := TGroupPermutator<SetDefaultShaderFlags>.Create;
  Permutator.AddFixedValue([FixedSet * DEFAULT_SHADOW_SHADER_ALLOWED_FLAGS]);

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .AddValues(GFXD.DefaultShaderManager.SetDefaultShaderFlagsToArray(DynamicSet * DEFAULT_SHADOW_SHADER_ALLOWED_FLAGS))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
    .AddValue(TArray<SetDefaultShaderFlags>.Create([]))
    .AddValue(TArray<SetDefaultShaderFlags>.Create([sfDiffuseTexture]))
    );

  Permutator.AddPermutator(
    TPermutator<SetDefaultShaderFlags>.Create
    .IterateInsteadOfPermutate
    .AddValues(GFXD.DefaultShaderManager.SetDefaultShaderFlagsToArray([sfMorphtarget1 .. sfMorphtarget8]))
    );

  GFXD.DefaultShaderManager.PrecompileSet(Permutator, True);

  Permutator.Free;
end;

procedure TRawMesh.SetAlpha(Value : single);
begin
  assert(inRange(Value, 0, 1), 'Alphavalue must be between 0.0 and 1.0!');
  FAlpha := Value;
end;

procedure TRawMesh.SetAlphaTestTreshold(Value : single);
begin
  assert(inRange(Value, 0, 1), 'Alphatestvalue must be between 0.0 and 1.0!');
  FAlphaTestTreshold := Value;
end;

procedure TRawMesh.SetColorAdjustment(const Value : RVector3);
begin
  FColorAdjustment := Value;
end;

{ TMesh }

constructor TMesh.Create(Scene : TRenderManager; Geometry : TMeshAnimatedGeometry);
begin
  FAnimationController := TAnimationController.Create;
  inherited Create(Scene, Geometry);
  InitCreate;
end;

constructor TMesh.CreateFromFile(Scene : TRenderManager; const Filepath : string);
begin
  FAnimationController := TAnimationController.Create;
  inherited CreateFromFile(Scene, Filepath);
  InitCreate;
end;

destructor TMesh.Destroy;
begin
  FAnimationController.Free;
  inherited;
end;

function TMesh.getBoundingSphereTransformed : RSphere;
begin
  if FTransformDirty then ComputeTransformationMatrix;
  Result := FBoundingSphereTransformed;
end;

function TMesh.getLeft : RVector3;
begin
  Result := Front.Cross(Up).Normalize;
end;

function TMesh.GetScale : single;
begin
  Result := FScale.x;
end;

function TMesh.GetTransformationMatrix : RMatrix4x3;
begin
  if FTransformDirty then ComputeTransformationMatrix;
  Result := FTransformationMatrix;
end;

function TMesh.GetUntransformedBoundingBox : RAABB;
begin
  Result := FGeometry.BoundingBox;
end;

constructor TMesh.InitCreate;
begin
  FFront := RVector3.UNITZ;
  FUp := RVector3.UNITY;
  Scale := 1;
end;

procedure TMesh.ComputeTransformationMatrix;
var
  tempUp, tempLeft : RVector3;
begin
  tempLeft := Up.Cross(Front).Normalize;
  tempUp := Front.Cross(tempLeft).Normalize;
  // if the new Base ist not correct dont use it (use only plane translation, rotation and scale), so the Mesh can not be deformed
  if (tempUp = RVector3.ZERO) or (tempLeft = RVector3.ZERO) or (Front = RVector3.ZERO) then
      FTransformationMatrix := RMatrix4x3.CreateTranslation(FPosition) * RMatrix4x3.CreateRotationPitchYawRoll(FRotation) * RMatrix4x3.CreateScaling(FScale)
  else
      FTransformationMatrix := RMatrix4x3.CreateTranslation(FPosition) * RMatrix4x3.CreateBase(tempLeft, tempUp, Front) * RMatrix4x3.CreateRotationPitchYawRoll(FRotation) * RMatrix4x3.CreateScaling(FScale);
  // all meshes are loaded mirrored along x-axis, so now mirror back
  FTransformationMatrix := FTransformationMatrix * RMatrix.CreateScaling(RVector3.Create(-1, 1, 1)).To4x3;

  BoundingTransformation;

  FTransformDirty := False;
end;

procedure TMesh.Render(Stage : EnumRenderStage; RenderContext : TRenderContext);
begin
  // ToDo: Check visibility on a higher level
  if RenderContext.Camera.IsSphereVisible(BoundingSphereTransformed) then inherited Render(Stage, RenderContext);
end;

procedure TMesh.RenderShadowContribution(RenderContext : TRenderContext);
begin
  if RenderContext.Camera.IsSphereVisible(BoundingSphereTransformed) then inherited;
end;

function TMesh.GetBoundingBox : RAABB;
begin
  Result := FBoundingBoxTransformed;
end;

function TMesh.getBoundingBoxTransformed : RAABB;
begin
  if FTransformDirty then ComputeTransformationMatrix;
  Result := FBoundingBoxTransformed;
end;

function TMesh.GetBoundingSphere : RSphere;
begin
  Result := FBoundingSphereTransformed;
end;

procedure TMesh.SetRotation(const Value : RVector3);
begin
  FRotation := Value;
  FTransformDirty := True;
end;

procedure TMesh.SetFront(const Value : RVector3);
begin
  if Value.isZeroVector then exit;
  FFront := Value.Normalize;
  FTransformDirty := True;
end;

procedure TMesh.SetGeometryFile(Value : string);
begin
  inherited;
  // new geometry -> new boundingdata, so transform data
  BoundingTransformation;
end;

procedure TMesh.SetScale(const Value : single);
begin
  FScale := RVector3.Create(Value, Value, Value);
  FTransformDirty := True;
end;

procedure TMesh.SetPosition(const Value : RVector3);
begin
  inherited;
  FTransformDirty := True;
end;

procedure TMesh.SetScaleImbalanced(const Value : RVector3);
begin
  FScale := Value;
  FTransformDirty := True;
end;

procedure TMesh.SetUp(const Value : RVector3);
begin
  if Value.isZeroVector then exit;
  FUp := Value.Normalize;
  FTransformDirty := True;
end;

procedure TMesh.BoundingTransformation;
var
  OBB : ROBB;
  TransformWithoutTranslation : RMatrix4x3;
begin
  assert(assigned(FGeometry));
  FBoundingSphereTransformed.Center := FTransformationMatrix * FGeometry.BoundingSphere.Center;
  FBoundingSphereTransformed.Radius := FGeometry.FBoundingSphere.Radius * FScale.MaxValue;
  // compute new axis aligned boundingbox, since a AABB can't be pure transformed
  // because rotation would cause a bigger or smaller box, Code by Tobi
  TransformWithoutTranslation := FTransformationMatrix;
  TransformWithoutTranslation.Translation := RVector3.ZERO;
  OBB := ROBB.Create(FTransformationMatrix * FGeometry.BoundingBox.Center, (TransformWithoutTranslation * (RVector3.UNITZ)), (TransformWithoutTranslation * RVector3.UNITY), FGeometry.BoundingBox.HalfExtents * 2 * FScale);
  FBoundingBoxTransformed := OBB.GetWrappingAABB;
end;

{ TMeshGeometryAnimatedXFile }

procedure TMeshAnimatedGeometry.CalculateBoundings(VertexData : AVertexData);
var
  j, positioncount : integer;
  first : boolean;
  VertexPosition : RVector3;
begin
  first := True;
  if first then
  begin
    VertexPosition := VertexData[0].Position[0];
    FBoundingBox := RAABB.Create(VertexPosition);
    FBoundingSphere := RSphere.CreateSphere(VertexPosition, 0);
  end;
  positioncount := 1;
  for j := 0 to length(VertexData) - 1 do
  begin
    if first then
    begin
      first := False;
      continue;
    end;
    VertexPosition := VertexData[j].Position[0];
    FBoundingSphere.Center := FBoundingSphere.Center + VertexPosition;
    inc(positioncount);
    FBoundingBox.Extend(VertexPosition);
  end;
  FBoundingSphere.Center := FBoundingSphere.Center / positioncount;
  for j := 0 to length(VertexData) - 1 do
  begin
    VertexPosition := VertexData[j].Position[0];
    FBoundingSphere.Radius := Max(FBoundingSphere.Radius, FBoundingSphere.Center.Distance(VertexPosition));
  end;
end;

class function TMeshAnimatedGeometry.CreateFromFile(FileName : string; GFXD : TGFXD) : TMeshAnimatedGeometry;
begin
  // raw mesh have a different filename (where extension is changed)
  if LOAD_RAW_MESH then
      FileName := TEngineRawMesh.ConvertFileNameToRaw(FileName);

  // try to get cashed version instead of loading it
  if assigned(GFXD) then
      Result := TMeshAnimatedGeometry(QueryDeviceForObject(GFXD.Device3D, FileName))
  else
      Result := nil;

  if not assigned(Result) then
  begin
    Result := CreateFromFileIntern(FileName, GFXD);
    Result.RegisterObjectInDevice(True, FileName, True);
  end;
end;

constructor TMeshAnimatedGeometry.CreateFromFileIntern(FileName : string; GFXD : TGFXD);
begin
  if FileExists(FileName) then
  begin
    if assigned(GFXD) then
        inherited Create(GFXD.Device3D);
    if SameText(ENGINEMESH_FORMAT_EXTENSION, ExtractFileExt(FileName)) then
        ContentManager.SubscribeToFile(FileName, LoadRawMeshData)
    else
        ContentManager.SubscribeToFile(FileName, LoadData);
  end
  else raise EMeshError.Create('TMeshAnimatedGeometry.CreateFromFileIntern: Can''t find geometry "' + FileName + '".');
end;

destructor TMeshAnimatedGeometry.Destroy;
begin
  if CanDestroyed then
  begin
    ContentManager.UnSubscribeFromFile(FileName, LoadData);
    FSkin.Free;
    FVertexBuffer.Free;
    FIndexBuffer.Free;
    FRootBone.Free;
    FSkinAnimationDriver.Free;
    FMorphAnimationdriver.Free;
    inherited;
  end;
end;

function TMeshAnimatedGeometry.GetFileName : string;
begin
  Result := FFileName;
end;

procedure TMeshAnimatedGeometry.LoadData(const Filepath : string);
var
  p : Pointer;
  i, i2, SubsetIndex, vertexSize, indexSize, Count : integer;
  rawVertices : AVertexData;
  rawColors : TArray<RVector4>;
  IndexedVertexData : AVertexData;
  IndexedIndexData : AIndexData;
  IndexedColorData : TArray<RVector4>;
  meshTransformIT : RMatrix4x3;
  MeshAsset : TMeshAsset;
  sourceData : TMeshAssetSubset;
  AnimationDataSkin : TArray<TMeshAssetAnimationBone>;
  AnimationDataMorph : TArray<TMeshAssetAnimationMorph>;
  hasTangentBinormal, baseFound : boolean;
  MorphtargetMapping : TArray<string>;
  MirrorMesh : boolean;
  AIndex : Cardinal;
  EngineRawMesh : TEngineRawMesh;
  EngineRawMeshFilename : string;
begin
  MirrorMesh := True;
  assert(FileExists(Filepath));
  FFileName := Filepath;

  // clean former state
  FreeAndNil(FRootBone);
  FreeAndNil(FVertexBuffer);
  FreeAndNil(FIndexBuffer);
  FreeAndNil(FSkin);
  FreeAndNil(FSkinAnimationDriver);
  FreeAndNil(FMorphAnimationdriver);

  MeshAsset := TAssetManager.LoadMesh(FileName);

  // every mesh has at least one rootbone
  // loading root bone will also loading child bones
  FRootBone := TBone.Create(MeshAsset.Skeleton.RootNode);

  // first collapse all subsets of the mesh into one giant subset
  if MeshAsset.SubsetCount > 1 then
      MeshAsset.CollapseSubsets(True);

  MorphtargetMapping := nil;
  sourceData := nil;
  // process all data to build buffers and animation data
  if MeshAsset.SubsetCount >= 1 then
  begin
    assert(MeshAsset.Subsets[0].MorphtargetCount <= MAX_MORPH_TARGET_COUNT, Format('Only %d Morphtargets are supported at the moment, but found %d', [MAX_MORPH_TARGET_COUNT, MeshAsset.Subsets[0].MorphtargetCount]));
    // Build vertex data ///////////////////////////////////////////////////////
    sourceData := MeshAsset.Subsets[0];
    assert(sourceData.VertexCount mod 3 = 0);

    // load all verticesdata into array
    setLength(rawVertices, sourceData.VertexCount);
    setLength(rawColors, sourceData.VertexCount);
    hasTangentBinormal := sourceData.HasTangents and sourceData.HasBinormals;
    for i := 0 to sourceData.VertexCount - 1 do
    begin
      rawVertices[i].Position[0] := sourceData.VertexPositions[i];

      if sourceData.HasColor then rawColors[i] := sourceData.Colors[i]
      else rawColors[i] := RVector4.ZERO;
      if sourceData.HasNormals then rawVertices[i].Normal := sourceData.Normals[i].Normalize
      else rawVertices[i].Normal := RTriangle.Create(sourceData.VertexPositions[i div 3], sourceData.VertexPositions[(i div 3) + 1], sourceData.VertexPositions[(i div 3) + 2]).GetNormal;
      rawVertices[i].SmoothedNormal := rawVertices[i].Normal;
      if sourceData.HasTextureCoordinates then rawVertices[i].TextureCoordinate := sourceData.TextureCoordinate[i]
      else rawVertices[i].TextureCoordinate := RVector2.ZERO;
      if hasTangentBinormal then
      begin
        rawVertices[i].Tangent := sourceData.Tangents[i];
        rawVertices[i].Binormal := sourceData.Binormals[i];
      end;
      if sourceData.HasSkin then
      begin
        assert(sourceData.BoneInfluencingCount[i] <= 4);
        assert(sourceData.BoneInfluencingCount[i] > 0, 'Any vertex that is not affected by any bone will be moved to ZERO by skinnig shader.');
        for i2 := 0 to sourceData.BoneInfluencingCount[i] - 1 do
        begin
          rawVertices[i].BoneWeights.Element[i2] := sourceData.BoneWeights[i][i2];
          rawVertices[i].BoneIndices.Element[i2] := sourceData.BoneIndices[i][i2];
        end;
      end;
    end;

    // load morphtarget data
    FMorphtargetCount := sourceData.MorphtargetCount + 1;
    for i := 0 to sourceData.MorphtargetCount - 1 do
    begin
      HArray.Push<string>(MorphtargetMapping, sourceData.MorphTargets[i].Name);
      assert(sourceData.VertexCount = sourceData.MorphTargets[i].DifferencePositionCount);
      for i2 := 0 to sourceData.VertexCount - 1 do
      begin
        rawVertices[i2].Position[1 + i] := sourceData.MorphTargets[i].DifferencePosition[i2];
      end;
    end;

    // compute indexing for vertexdata
    ComputeIndexedVertexData(rawVertices, rawColors, IndexedVertexData, IndexedIndexData, IndexedColorData);

    // apply mesh offset matrix directly to the vertices, so even unanimated it is correctly displayed
    sourceData := MeshAsset.Subsets[0];
    meshTransformIT := sourceData.MeshOffsetMatrix.Get3x3.Inverse.Transpose.To4x3;
    for i := 0 to length(IndexedVertexData) - 1 do
    begin
      IndexedVertexData[i].Position[0] := sourceData.MeshOffsetMatrix * IndexedVertexData[i].Position[0];
      for i2 := 1 to length(IndexedVertexData[i].Position) - 1 do
          IndexedVertexData[i].Position[i2] := sourceData.MeshOffsetMatrix.Get3x3 * IndexedVertexData[i].Position[i2];
      IndexedVertexData[i].Normal := (meshTransformIT * IndexedVertexData[i].Normal).Normalize;
    end;

    // compute tangent and binormal for indexed data if not already data was delivered
    if not hasTangentBinormal then ComputeTangentsAndBinormals(IndexedVertexData, IndexedIndexData);

    // provide the smoothed normal
    ComputeSmoothedNormals(IndexedVertexData);

    CalculateBoundings(IndexedVertexData);

    FFaceCount := length(IndexedIndexData) div 3;
    FVerticesCount := length(IndexedVertexData);

    // move vertexdata to vertexbuffer
    vertexSize := RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.GetSize(FMorphtargetCount);
    vertexSize := vertexSize * length(IndexedVertexData);
    GetMem(p, vertexSize);
    IndexedVertexData.CopyTo(p, FMorphtargetCount, vertexSize);
    if assigned(GFXD) then
        FVertexBuffer := TVertexBuffer.CreateVertexBuffer(vertexSize, [], GFXD.Device3D, p);
    FreeMem(p, vertexSize);

    // MirrorMesh: change vertices order
    if MirrorMesh then
      for i := 0 to (length(IndexedIndexData) div 3) - 1 do
      begin
        AIndex := IndexedIndexData[i * 3 + 2];
        IndexedIndexData[i * 3 + 2] := IndexedIndexData[i * 3 + 0];
        IndexedIndexData[i * 3 + 0] := AIndex;
      end;
    // move indexdata to indexbuffer
    indexSize := sizeof(LongWord) * length(IndexedIndexData);
    GetMem(p, indexSize);
    Move(IndexedIndexData[0], p^, sizeof(LongWord) * length(IndexedIndexData));
    if assigned(GFXD) then
        FIndexBuffer := TIndexBuffer.CreateIndexBuffer(indexSize, [], ifINDEX32, GFXD.Device3D, p);
    FreeMem(p, indexSize);

    // load skin data //////////////////////////////////////////////////////////
    if sourceData.HasSkin then
    begin
      assert(assigned(FRootBone));
      FSkin := TSkin.Create(sourceData.SkinBoneLinkCount);
      for i := 0 to sourceData.SkinBoneLinkCount - 1 do
      begin
        FSkin.FSkinBoneLinks[i].BoneSpaceOffsetMatrix := sourceData.SkinBoneLinks[i].BoneSpaceMatrix.To4x3 * sourceData.MeshOffsetMatrix.Inverse.To4x3;
        FSkin.FSkinBoneLinks[i].TargetBone := FRootBone.GetBoneByName(sourceData.SkinBoneLinks[i].TargetBone);
        assert(assigned(FSkin.FSkinBoneLinks[i].TargetBone), 'Referenced bone "' + sourceData.SkinBoneLinks[i].TargetBone + '" not found, Bones exported?');
      end;
    end;
  end;
  // no exception here, because for robustness empty meshes should be loaded correctly
  // but does not display any geometrie data
  // else raise Exception.Create('TMesh.CreateFromFileIntern: Mesh-File has no subsets!');

  // load animation data ///////////////////////////////////////////////////////
  AnimationDataSkin := nil;
  AnimationDataMorph := nil;

  // filter all bone animation in, all other out
  for i := 0 to MeshAsset.AnimationCount - 1 do
  begin
    case MeshAsset.Animations[i].AnimationType of
      atBoneAnimation :
        begin
          setLength(AnimationDataSkin, length(AnimationDataSkin) + 1);
          AnimationDataSkin[high(AnimationDataSkin)] := MeshAsset.Animations[i].AsBoneAnimation;
        end;
      atMorphAnimation :
        begin
          setLength(AnimationDataMorph, length(AnimationDataMorph) + 1);
          AnimationDataMorph[high(AnimationDataMorph)] := MeshAsset.Animations[i].AsMorphAnimation;
        end;
    end;
  end;
  FSkinAnimationDriver := TSkinnedMeshAnimationDriver.Create(self, AnimationDataSkin);
  FMorphAnimationdriver := TMeshMorphAnimationDriver.Create(self, AnimationDataMorph, MorphtargetMapping);

  if CREATE_RAW_MESH then
  begin
    EngineRawMeshFilename := TEngineRawMesh.ConvertFileNameToRaw(Filepath);
    EngineRawMesh := TEngineRawMesh.CreateEmpty(Filepath);
    EngineRawMesh.MorphtargetCount := FMorphtargetCount;
    EngineRawMesh.BoundingBox := BoundingBox;
    EngineRawMesh.BoundingSphere := BoundingSphere;
    EngineRawMesh.VertexData := IndexedVertexData;
    EngineRawMesh.ColorData := IndexedColorData;
    EngineRawMesh.IndexData := IndexedIndexData;
    EngineRawMesh.BoneData := HArray.Map<TBone, REngineRawMeshBone>(FRootBone.ToArray,
      function(const Bone : TBone) : REngineRawMeshBone
      begin
        Result := REngineRawMeshBone.Create(Bone.Name, Bone.OriginalMatrix, length(Bone.ChildBones));
      end);
    if assigned(sourceData) and sourceData.HasSkin then
    begin
      EngineRawMesh.SkinData := HArray.Map<TMeshAnimatedGeometry.RSkinBoneLink, REngineRawSkinBoneLink>(FSkin.FSkinBoneLinks,
        function(const SkinBoneLink : TMeshAnimatedGeometry.RSkinBoneLink) : REngineRawSkinBoneLink
        begin
          Result := REngineRawSkinBoneLink.Create(SkinBoneLink.TargetBone.Name, SkinBoneLink.BoneSpaceOffsetMatrix);
        end);
    end;
    EngineRawMesh.BoneAnimationData := AnimationDataSkin;
    EngineRawMesh.MorphAnimationData := AnimationDataMorph;
    EngineRawMesh.MorphtargetMapping := MorphtargetMapping;
    EngineRawMesh.SaveToFile(EngineRawMeshFilename);
    EngineRawMesh.Free;
  end;

  MeshAsset.Free;
end;

procedure TMeshAnimatedGeometry.LoadRawMeshData(const Filepath : string);
var
  p : Pointer;
  i, vertexSize, indexSize : integer;
  AnimationDataSkin : TArray<TMeshAssetAnimationBone>;
  AnimationDataMorph : TArray<TMeshAssetAnimationMorph>;
  EngineRawMesh : TEngineRawMesh;
  FileStream : TStream;
  BoneData : TList<REngineRawMeshBone>;
  MorphtargetMapping : TArray<string>;
begin
  assert(FileExists(Filepath));
  FFileName := Filepath;

  // clean former state
  FreeAndNil(FRootBone);
  FreeAndNil(FVertexBuffer);
  FreeAndNil(FIndexBuffer);
  FreeAndNil(FSkin);
  FreeAndNil(FSkinAnimationDriver);
  FreeAndNil(FMorphAnimationdriver);

  FileStream := TFileStream.Create(Filepath, fmOpenRead or fmShareDenyWrite);
  try
    EngineRawMesh := TEngineRawMesh.CreateFromStream(FileStream);
    // every mesh has at least one rootbone
    // loading root bone will also loading child bones
    BoneData := TList<REngineRawMeshBone>.Create;
    BoneData.AddRange(EngineRawMesh.BoneData);
    FRootBone := TBone.Create(BoneData);
    BoneData.Free;
    FBoundingBox := EngineRawMesh.BoundingBox;
    FBoundingSphere := EngineRawMesh.BoundingSphere;
    FMorphtargetCount := EngineRawMesh.MorphtargetCount;

    vertexSize := RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.GetSize(EngineRawMesh.MorphtargetCount);
    vertexSize := vertexSize * length(EngineRawMesh.VertexData);

    // move vertexdata to vertexbuffer
    GetMem(p, vertexSize);
    EngineRawMesh.VertexData.CopyTo(p, EngineRawMesh.MorphtargetCount, vertexSize);
    if assigned(GFXD) then
        FVertexBuffer := TVertexBuffer.CreateVertexBuffer(vertexSize, [], GFXD.Device3D, p);
    FreeMem(p, vertexSize);

    // move indexdata to indexbuffer
    indexSize := sizeof(LongWord) * length(EngineRawMesh.IndexData);
    GetMem(p, indexSize);
    Move(EngineRawMesh.IndexData[0], p^, sizeof(LongWord) * length(EngineRawMesh.IndexData));
    if assigned(GFXD) then
        FIndexBuffer := TIndexBuffer.CreateIndexBuffer(indexSize, [], ifINDEX32, GFXD.Device3D, p);
    FreeMem(p, indexSize);

    FFaceCount := length(EngineRawMesh.IndexData) div 3;
    FVerticesCount := length(EngineRawMesh.IndexData);

    if length(EngineRawMesh.SkinData) > 0 then
    begin
      assert(assigned(FRootBone));
      FSkin := TSkin.Create(length(EngineRawMesh.SkinData));
      for i := 0 to length(EngineRawMesh.SkinData) - 1 do
      begin
        FSkin.FSkinBoneLinks[i].BoneSpaceOffsetMatrix := EngineRawMesh.SkinData[i].OffsetMatrix;
        FSkin.FSkinBoneLinks[i].TargetBone := FRootBone.GetBoneByName(string(EngineRawMesh.SkinData[i].TargetBoneName));
        assert(assigned(FSkin.FSkinBoneLinks[i].TargetBone), 'Referenced bone "' + EngineRawMesh.SkinData[i].TargetBoneName + '" not found, Bones exported?');
      end;
    end;

    // load animation data ///////////////////////////////////////////////////////
    AnimationDataSkin := nil;
    AnimationDataMorph := nil;

    // filter all bone animation in, all other out
    setLength(AnimationDataSkin, length(EngineRawMesh.BoneAnimationData));
    for i := 0 to length(EngineRawMesh.BoneAnimationData) - 1 do
        AnimationDataSkin[high(AnimationDataSkin)] := EngineRawMesh.BoneAnimationData[i];

    setLength(AnimationDataMorph, length(EngineRawMesh.MorphAnimationData));
    for i := 0 to length(EngineRawMesh.MorphAnimationData) - 1 do
        AnimationDataMorph[high(AnimationDataMorph)] := EngineRawMesh.MorphAnimationData[i];
    MorphtargetMapping := EngineRawMesh.MorphtargetMapping;

    FSkinAnimationDriver := TSkinnedMeshAnimationDriver.Create(self, AnimationDataSkin);
    FMorphAnimationdriver := TMeshMorphAnimationDriver.Create(self, AnimationDataMorph, MorphtargetMapping);
    EngineRawMesh.Free;
  finally
    FileStream.Free;
  end;
end;

procedure TMeshAnimatedGeometry.Render(SubsetIndex : integer);
begin
  GFXD.Device3D.SetVertexDeclaration(RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.BuildVertexdeclaration(FMorphtargetCount));
  GFXD.Device3D.SetStreamSource(0, FVertexBuffer, 0, RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.GetSize(FMorphtargetCount));
  GFXD.Device3D.SetIndices(FIndexBuffer);
  GFXD.Device3D.DrawIndexedPrimitive(ptTrianglelist, 0, 0, FVerticesCount, 0, FFaceCount);
end;

procedure TMeshAnimatedGeometry.ComputeIndexedVertexData(InVertexData : AVertexData; InColorData : TArray<RVector4>;
out IndexedVertexData : AVertexData; out IndexedIndexData : AIndexData; out IndexedColorData : TArray<RVector4>);
var
  VertexTable : TDictionary<RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight, integer>;
  index, i : integer;
begin
  VertexTable := TDictionary<RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight, integer>.Create(
    TEqualityComparer<RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight>.Construct(
    function(const Left, Right : RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight) : boolean
    begin
      Result := Left.Position[0].SimilarTo(Right.Position[0]) and Left.Normal.SimilarTo(Right.Normal) and Left.TextureCoordinate.SimilarTo(Right.TextureCoordinate, 0.00001);
    end,
    function(const Value : RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight) : integer
    begin
      Result := Value.Position[0].GetHashValue xor Value.Normal.GetHashValue xor Value.TextureCoordinate.GetHashValue;
    end));
  // build indextable and fill array with data
  index := 0;
  setLength(IndexedIndexData, length(InVertexData));
  // set arraylength to max possible length, will adjust them later
  assert(length(InVertexData) = length(InColorData));
  setLength(IndexedVertexData, length(InVertexData));
  setLength(IndexedColorData, length(InColorData));
  for i := 0 to length(InVertexData) - 1 do
  begin
    if not VertexTable.ContainsKey(InVertexData[i]) then
    begin
      VertexTable.add(InVertexData[i], index);
      IndexedIndexData[i] := index;
      IndexedVertexData[index] := InVertexData[i];
      IndexedColorData[index] := InColorData[i];
      inc(index);
    end
    else IndexedIndexData[i] := VertexTable[InVertexData[i]];
  end;
  setLength(IndexedVertexData, index);
  setLength(IndexedColorData, index);
  VertexTable.Free;
end;

procedure TMeshAnimatedGeometry.ComputeSmoothedNormals(VertexData : AVertexData);
var
  VertexTable : TDictionary<RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight, RVector3>;
  i : integer;
begin
  VertexTable := TDictionary<RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight, RVector3>.Create(
    TEqualityComparer<RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight>.Construct(
    function(const Left, Right : RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight) : boolean
    begin
      Result := Left.Position[0].SimilarTo(Right.Position[0]);
    end,
    function(const Value : RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight) : integer
    begin
      Result := Value.Position[0].GetHashValue;
    end));
  for i := 0 to length(VertexData) - 1 do
  begin
    if not VertexTable.ContainsKey(VertexData[i]) then
    begin
      VertexTable.add(VertexData[i], VertexData[i].Normal);
    end
    else
    begin
      VertexTable[VertexData[i]] := VertexTable[VertexData[i]] + VertexData[i].Normal
    end;
  end;
  for i := 0 to length(VertexData) - 1 do
      VertexData[i].SmoothedNormal := VertexTable[VertexData[i]].Normalize;
  VertexTable.Free;
end;

procedure TMeshAnimatedGeometry.ComputeTangentsAndBinormals(VertexData : AVertexData; IndexData : AIndexData);
var
  tan1, tan2 : TArray<RVector3>;
  a, i1, i2, i3 : integer;
  v1, v2, v3 : RVector3;
  w1, w2, w3 : RVector2;
  sdir, tdir, n, t : RVector3;
  x1, x2, y1, y2, z1, z2, s1, s2, t1, t2, r : single;
begin
  // Algorithm from http://www.terathon.com/code/tangent.html
  setLength(tan1, length(VertexData));
  setLength(tan2, length(VertexData));
  ZeroMemory(tan1, length(VertexData) * sizeof(RVector3));
  ZeroMemory(tan2, length(VertexData) * sizeof(RVector3));
  assert(length(IndexData) mod 3 = 0);

  for a := 0 to (length(IndexData) div 3) - 1 do
  begin
    i1 := IndexData[a * 3 + 0];
    i2 := IndexData[a * 3 + 1];
    i3 := IndexData[a * 3 + 2];

    v1 := VertexData[i1].Position[0];
    v2 := VertexData[i2].Position[0];
    v3 := VertexData[i3].Position[0];

    w1 := VertexData[i1].TextureCoordinate;
    w2 := VertexData[i2].TextureCoordinate;
    w3 := VertexData[i3].TextureCoordinate;

    x1 := v2.x - v1.x;
    x2 := v3.x - v1.x;
    y1 := v2.y - v1.y;
    y2 := v3.y - v1.y;
    z1 := v2.z - v1.z;
    z2 := v3.z - v1.z;

    s1 := w2.x - w1.x;
    s2 := w3.x - w1.x;
    t1 := w2.y - w1.y;
    t2 := w3.y - w1.y;

    r := (s1 * t2 - s2 * t1);
    if r = 0 then continue;
    r := 1 / r;
    sdir := RVector3.Create((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);
    tdir := RVector3.Create((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);

    tan1[i1] := tan1[i1] + sdir;
    tan1[i2] := tan1[i2] + sdir;
    tan1[i3] := tan1[i3] + sdir;

    tan2[i1] := tan2[i1] + tdir;
    tan2[i2] := tan2[i2] + tdir;
    tan2[i3] := tan2[i3] + tdir;
  end;
  for a := 0 to length(VertexData) - 1 do
  begin
    n := VertexData[a].Normal;
    t := tan1[a];

    // Gram-Schmidt orthogonalize
    VertexData[a].Tangent := (t - (n * n.Dot(t))).Normalize();

    // Calculate handedness
    VertexData[a].Binormal := VertexData[a].Normal.Cross(VertexData[a].Tangent).Normalize;
    VertexData[a].Binormal := VertexData[a].Binormal * Sign(n.Cross(t).Dot(tan2[a]));
  end;
end;

{ TMeshGeometryAnimatedXFile.TSkin }

function TMeshAnimatedGeometry.TSkin.ComputeAnimatedMatrices : TArray<RMatrix4x3>;
var
  i : integer;
begin
  for i := 0 to length(FSkinBoneLinks) - 1 do
      FOutDataComputeAnimatedMatrix[i] := FSkinBoneLinks[i].TargetBone.CombinedMatrix * FSkinBoneLinks[i].BoneSpaceOffsetMatrix;
  Result := FOutDataComputeAnimatedMatrix;
end;

constructor TMeshAnimatedGeometry.TSkin.Create(SkinBoneLinkCount : integer);
begin
  setLength(FSkinBoneLinks, SkinBoneLinkCount);
  setLength(FOutDataComputeAnimatedMatrix, SkinBoneLinkCount);
end;

function TMeshAnimatedGeometry.TSkin.GetCopy(BoneMapping : TBoneMapping) : TSkin;
var
  i : integer;
begin
  Result := TSkin.Create(length(FSkinBoneLinks));
  for i := 0 to length(FSkinBoneLinks) - 1 do
  begin
    Result.FSkinBoneLinks[i] := FSkinBoneLinks[i];
    Result.FSkinBoneLinks[i].TargetBone := BoneMapping[FSkinBoneLinks[i].TargetBone];
  end;
end;

{ TMeshGeometryAnimatedXFile.TBone }

procedure TMeshAnimatedGeometry.TBone.AddBoneAnimation(const Translation, Scale : RVector3; const Rotation : RQuaternion; Weight : single);
begin
  assert(HMath.inRange(Weight, 0, 1));
  ClearAnimatedMatricesIfOld;
  // if array already full, skip new animations
  if FBoneAnimationsCount < (MAX_ANIMATIONS_PER_FRAME - 1) then
  begin
    FBoneAnimations[FBoneAnimationsCount].Translation := Translation;
    FBoneAnimations[FBoneAnimationsCount].Scale := Scale;
    FBoneAnimations[FBoneAnimationsCount].Rotation := Rotation;
    FBoneAnimations[FBoneAnimationsCount].Weight := Weight;
    inc(FBoneAnimationsCount);
  end;
end;

procedure TMeshAnimatedGeometry.TBone.ClearAnimatedMatricesIfOld;
begin
  // new frame? -> all old animated matrices not longer useful
  if GFXD.FPSCounter.FrameCount <> FLastFrameKey then
  begin
    FBoneAnimationsCount := 0;
    FOverwriteAnimation := False;
    FLastFrameKey := GFXD.FPSCounter.FrameCount;
  end;
end;

constructor TMeshAnimatedGeometry.TBone.Create(Data : TList<REngineRawMeshBone>);
var
  OwnData : REngineRawMeshBone;
  i : integer;
begin
  assert(Data.Count > 0);
  Create();
  OwnData := Data[0];
  Data.Delete(0);
  name := string(OwnData.Name);
  OriginalMatrix := OwnData.Matrix;
  setLength(ChildBones, OwnData.ChildCount);
  for i := 0 to OwnData.ChildCount - 1 do
      ChildBones[i] := TBone.Create(Data);
end;

constructor TMeshAnimatedGeometry.TBone.Create;
begin
  FBoneAnimationsCount := 0;
end;

constructor TMeshAnimatedGeometry.TBone.Create(Source : TMeshAssetBone);
var
  i : integer;
begin
  Create();
  setLength(ChildBones, Source.ChildCount);
  for i := 0 to Source.ChildCount - 1 do
      ChildBones[i] := TBone.Create(Source.Children[i]);
  name := Source.Name;
  OriginalMatrix := Source.LocalTransform.To4x3;
end;

destructor TMeshAnimatedGeometry.TBone.Destroy;
begin
  HArray.FreeAllObjects<TBone>(ChildBones, True);
  FBoneLookup.Free;
  inherited;
end;

function TMeshAnimatedGeometry.TBone.GetBoneByName(const BoneName : string) : TBone;
var
  Bone : TBone;
begin
  if not assigned(FBoneLookup) then
  begin
    FBoneLookup := TDictionary<string, TBone>.Create;
    for Bone in ToArray do
        FBoneLookup.AddOrSetValue(Bone.Name.ToLowerInvariant, Bone);
  end;
  // if no child or self match name this value will returned
  if not FBoneLookup.TryGetValue(BoneName.ToLowerInvariant, Result) then
      Result := nil;
end;

function TMeshAnimatedGeometry.TBone.GetCopy(var BoneMapping : TBoneMapping) : TBone;
var
  i : integer;
begin
  Result := TBone.Create;
  // new bone instance, new mapping
  BoneMapping.add(self, Result);
  Result.Name := name;
  Result.CombinedMatrix := CombinedMatrix;
  Result.OriginalMatrix := OriginalMatrix;
  setLength(Result.ChildBones, length(self.ChildBones));
  for i := 0 to length(self.ChildBones) - 1 do
      Result.ChildBones[i] := ChildBones[i].GetCopy(BoneMapping);
end;

procedure TMeshAnimatedGeometry.TBone.OverwriteBoneAnimation(const Tranformation : RMatrix4x3);
begin
  ClearAnimatedMatricesIfOld;
  FOverwriteAnimation := True;
  FOverwriteTransformation := Tranformation;
end;

procedure TMeshAnimatedGeometry.TBone.PassAnimationToHierarchy(const ParentMatrix : RMatrix4x3);
var
  i : integer;
  animatedMatrix : RMatrix4x3;
  animatedTranslation : RVector3;
  animatedScale : RVector3;
  animatedRotation : RQuaternion;
  weightSum : single;
begin
  ClearAnimatedMatricesIfOld;
  // overwrite is enabled, only use the setted transformation and ignore all other data
  if FOverwriteAnimation then
      animatedMatrix := OriginalMatrix * FOverwriteTransformation
  else
  begin
    if FBoneAnimationsCount > 0 then
    // sum up weighted all animatedmatrices for bone
    begin
      animatedTranslation := RVector3.ZERO;
      animatedScale := RVector3.ZERO;
      animatedRotation := RQuaternion.ZERO;
      for i := 0 to FBoneAnimationsCount - 1 do
      begin
        animatedTranslation := animatedTranslation + (FBoneAnimations[i].Weight * FBoneAnimations[i].Translation);
        animatedScale := animatedScale + (FBoneAnimations[i].Weight * FBoneAnimations[i].Scale);
      end;
      animatedRotation := FBoneAnimations[0].Rotation;
      weightSum := FBoneAnimations[0].Weight;
      for i := 1 to FBoneAnimationsCount - 1 do
      begin
        animatedRotation := animatedRotation.Slerp(FBoneAnimations[i].Rotation, FBoneAnimations[i].Weight / (FBoneAnimations[i].Weight + weightSum));
      end;
      animatedMatrix := RMatrix4x3.CreateTranslation(animatedTranslation) * animatedRotation.QuaternionToMatrix4x3 * RMatrix4x3.CreateScaling(animatedScale);
    end
    // no animation for bone? use matrix from meshhierarchy
    else
        animatedMatrix := OriginalMatrix;
  end;
  CombinedMatrix := ParentMatrix * animatedMatrix;
  for i := 0 to length(ChildBones) - 1 do
      ChildBones[i].PassAnimationToHierarchy(CombinedMatrix);
end;

function TMeshAnimatedGeometry.TBone.ToArray : TArray<TBone>;
var
  Child : TBone;
begin
  Result := [self];
  for Child in ChildBones do
      Result := Result + Child.ToArray;
end;

{ TSkinnedMeshAnimationDriver }

constructor TSkinnedMeshAnimationDriver.Create(TargetGeometry : TMeshAnimatedGeometry; AnimationData : TArray<TMeshAssetAnimationBone>);
var
  i : integer;
  function GetAnimationLength(Animation : TMeshAssetAnimation) : int64;
  var
    i : integer;
  begin
    Result := 0;
    // search for longest animation
    for i := 0 to Animation.AsBoneAnimation.AnimationChannelCount - 1 do
      if Animation.AsBoneAnimation.AnimationChannels[i].KeyFrameCount > 0 then
        // last keyframe always save longest timestamp
          Result := Max(Animation.AsBoneAnimation.AnimationChannels[i].KeyFrames[Animation.AsBoneAnimation.AnimationChannels[i].KeyFrameCount - 1].Time, Result)
      else
          Result := 0;
  end;

begin
  inherited Create;
  FSkin := TargetGeometry.FSkin;
  FRootBone := TargetGeometry.FRootBone;
  for i := 0 to length(AnimationData) - 1 do
      FAnimationData.add(string(AnimationData[i].Name),
      TSkinnedMeshAnimationData.Create(string(AnimationData[i].Name), GetAnimationLength(AnimationData[i]), AnimationData[i].AsBoneAnimation, FRootBone));
end;

destructor TSkinnedMeshAnimationDriver.Destroy;
begin
  if FOwnsSkinAndRootBone then
  begin
    FRootBone.Free;
    FSkin.Free;
  end;
  inherited;
end;

function TSkinnedMeshAnimationDriver.GenerateShaderBitmask(CurrentStatus : EnumAnimationState) : SetDefaultShaderFlags;
begin
  // use everytime (if mesh really has a skin) skinning, because even if no animation is playing, bones can effect
  // mesh, e.g. with manuall set transformation for bone
  if HasSkin then
      Result := [sfSkinning]
  else Result := [];
end;

function TSkinnedMeshAnimationDriver.GetCopy : TSkinnedMeshAnimationDriver;
var
  key : string;
  original, Data : TSkinnedMeshAnimationData;
  i : integer;
  BoneMapping : TMeshAnimatedGeometry.TBoneMapping;
begin
  Result := TSkinnedMeshAnimationDriver.Create();
  // first need a rootbone copy, because data depends on bones, need a mapping from old data to new data
  BoneMapping := TMeshAnimatedGeometry.TBoneMapping.Create();
  Result.FRootBone := FRootBone.GetCopy(BoneMapping);
  // secound need s skincopy and use the bonemapping here
  if assigned(FSkin) then
      Result.FSkin := FSkin.GetCopy(BoneMapping);
  // because the result has copies from root and skin, from now the driver has to free both
  Result.FOwnsSkinAndRootBone := True;

  for key in FAnimationData.Keys do
  begin
    original := TSkinnedMeshAnimationData(FAnimationData[key]);
    Data := TSkinnedMeshAnimationData.Create();
    Data.SubAnimationData := Copy(original.SubAnimationData);
    for i := 0 to length(Data.SubAnimationData) - 1 do
        Data.SubAnimationData[i].TargetBone := BoneMapping[Data.SubAnimationData[i].TargetBone];
    Data.Name := original.Name;
    Data.DefaultLength := original.DefaultLength;
    Data.FFrameCount := original.FFrameCount;
    Result.FAnimationData.add(key, Data);
  end;

  BoneMapping.Free;
end;

function TSkinnedMeshAnimationDriver.HasSkin : boolean;
begin
  Result := assigned(FSkin);
end;

procedure TSkinnedMeshAnimationDriver.ImportAnimationFromFile(const FileName, OverrideName : string);
var
  AnimationFile : TMeshAnimatedGeometry;
  driver : TSkinnedMeshAnimationDriver;
  original, Data : TSkinnedMeshAnimationData;
  Bone : TMeshAnimatedGeometry.TBone;
  key, BoneName : string;
  i : integer;
begin
  AnimationFile := nil;
  try
    AnimationFile := TMeshAnimatedGeometry.CreateFromFile(FileName, GFXD);
    driver := AnimationFile.SkinAnimationDriver;
    if driver.FAnimationData.Count > 1 then
        HLog.Write(elError, 'TSkinnedMeshAnimationDriver.ImportAnimationFromFile: At the moment only file with one animation are supported.', ENotSupportedException);
    if driver.FAnimationData.Count <= 0 then
        raise EAnimationNotFound.CreateFmt('TSkinnedMeshAnimationDriver.ImportAnimationFromFile: File "%s" doesn''t contain any animationdata.', [FileName]);
    // iterate for future, because only one data are there
    for key in driver.FAnimationData.Keys do
    begin
      original := TSkinnedMeshAnimationData(driver.FAnimationData[key]);
      Data := TSkinnedMeshAnimationData.Create();
      Data.SubAnimationData := Copy(original.SubAnimationData);
      // map from destinationbones to current mesh bones
      for i := 0 to length(Data.SubAnimationData) - 1 do
      begin
        BoneName := Data.SubAnimationData[i].TargetBone.Name;
        Bone := FRootBone.GetBoneByName(BoneName);
        if assigned(Bone) then
            Data.SubAnimationData[i].TargetBone := Bone
        else
        begin
          Data.Free;
          HLog.Write(elError, 'TSkinnedMeshAnimationDriver.ImportAnimationFromFile: Skeleton is not compatible. Could not find bone "%s"', [BoneName], ENotSupportedException);
        end;
      end;
      if OverrideName <> '' then Data.Name := OverrideName
      else Data.Name := original.Name;
      // avoid duplicate animationnames
      if FAnimationData.ContainsKey(Data.Name) then
      begin
        Data.Name := ChangeFileExt(ExtractFileName(FileName), '') + '_' + Data.Name;
        if FAnimationData.ContainsKey(Data.Name) then
            raise EAnimationError.Create('TSkinnedMeshAnimationDriver.ImportAnimationFromFile: Animationdata was already loaded.');

      end;
      Data.DefaultLength := original.DefaultLength;
      FAnimationData.add(Data.Name, Data);
    end;
  finally
    AnimationFile.Free;
  end;
end;

procedure TSkinnedMeshAnimationDriver.SetShaderSettings(RenderContext : TRenderContext);
var
  AnimatedMatrices : TArray<RMatrix4x3>;
begin
  if HasSkin then
  begin
    AnimatedMatrices := FSkin.ComputeAnimatedMatrices;
    assert(length(AnimatedMatrices) <= HW_MAX_BONES, Format('Mesh has too many bones! (%d, max %d are allowed)', [length(AnimatedMatrices), HW_MAX_BONES]));
    RenderContext.CurrentShader.SetShaderConstantArray<RMatrix4x3>('BoneTransforms', AnimatedMatrices);
  end;
end;

procedure TSkinnedMeshAnimationDriver.UpdateAnimation(const Animation : string; const Timekey : RTimeframe; Direction : integer; Weight : single);
begin
  // compute animation
  inherited;
  if HasSkin then
      FRootBone.PassAnimationToHierarchy(RMatrix4x3.IDENTITY);
end;

procedure TSkinnedMeshAnimationDriver.UpdateWithoutAnimation;
begin
  if HasSkin then
      FRootBone.PassAnimationToHierarchy(RMatrix4x3.IDENTITY);
end;

{ TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData }

constructor TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData.Create(Name : string; DefaultLength : int64; Data : TMeshAssetAnimationBone; RootBone : TMeshAnimatedGeometry.TBone);
var
  i, TargetIndex, i2, FinalArrayLength : integer;
begin
  inherited Create;
  FName := name;
  // animationspeed correction, because at default xfileanimation to slow
  DefaultLength := DefaultLength{ * ANIMATIONSPEEDCORRECTIONFACTOR };
  FDefaultlength := DefaultLength;
  setLength(SubAnimationData, Data.AnimationChannelCount);
  FinalArrayLength := Data.AnimationChannelCount;
  assert(assigned(RootBone));
  i := 0;
  TargetIndex := 0;
  while (TargetIndex < FinalArrayLength) do
  begin
    // only add skinlink if target bone really exist and there are any keyframes
    if assigned(RootBone.GetBoneByName(string(Data.AnimationChannels[i].TargetBone))) and (Data.AnimationChannels[i].KeyFrameCount > 0) then
    begin
      SubAnimationData[TargetIndex].TargetBone := RootBone.GetBoneByName(string(Data.AnimationChannels[i].TargetBone));
      setLength(SubAnimationData[TargetIndex].KeyFrames, Data.AnimationChannels[i].KeyFrameCount);
      FFrameCount := Max(FFrameCount, Data.AnimationChannels[i].KeyFrameCount);
      for i2 := 0 to Data.AnimationChannels[i].KeyFrameCount - 1 do
      begin
        // normalize data in range 0..1
        SubAnimationData[TargetIndex].KeyFrames[i2].PointInTime := Data.AnimationChannels[i].KeyFrames[i2].Time{ * ANIMATIONSPEEDCORRECTIONFACTOR } / DefaultLength;
        SubAnimationData[TargetIndex].KeyFrames[i2].Translation := Data.AnimationChannels[i].KeyFrames[i2].Translation; // .Transpose;
        SubAnimationData[TargetIndex].KeyFrames[i2].Scale := Data.AnimationChannels[i].KeyFrames[i2].Scale;
        SubAnimationData[TargetIndex].KeyFrames[i2].Rotation := Data.AnimationChannels[i].KeyFrames[i2].Rotation;
      end;
      // only use next target datablock, if data was saved
      inc(TargetIndex);
    end
    // if a skinlink is dropped, less targetdata is nessecary
    else dec(FinalArrayLength);
    inc(i);
  end;
  // adjust arraylength, because some bonelinks maybe are skipped
  setLength(SubAnimationData, FinalArrayLength);
end;

function TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData.Clone : TAnimationData;
begin
  raise ENotImplemented.Create('TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData.Clone: Not implemented!');
end;

constructor TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData.Create;
begin

end;

destructor TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData.Destroy;
begin
  SubAnimationData := nil;
  inherited;
end;

function TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData.ExtractPart(StartFrame, EndFrame : integer) : TAnimationData;
var
  i, frame : integer;
  newAnimation : TSkinnedMeshAnimationData;
begin
  assert(EndFrame >= StartFrame);
  // check if there is enough data
  for i := 0 to length(SubAnimationData) - 1 do
  begin
    if length(SubAnimationData[i].KeyFrames) < EndFrame then
        HLog.Write(elWarning, 'TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData.ExtractPart: Subanimation does not' +
        ' contains enough frames to copy animationdata (Keyframes: %d/Wanted keyframes: %d Bone: %s)', [length(SubAnimationData[i].KeyFrames), EndFrame, SubAnimationData[i].TargetBone.Name], ENotSupportedException);
    StartFrame := Min(StartFrame, length(SubAnimationData[i].KeyFrames) - 1);
    EndFrame := Min(EndFrame, length(SubAnimationData[i].KeyFrames) - 1);
  end;
  // start copy
  newAnimation := TSkinnedMeshAnimationData.Create;
  // set result already here, because an early exit needs an result
  Result := newAnimation;
  // no data, empty class is sufficent
  if length(SubAnimationData) < 1 then exit;
  newAnimation.DefaultLength := round(DefaultLength * (SubAnimationData[0].KeyFrames[EndFrame].PointInTime - SubAnimationData[0].KeyFrames[StartFrame].PointInTime));
  setLength(newAnimation.SubAnimationData, length(SubAnimationData));
  for i := 0 to length(SubAnimationData) - 1 do
  begin
    newAnimation.SubAnimationData[i].TargetBone := SubAnimationData[i].TargetBone;
    setLength(newAnimation.SubAnimationData[i].KeyFrames, EndFrame - StartFrame + 1);
    for frame := StartFrame to EndFrame do
    begin
      newAnimation.SubAnimationData[i].KeyFrames[frame - StartFrame].PointInTime := (frame - StartFrame) / (EndFrame - StartFrame);
      newAnimation.SubAnimationData[i].KeyFrames[frame - StartFrame].Translation := SubAnimationData[i].KeyFrames[frame].Translation;
      newAnimation.SubAnimationData[i].KeyFrames[frame - StartFrame].Scale := SubAnimationData[i].KeyFrames[frame].Scale;
      newAnimation.SubAnimationData[i].KeyFrames[frame - StartFrame].Rotation := SubAnimationData[i].KeyFrames[frame].Rotation;
    end;
  end;
end;

procedure TSkinnedMeshAnimationDriver.TSkinnedMeshAnimationData.UpdateAnimation(const Timekey : RTimeframe; Direction : integer; Weight : single);
var
  i : integer;
begin
  // writeln(GFXD.FPSCounter.FrameCount, ' - Timekey: ', FloattostrF(Timekey.Endtime, ffFixed, 100, 10000, EngineFloatFormatSettings), 'Weight: ', FloattostrF(Weight, ffFixed, 100, 10000, EngineFloatFormatSettings));
  // for Skinned animation only current time (endtime) affects animation
  for i := 0 to length(SubAnimationData) - 1 do
      SubAnimationData[i].UpdateAnimation(Timekey.Endtime, Direction, Weight);
end;

{ TSkinnedMeshAnimationDriver.RSkinnedMeshSubAnimationData }

procedure TSkinnedMeshAnimationDriver.RSkinnedMeshSubAnimationData.UpdateAnimation(Timekey : single; Direction : integer; Weight : single);

/// <summary> Search for the two indices, where the point in time is in between</summary>
  procedure GetKeyFrameIndices(out first, Sec : integer);
  var
    searchDirection : integer;
  begin
    // if there are only two or less frames, simple use them
    if length(KeyFrames) <= 2 then
    begin
      first := low(KeyFrames);
      Sec := high(KeyFrames);
    end
    else
    // guess index
    begin
      // second
      Sec := trunc((length(KeyFrames) - 1) * Timekey);
      first := Max(Sec - 1, 0);
      while not((KeyFrames[first].PointInTime <= Timekey) and (Timekey <= KeyFrames[Sec].PointInTime)) do
      begin
        searchDirection := CompareValue(Timekey, KeyFrames[Sec].PointInTime);
        Sec := HMath.Clamp(Sec + searchDirection, 0, high(KeyFrames));
        first := HMath.Clamp(Sec - 1, 0, high(KeyFrames));
        if (first <= 0) or (Sec >= high(KeyFrames)) or (searchDirection = 0) then
            break;
      end;
    end;
  end;

var
  Index1, Index2 : integer;
  a : single;
  Translation, Scale : RVector3;
  Rotation : RQuaternion;
begin
  // if bone has no data, we can't animate it, so default matrix will do the job
  if length(KeyFrames) > 0 then
  begin
    assert(Direction = 1, 'Currently not support reverse playback.');
    assert((Direction = -1) or (Direction = 1));
    assert((Timekey >= 0) and (Timekey <= 1));
    assert(assigned(TargetBone));

    GetKeyFrameIndices(Index1, Index2);
    if Index1 = Index2 then a := 1
    else a := 1 - ((Timekey - KeyFrames[Index1].PointInTime) / abs(KeyFrames[Index2].PointInTime - KeyFrames[Index1].PointInTime));
    a := HMath.Saturate(a);
    Translation := (KeyFrames[Index1].Translation.Lerp(KeyFrames[Index2].Translation, 1 - a));
    Scale := (KeyFrames[Index1].Scale.Lerp(KeyFrames[Index2].Scale, 1 - a));
    Rotation := (KeyFrames[Index1].Rotation.Slerp(KeyFrames[Index2].Rotation, 1 - a));
    TargetBone.AddBoneAnimation(Translation, Scale, Rotation, Weight);
  end;
end;

{ TMeshMorphAnimationDriver }

procedure TMeshMorphAnimationDriver.ClearDataIfOld;
begin
  // new frame? -> all old animated weights not longer useful
  if GFXD.FPSCounter.FrameCount <> FLastFrameKey then
  begin
    ZeroMemory(@FCurrentMorphweights[0], sizeof(FCurrentMorphweights));
    FLastFrameKey := GFXD.FPSCounter.FrameCount;
  end;
end;

constructor TMeshMorphAnimationDriver.Create(TargetGeometry : TMeshAnimatedGeometry; AnimationData : TArray<TMeshAssetAnimationMorph>; MorphtargetMapping : TArray<string>);
var
  i : integer;
  MorphAnimationData : TMeshAssetAnimationMorph;
begin
  inherited Create;
  FMorphtargetCount := length(MorphtargetMapping);
  // split data for each animation, e.g. walk, attack
  for i := 0 to length(AnimationData) - 1 do
  begin
    MorphAnimationData := AnimationData[i].AsMorphAnimation;
    FAnimationData.add(string(AnimationData[i].Name), TMorphAnimationData.Create(MorphAnimationData, MorphtargetMapping));
  end;
end;

destructor TMeshMorphAnimationDriver.Destroy;
begin

  inherited;
end;

function TMeshMorphAnimationDriver.GenerateShaderBitmask(CurrentStatus : EnumAnimationState) : SetDefaultShaderFlags;
begin
  if HasMorph then
  begin
    case FMorphtargetCount of
      1 : Result := [EnumDefaultShaderFlags.sfMorphtarget1];
      2 : Result := [EnumDefaultShaderFlags.sfMorphtarget2];
      3 : Result := [EnumDefaultShaderFlags.sfMorphtarget3];
      4 : Result := [EnumDefaultShaderFlags.sfMorphtarget4];
      5 : Result := [EnumDefaultShaderFlags.sfMorphtarget5];
      6 : Result := [EnumDefaultShaderFlags.sfMorphtarget6];
      7 : Result := [EnumDefaultShaderFlags.sfMorphtarget7];
      8 : Result := [EnumDefaultShaderFlags.sfMorphtarget8];
    end;
  end
  else Result := [];
end;

function TMeshMorphAnimationDriver.GetCopy : TMeshMorphAnimationDriver;
var
  key : string;
begin
  Result := TMeshMorphAnimationDriver.Create();
  Result.FMorphtargetCount := FMorphtargetCount;
  Result.FCurrentMorphweights := FCurrentMorphweights;;
  Result.FLastFrameKey := FLastFrameKey;
  for key in FAnimationData.Keys do
  begin
    Result.FAnimationData.add(key, FAnimationData[key].Clone);
  end;
end;

function TMeshMorphAnimationDriver.HasMorph : boolean;
begin
  Result := FMorphtargetCount > 0;
end;

procedure TMeshMorphAnimationDriver.ImportAnimationFromFile(const FileName, OverrideName : string);
begin
  raise ENotImplemented.Create('TMeshMorphAnimationDriver.ImportAnimationFromFile: Not implemented!');
end;

procedure TMeshMorphAnimationDriver.SetShaderSettings(RenderContext : TRenderContext);
var
  CurrentMorphweights : array [0 .. MAX_MORPH_TARGET_COUNT - 1] of single;
  i : integer;
begin
  if HasMorph then
  begin
    ZeroMemory(@CurrentMorphweights[0], sizeof(CurrentMorphweights));
    for i := 0 to length(FCurrentMorphweights) - 1 do
        CurrentMorphweights[i] := FCurrentMorphweights[i] / 100;
    RenderContext.CurrentShader.SetShaderConstant(dcMorphweights, @CurrentMorphweights[0], sizeof(CurrentMorphweights));
  end;
end;

procedure TMeshMorphAnimationDriver.UpdateAnimation(const Animation : string; const Timeframe : RTimeframe; Direction : integer; Weight : single);
var
  i : integer;
begin
  ClearDataIfOld;
  if FAnimationData.ContainsKey(Animation) then
  begin
    // first update
    FAnimationData[Animation].UpdateAnimation(Timeframe, Direction, Weight);
    // then apply data to global weight array
    for i := 0 to length(FCurrentMorphweights) - 1 do
        FCurrentMorphweights[i] := FCurrentMorphweights[i] + TMorphAnimationData(FAnimationData[Animation]).FCurrentMorphweights[i];
  end;
end;

procedure TMeshMorphAnimationDriver.UpdateWithoutAnimation;
begin
  ClearDataIfOld;
end;

{ TMeshMorphAnimationDriver.TMorphAnimationData }

function TMeshMorphAnimationDriver.TMorphAnimationData.Clone : TAnimationData;
begin
  Result := TMorphAnimationData.Create();
  DoClone(Result);
end;

constructor TMeshMorphAnimationDriver.TMorphAnimationData.Create(MorphData : TMeshAssetAnimationMorph; MorphtargetMapping : TArray<string>);
var
  i, j, MorphChannel : integer;
  KeyFrames : TList<RMorphKeyFrame>;
  keyframe : RMorphKeyFrame;
begin
  Create;
  FName := string(MorphData.Name);
  for i := 0 to MorphData.AnimationChannelCount - 1 do
  begin
    MorphChannel := HArray.IndexOf(MorphtargetMapping, string(MorphData.AnimationChannels[i].MorphTarget));
    assert(MorphChannel >= 0, 'TMeshMorphAnimationDriver.TMorphAnimationData.Create: Found animation data for non-existing morphtarget!');
    assert(not FCurves.ContainsKey(MorphChannel), 'TMeshMorphAnimationDriver.TMorphAnimationData.Create: Found more than one curve for the same morphtarget!');
    assert(MorphChannel < MAX_MORPH_TARGET_COUNT, Format('TMeshMorphAnimationDriver.TMorphAnimationData.Create: Too many morphtargets, only %d are allowed!', [MAX_MORPH_TARGET_COUNT]));
    if (MorphChannel >= 0) and not FCurves.ContainsKey(MorphChannel) then
    begin
      KeyFrames := TList<RMorphKeyFrame>.Create;
      for j := 0 to MorphData.AnimationChannels[i].KeyFrameCount - 1 do
      begin
        keyframe.PointInTime := MorphData.AnimationChannels[i].KeyFrames[j].Time;
        FDefaultlength := Max(FDefaultlength, round(keyframe.PointInTime));
        keyframe.Weight := MorphData.AnimationChannels[i].KeyFrames[j].Weight;
        KeyFrames.add(keyframe);
      end;
      FCurves.add(MorphChannel, KeyFrames);
      FFrameCount := Max(FFrameCount, KeyFrames.Count);
    end;
  end;
end;

constructor TMeshMorphAnimationDriver.TMorphAnimationData.Create;
begin
  FDefaultlength := 0;
  FCurves := TObjectDictionary < integer, TList < RMorphKeyFrame >>.Create([doOwnsValues]);
end;

constructor TMeshMorphAnimationDriver.TMorphAnimationData.CreateSlice(StartFrame, EndFrame : integer; Curves : TObjectDictionary < integer, TList < RMorphKeyFrame >> );
var
  key, i : integer;
  keyframe : RMorphKeyFrame;
  KeyFrames, PrevKeyFrames : TList<RMorphKeyFrame>;
begin
  FName := 'Slice';
  FFrameCount := EndFrame - StartFrame;
  // adjust Startframe and Endframe because Code only works with time and not with frame indizes
  StartFrame := round(StartFrame * 1000 / 30);
  EndFrame := round(EndFrame * 1000 / 30);
  FDefaultlength := EndFrame - StartFrame;
  FCurves := TObjectDictionary < integer, TList < RMorphKeyFrame >>.Create([doOwnsValues]);
  for key in Curves.Keys do
  begin
    KeyFrames := TList<RMorphKeyFrame>.Create;
    PrevKeyFrames := Curves[key];
    for i := 0 to PrevKeyFrames.Count - 1 do
    begin
      if (i < PrevKeyFrames.Count - 1) and (PrevKeyFrames[i].PointInTime < StartFrame) and (PrevKeyFrames[i + 1].PointInTime > StartFrame) then
      begin
        // lerp starting key
        keyframe := PrevKeyFrames[i].Lerp(PrevKeyFrames[i + 1], (StartFrame - PrevKeyFrames[i].PointInTime) / (PrevKeyFrames[i + 1].PointInTime - PrevKeyFrames[i].PointInTime))
      end
      else
        if (PrevKeyFrames[i].PointInTime >= StartFrame) and (PrevKeyFrames[i].PointInTime <= EndFrame) then
      begin
        // adds frame between
        keyframe := PrevKeyFrames[i];
      end
      else
        if (i > 0) and (PrevKeyFrames[i].PointInTime > EndFrame) and (PrevKeyFrames[i - 1].PointInTime < EndFrame) then
      begin
        // lerp final key
        keyframe := PrevKeyFrames[i].Lerp(PrevKeyFrames[i - 1], (EndFrame - PrevKeyFrames[i - 1].PointInTime) / (PrevKeyFrames[i].PointInTime - PrevKeyFrames[i - 1].PointInTime))
      end
      else continue;
      KeyFrames.add(keyframe);
    end;
    // now the slice have been build, we have to normalize the timeline, so it has no offset and start by 0
    for i := 0 to KeyFrames.Count - 1 do
    begin
      keyframe := KeyFrames[i];
      keyframe.PointInTime := keyframe.PointInTime - StartFrame;
      KeyFrames[i] := keyframe;
    end;
    FCurves.add(key, KeyFrames);
  end;
end;

destructor TMeshMorphAnimationDriver.TMorphAnimationData.Destroy;
begin
  FCurves.Free;
  inherited;
end;

procedure TMeshMorphAnimationDriver.TMorphAnimationData.DoClone(Clone : TAnimationData);
var
  i : integer;
begin
  inherited DoClone(Clone);
  TMorphAnimationData(Clone).FCurrentMorphweights := FCurrentMorphweights;
  for i in FCurves.Keys do
  begin
    TMorphAnimationData(Clone).FCurves.add(i, TAdvancedList<RMorphKeyFrame>(FCurves[i]).Clone);
  end;
end;

function TMeshMorphAnimationDriver.TMorphAnimationData.ExtractPart(StartFrame, EndFrame : integer) : TAnimationData;
var
  slice : TMorphAnimationData;
begin
  slice := TMorphAnimationData.CreateSlice(StartFrame, EndFrame, FCurves);
  Result := slice;
end;

procedure TMeshMorphAnimationDriver.TMorphAnimationData.UpdateAnimation(const Timeframe : RTimeframe; Direction : integer; Weight : single);
var
  index, i : integer;
  KeyFrames : TList<RMorphKeyFrame>;
  keyframe : RMorphKeyFrame;
begin
  ZeroMemory(@FCurrentMorphweights[0], sizeof(FCurrentMorphweights));
  if Weight <= 0.0 then
  begin
    exit;
  end;
  for index in FCurves.Keys do
  begin
    KeyFrames := FCurves[index];
    keyframe := HArray.InterpolateLinear<RMorphKeyFrame>(
      KeyFrames.ToArray,
      Timeframe.Endtime * FDefaultlength,
      function(const item : RMorphKeyFrame) : single
      begin
        Result := item.PointInTime;
      end,
      function(itemA, itemB : RMorphKeyFrame; Factor : single) : RMorphKeyFrame
      begin
        Result := itemA.Lerp(itemB, Factor);
      end);
    FCurrentMorphweights[index] := keyframe.Weight;
  end;
  for i := 0 to length(FCurrentMorphweights) - 1 do
      FCurrentMorphweights[i] := FCurrentMorphweights[i] * Weight;
end;

{ TMeshMorphAnimationDriver.RMorphKeyFrame }

function TMeshMorphAnimationDriver.RMorphKeyFrame.Lerp(itemB : RMorphKeyFrame; Factor : single) : RMorphKeyFrame;
begin
  Result.PointInTime := self.PointInTime * (1 - Factor) + itemB.PointInTime * Factor;
  Result.Weight := self.Weight * (1 - Factor) + itemB.Weight * Factor;
end;

{ RMeshShader }

constructor RMeshShader.Create(const ShaderPath : string; SetUp : ProcSetUpShader; NeedsOwnPass : SetRenderStage; OwnPasses : integer; OwnPassHideOriginal : boolean; BlendMode : EnumBlendMode; Tag : NativeUInt);
begin
  self.Shader := ShaderPath;
  self.SetUp := SetUp;
  self.NeedsOwnPass := NeedsOwnPass;
  self.OwnPasses := OwnPasses;
  self.OwnPassHideOriginal := OwnPassHideOriginal;
  self.BlendMode := BlendMode;
  self.Tag := Tag;
end;

function RMeshShader.RendersInOwnPass : boolean;
begin
  Result := NeedsOwnPass <> [];
end;

end.

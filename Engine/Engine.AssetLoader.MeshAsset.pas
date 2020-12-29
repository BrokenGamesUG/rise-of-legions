unit Engine.AssetLoader.MeshAsset;

interface

uses
  // ========= Delphi =========
  System.Math,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  // ========= Engine ========
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.DataStructures;

const
  MAXINFLUENCINGBONES = 4;

type
  ABoneIndices = array [0 .. MAXINFLUENCINGBONES - 1] of integer;
  ABoneWeights = array [0 .. MAXINFLUENCINGBONES - 1] of Single;

  EMeshAssetInvalidOperation = class(Exception);

  RSkinBoneLink = record
    BoneSpaceMatrix : RMatrix;
    TargetBone : string;
    constructor Create(const BoneSpaceMatrix : RMatrix; const TargetBone : string);
  end;

  RMeshAssetVertex = record
    /// <summary> 3D Position</summary>
    Position : RVector3;
    Color : RColor;
    /// <summary> 3D Normal</summary>
    Normal : RVector3;
    Tangent : RVector3;
    Binormal : RVector3;
    TextureCoordinate : RVector2;
    // index to bonelink
    Bones : ABoneIndices;
    // weight for bonelink
    BoneWeight : ABoneWeights;
    // current bones set a weights
    BoneCount : integer;
  end;

  TMeshAssetMorphTarget = class
    private
      FDiffPositions : TArray<RVector3>;
      FName : string;
      function GetDifferencePositionCount : integer;
      function GetDiffPosition(index : integer) : RVector3;
      procedure SetDifferencePositionCount(const Value : integer);
      procedure SetDiffPosition(index : integer; const Value : RVector3);
    public
      property name : string read FName write FName;
      property DifferencePosition[index : integer] : RVector3 read GetDiffPosition write SetDiffPosition;
      property DifferencePositionCount : integer read GetDifferencePositionCount write SetDifferencePositionCount;
  end;

  TMeshAssetSubset = class
    private
      FSubsetName : string;
      FHasNormals : boolean;
      FHasTangents : boolean;
      FHasBinormals : boolean;
      FHasColor : boolean;
      FHasTextureCoordinates : boolean;
      FMeshOffsetMatrix : RMatrix;
      FVertices : TArray<RMeshAssetVertex>;
      FSkinBoneLinks : TArray<RSkinBoneLink>;
      FMorphTargets : TArray<TMeshAssetMorphTarget>;
      function GetNormal(index : integer) : RVector3;
      function GetTextureCoordinate(index : integer) : RVector2;
      function GetVertexCount : integer;
      function GetVertexPosition(index : integer) : RVector3;
      function GetSkinBoneLink(index : integer) : RSkinBoneLink;
      function GetSkinBoneLinkCount : integer;
      function GetHasSkin : boolean;
      function GetBoneInfluencingCount(index : integer) : integer;
      function GetBonesIndices(index : integer) : ABoneIndices;
      function GetBoneWeight(index : integer) : ABoneWeights;
      function GetBinormal(index : integer) : RVector3;
      function GetTangent(index : integer) : RVector3;
      procedure SetBinormal(index : integer; const Value : RVector3);
      procedure SetBoneIndices(index : integer; const Value : ABoneIndices);
      procedure SetBoneInfluencingCount(index : integer; const Value : integer);
      procedure SetBoneWeights(index : integer; const Value : ABoneWeights);
      procedure SetNormal(index : integer; const Value : RVector3);
      procedure SetSkinBoneLink(index : integer; const Value : RSkinBoneLink);
      procedure SetSkinBoneLinkCount(const Value : integer);
      procedure SetTangent(index : integer; const Value : RVector3);
      procedure SetTextureCoordinate(index : integer; const Value : RVector2);
      procedure SetVertexCount(const Value : integer);
      function GetVertex(index : integer) : RMeshAssetVertex;
      procedure SetVertex(index : integer; const Value : RMeshAssetVertex);
      function GetMorphTargetCount : integer;
      procedure SetMorphTargetCount(const Value : integer);
      procedure SetVertexPosition(index : integer; const Value : RVector3);
      function GetMorphTarget(index : integer) : TMeshAssetMorphTarget;
      procedure SetMorphTarget(index : integer; const Value : TMeshAssetMorphTarget);
      function GetColor(index : integer) : RColor;
      procedure SetColor(index : integer; const Value : RColor);
    public
      property SubsetName : string read FSubsetName write FSubsetName;
      property MeshOffsetMatrix : RMatrix read FMeshOffsetMatrix write FMeshOffsetMatrix;
      property VertexPositions[index : integer] : RVector3 read GetVertexPosition write SetVertexPosition;
      property HasColor : boolean read FHasColor write FHasColor;
      property HasNormals : boolean read FHasNormals write FHasNormals;
      property HasTangents : boolean read FHasTangents write FHasTangents;
      property HasBinormals : boolean read FHasBinormals write FHasBinormals;
      property Colors[index : integer] : RColor read GetColor write SetColor;
      property Normals[index : integer] : RVector3 read GetNormal write SetNormal;
      property Tangents[index : integer] : RVector3 read GetTangent write SetTangent;
      property Binormals[index : integer] : RVector3 read GetBinormal write SetBinormal;
      property HasTextureCoordinates : boolean read FHasTextureCoordinates write FHasTextureCoordinates;
      property TextureCoordinate[index : integer] : RVector2 read GetTextureCoordinate write SetTextureCoordinate;
      property Vertices[index : integer] : RMeshAssetVertex read GetVertex write SetVertex;
      property VertexCount : integer read GetVertexCount write SetVertexCount;
      /// <summary> If true, mesh defines skindata, means it provides BoneIndices, BoneWeights and SkinBoneLinks.</summary>
      property HasSkin : boolean read GetHasSkin;
      /// <summary> Array of indices (with length = BoneInfluencingCount) of skinbonelinks for a vertex. Every index
      /// targets one SkinBoneLink.</summary>
      property BoneIndices[index : integer] : ABoneIndices read GetBonesIndices write SetBoneIndices;
      /// <summary> Array of weights (with length = BoneInfluencingCount) for SkinBoneLink of a vertex. Every weight
      /// describes the influence of a SkinBoneLink to the vertex. The sum of all weights is 1 or 0 (with variance of 0.01)</summary>
      property BoneWeights[index : integer] : ABoneWeights read GetBoneWeight write SetBoneWeights;
      property BoneInfluencingCount[index : integer] : integer read GetBoneInfluencingCount write SetBoneInfluencingCount;
      property SkinBoneLinks[index : integer] : RSkinBoneLink read GetSkinBoneLink write SetSkinBoneLink;
      property SkinBoneLinkCount : integer read GetSkinBoneLinkCount write SetSkinBoneLinkCount;
      property MorphTargets[index : integer] : TMeshAssetMorphTarget read GetMorphTarget write SetMorphTarget;
      property MorphTargetCount : integer read GetMorphTargetCount write SetMorphTargetCount;
      constructor Create;
      destructor Destroy; override;
  end;

  /// <summary> A bone in bone hierarchie.</summary>
  TMeshAssetBone = class(TTreeNode<TMeshAssetBone>)
    private
      FName : string;
      FLocalTransform : RMatrix;
      FTargetSubsets : TArray<TMeshAssetSubset>;
      function GetTargetSubset(index : integer) : TMeshAssetSubset;
      function GetTargetSubsetCount : integer;
      procedure SetTargetSubset(index : integer; const Value : TMeshAssetSubset);
      procedure SetTargetSubsetCount(const Value : integer);
    public
      /// <summary> Some Bones directly affect one or many subsets. Then the transform of this bone affects the subset transform.</summary>
      property TargetSubsets[index : integer] : TMeshAssetSubset read GetTargetSubset write SetTargetSubset;
      property TargetSubsetCount : integer read GetTargetSubsetCount write SetTargetSubsetCount;
      /// <summary> Name of the bone.</summary>
      property name : string read FName write FName;
      /// <summary> Defines a local transform for a bone in dependency of parent transform. It is not the BoneSpaceMatrix!
      /// Value is obsolet if some animation provide a new localtranform for this bone, but nessecary for e.g. set pivotpoint
      /// for bones while a bone not affected by any animation.</summary>
      property LocalTransform : RMatrix read FLocalTransform write FLocalTransform;
      /// <summary> Compute the complete matrix of this bone including all transformations from itself and his parents.</summary>
      function ComputeCompleteMatrix : RMatrix;
      /// <summary> Commite the bone complete transform (local transform including parenttransform)
      /// into the target subset matrix. This operation call also the method from his childnodes</summary>
      procedure ApplyBoneMatrixOnSubset;
      /// <summary> Create a TMeshAssetBone.
      /// <param name="Name"> Name of bone.</param></summary>
      constructor Create(Name : string);
  end;

  RKeyFrameBone = packed record
    public
      Time : integer;
      Translation : RVector3;
      Scale : RVector3;
      Rotation : RQuaternion;
  end;

  RKeyFrameMorph = packed record
    public
      /// <summary> Timekey in msec.</summary>
      Time : integer;
      /// <summary> Weight of the morphtarget that influences the whole mesh.</summary>
      Weight : Single;
      function Lerp(OtherKey : RKeyFrameMorph; Factor : Single) : RKeyFrameMorph;
  end;

  /// <summary> Base class of a animation channel. A animation channel saves the data (keyframes) of an an animtion
  /// an sets them in refrence to an target. The data and the target depening on animationtype.
  /// The Generice type K is the keyframe type.
  /// This class can't be directly used, it needs a specialized version with also saves the target.</summary>
  TMeshAssetAnimationChannel<K> = class abstract
    private
      FKeyFrames : TArray<K>;
      function GetKeyFrame(index : integer) : K;
      function GetKeyFrameCount : integer;
      procedure SetKeyFrame(index : integer; const Value : K);
      procedure SetKeyFrameCount(const Value : integer);
    public
      /// <summary> Array of keyframes. Length of KeyFrames = KeyFrameCount, to change the Length of KeyFrames
      /// set KeyFrameCount.</summary>
      property KeyFrames[index : integer] : K read GetKeyFrame write SetKeyFrame;
      /// <summary>  Key frame count. Set a value will directly influence the length of the KeyFrames array.</summary>
      property KeyFrameCount : integer read GetKeyFrameCount write SetKeyFrameCount;
      /// <summary> No special.</summary>
      constructor Create;
      constructor CreateFromStream(Stream : TStream);
      /// <summary> Save data to stream in binary format.</summary>
      procedure SaveToStream(Stream : TStream); virtual;
  end;

  /// <summary> AnimationChannel specialized version for bone animtions.</summary>
  TMeshAssetAnimationChannelBone = class(TMeshAssetAnimationChannel<RKeyFrameBone>)
    private
      FTargetBone : ShortString;
    public
      /// <summary> Name of target Bone for this channel. All keyframes only for this bone valid.</summary>
      property TargetBone : ShortString read FTargetBone write FTargetBone;
      procedure ClipAnimationsAgainstTimeSlot(StartTime : integer; EndTime : integer);
      constructor CreateFromStream(Stream : TStream);
      /// <summary> Save data to stream in binary format.</summary>
      procedure SaveToStream(Stream : TStream); override;
  end;

  /// <summary> AnimationChannel specialized version for bone animations.</summary>
  TMeshAssetAnimationChannelMorph = class(TMeshAssetAnimationChannel<RKeyFrameMorph>)
    private
      FMorphTarget : ShortString;
    public
      /// <summary> Name of the subset that is the morph target for this animationchannel.</summary>
      property MorphTarget : ShortString read FMorphTarget write FMorphTarget;
      procedure ClipAnimationsAgainstTimeSlot(StartTime : integer; EndTime : integer);
      constructor CreateFromStream(Stream : TStream);
      /// <summary> Save data to stream in binary format.</summary>
      procedure SaveToStream(Stream : TStream); override;
  end;

  /// <summary> Enumeration the identifies the type of an animation.</summary>
  EnumMeshAssetAnimationType = (
    atBoneAnimation, // Animation is a Bone Animation
    atMorphAnimation // Animation is a Morph Animation
    );

  // predefiniations
  TMeshAssetAnimationBone = class;
  TMeshAssetAnimationMorph = class;

  /// <summary> Base class of animations. Implements basic stuff that is shared by all animations,
  /// but need spezilation to be usable. This class is visible by user from TMeshAsset,
  /// so its provide some methods to interpret it as spezialized versions.</summary>
  TMeshAssetAnimation = class abstract
    private
      FName : ShortString;
      FAnimationType : EnumMeshAssetAnimationType;
    public
      /// <summary> Unique Name of the animation.</summary>
      property name : ShortString read FName;
      /// <summary> The Animationtype identifies the specilaized version of the animation (e.g. Morph, Bone, ...)</summary>
      property AnimationType : EnumMeshAssetAnimationType read FAnimationType;
      /// <summary> Interpret the Animation as MorphAnimation, will fail if AniamtionType is not atMorphAnimation.</summary>
      function AsMorphAnimation : TMeshAssetAnimationMorph;
      /// <summary> Interpret the Animation as BoneAnimation, will fail if AniamtionType is not atBoneAnimation.</summary>
      function AsBoneAnimation : TMeshAssetAnimationBone;
      /// <summary> Discard all frames in animationdata that is before starttime and after endtime. If there is no keyframe
      /// as this time, there will be one created with interpolation method.</summary>
      procedure ClipAnimationsAgainstTimeSlot(StartTime : integer; EndTime : integer); virtual; abstract;
      /// <summary> Init and sets the name.</summary>
      constructor Create(Name : ShortString);
      constructor CreateFromStream(Stream : TStream);
      procedure SaveToStream(Stream : TStream); virtual;
      /// <summary> No special.</summary>
      destructor Destroy; override;
  end;

  TMeshAssetAnimation<K : class> = class abstract(TMeshAssetAnimation)
    private
      FAnimationChannels : TArray<K>;
      function GetAnimationChannel(index : integer) : K;
      function GetAnimationChannelCount : integer;
      procedure SetAnimationChannel(index : integer; const Value : K);
      procedure SetAnimationChannelCount(const Value : integer);
    public
      property AnimationChannels[index : integer] : K read GetAnimationChannel write SetAnimationChannel;
      property AnimationChannelCount : integer read GetAnimationChannelCount write SetAnimationChannelCount;
      destructor Destroy; override;
  end;

  /// <summary> For bone animation specialized version of TMeshAssetAnimation<k>. Implements stuff
  /// thats only by Bone animations usable.</summary>
  TMeshAssetAnimationBone = class(TMeshAssetAnimation<TMeshAssetAnimationChannelBone>)
    public
      /// <summary> Init instance and set AnimationType to atBoneAnimation.</summary>
      constructor Create(Name : ShortString);
      constructor CreateFromStream(Stream : TStream);
      procedure ClipAnimationsAgainstTimeSlot(StartTime : integer; EndTime : integer); override;
      procedure SaveToStream(Stream : TStream); override;
  end;

  /// <summary> For morph animation specialized version of TMeshAssetAnimation<k>. Implements stuff
  /// thats only by Morph animations usable.</summary>
  TMeshAssetAnimationMorph = class(TMeshAssetAnimation<TMeshAssetAnimationChannelMorph>)
    public
      /// <summary> Init instance and set AnimationType to atMorphAnimation.</summary>
      constructor Create(Name : ShortString);
      constructor CreateFromStream(Stream : TStream);
      procedure ClipAnimationsAgainstTimeSlot(StartTime : integer; EndTime : integer); override;
      procedure SaveToStream(Stream : TStream); override;
  end;

  /// <summary> The mainclass of the Unit MeshAsset. A TMeshAsset is like the scene in a 3D model prog and combine all
  /// relevant aspects, like animations and geometrie data.</summary>
  TMeshAsset = class
    private
      FSubsets : TArray<TMeshAssetSubset>;
      FSkeleton : TTree<TMeshAssetBone>;
      FAnimations : TArray<TMeshAssetAnimation>;
      function GetSubset(index : integer) : TMeshAssetSubset;
      function GetSubsetCount : integer;
      function GetAnimation(index : integer) : TMeshAssetAnimation;
      function GetAnimationCount : integer;
      function GetHasAnimation : boolean;
      procedure SetAnimation(index : integer; const Value : TMeshAssetAnimation);
      procedure SetAnimationCount(const Value : integer);
      procedure SetSubset(index : integer; const Value : TMeshAssetSubset);
      procedure SetSubsetCount(const Value : integer);
      function GetSubsetByName(SubsetName : string) : TMeshAssetSubset;
      procedure SetSubsetByName(SubsetName : string; const Value : TMeshAssetSubset);
      function GetSubsetIndexByName(SubsetName : string) : integer;
    public
      /// <summary> The Skeleton as tree structure of this asset, every asset has exactly one rootbone.
      /// This property access the rootbone.</summary>
      property Skeleton : TTree<TMeshAssetBone> read FSkeleton;
      /// <summary> Access to subsets via index, a subset is a geometry element of a scene.</summary>
      property Subsets[index : integer] : TMeshAssetSubset read GetSubset write SetSubset;
      /// <summary> Access to subsets via name, a subset is a geometry element of a scene.</summary>
      property SubsetsByName[SubsetName : string] : TMeshAssetSubset read GetSubsetByName write SetSubsetByName;
      /// <summary> Count of subsets, change the subsetcount will directly effect the Subsets array.</summary>
      property SubsetCount : integer read GetSubsetCount write SetSubsetCount;
      /// <summary> Does the mesh provide any animationdata. Derived by AnimationCount.</summary>
      property HasAnimation : boolean read GetHasAnimation;
      /// <summary> Array of animations, length = AnimationCount. Use AnimationCount to change length of this array.</summary>
      property Animations[index : integer] : TMeshAssetAnimation read GetAnimation write SetAnimation;
      /// <summary> Count of animations. Change AnimationCount will directly effect the Animations array</summary>
      property AnimationCount : integer read GetAnimationCount write SetAnimationCount;
      /// <summary> Merge all subsets to one subset. Will apply meshoffsetmatrix to data and new meshoffsetmatrix
      /// will be identity. Any MorphTargets will be stay, but not merged into new subset
      /// <param name="DropDummySubsets"> While merging all dummy subsets are dropped. A dummy subset is identified by
      /// by not having any TextureCoordinates.</param>
      /// </summary>
      procedure CollapseSubsets(DropDummySubsets : boolean);
      /// <summary> Discard all frames in animationdata that is before starttime and after endtime. If there is no keyframe
      /// as this time, there will be one created with interpolation method.</summary>
      procedure ClipAnimationsAgainstTimeSlot(StartTime : integer; EndTime : integer);
      /// <summary> Creates an empty TMeshAsset.</summary>
      constructor Create();
      /// <summary> Free Instance and all child objects (e.g. Subsets, Animations)</summary>
      destructor Destroy; override;
  end;

implementation

{ TMeshAssetSubset }

constructor TMeshAssetSubset.Create;
begin

end;

destructor TMeshAssetSubset.Destroy;
begin
  HArray.FreeAllObjects<TMeshAssetMorphTarget>(FMorphTargets);
  inherited;
end;

function TMeshAssetSubset.GetBinormal(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Binormal;
end;

function TMeshAssetSubset.GetBoneInfluencingCount(index : integer) : integer;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].BoneCount;
end;

function TMeshAssetSubset.GetBonesIndices(index : integer) : ABoneIndices;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Bones;
end;

function TMeshAssetSubset.GetBoneWeight(index : integer) : ABoneWeights;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].BoneWeight;
end;

function TMeshAssetSubset.GetColor(index : integer) : RColor;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Color;
end;

function TMeshAssetSubset.GetHasSkin : boolean;
begin
  result := length(FSkinBoneLinks) > 0;
end;

function TMeshAssetSubset.GetMorphTarget(index : integer) : TMeshAssetMorphTarget;
begin
  assert((index >= 0) and (index < length(FMorphTargets)));
  result := FMorphTargets[index];
end;

function TMeshAssetSubset.GetMorphTargetCount : integer;
begin
  result := length(FMorphTargets);
end;

function TMeshAssetSubset.GetNormal(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FVertices)));
  if HasNormals then result := FVertices[index].Normal
  else raise EMeshAssetInvalidOperation.Create('TMeshAssetSubset: MeshAsset doesn''t contain normals.');
end;

function TMeshAssetSubset.GetSkinBoneLink(index : integer) : RSkinBoneLink;
begin
  assert((index >= 0) and (index < length(FSkinBoneLinks)));
  result := FSkinBoneLinks[index];
end;

function TMeshAssetSubset.GetSkinBoneLinkCount : integer;
begin
  result := length(FSkinBoneLinks);
end;

function TMeshAssetSubset.GetTangent(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Tangent;
end;

function TMeshAssetSubset.GetTextureCoordinate(index : integer) : RVector2;
begin
  assert((index >= 0) and (index < length(FVertices)));
  if HasTextureCoordinates then result := FVertices[index].TextureCoordinate
  else raise EMeshAssetInvalidOperation.Create('TMeshAssetSubset: MeshAsset doesn''t contain texturecoordinates.');
end;

function TMeshAssetSubset.GetVertex(index : integer) : RMeshAssetVertex;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index];
end;

function TMeshAssetSubset.GetVertexCount : integer;
begin
  result := length(FVertices);
end;

function TMeshAssetSubset.GetVertexPosition(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Position;
end;

procedure TMeshAssetSubset.SetBinormal(index : integer; const Value : RVector3);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].Binormal := Value;
end;

procedure TMeshAssetSubset.SetBoneIndices(index : integer; const Value : ABoneIndices);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].Bones := Value;
end;

procedure TMeshAssetSubset.SetBoneInfluencingCount(index : integer; const Value : integer);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].BoneCount := Value;
end;

procedure TMeshAssetSubset.SetBoneWeights(index : integer; const Value : ABoneWeights);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].BoneWeight := Value;
end;

procedure TMeshAssetSubset.SetColor(index : integer; const Value : RColor);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].Color := Value;
end;

procedure TMeshAssetSubset.SetMorphTarget(index : integer; const Value : TMeshAssetMorphTarget);
begin
  assert((index >= 0) and (index < length(FMorphTargets)));
  FMorphTargets[index] := Value;
end;

procedure TMeshAssetSubset.SetMorphTargetCount(const Value : integer);
begin
  setlength(FMorphTargets, Value);
end;

procedure TMeshAssetSubset.SetNormal(index : integer; const Value : RVector3);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].Normal := Value;
end;

procedure TMeshAssetSubset.SetSkinBoneLink(index : integer; const Value : RSkinBoneLink);
begin
  assert((index >= 0) and (index < length(FSkinBoneLinks)));
  FSkinBoneLinks[index] := Value;
end;

procedure TMeshAssetSubset.SetSkinBoneLinkCount(const Value : integer);
begin
  setlength(FSkinBoneLinks, Value);
end;

procedure TMeshAssetSubset.SetTangent(index : integer; const Value : RVector3);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].Tangent := Value;
end;

procedure TMeshAssetSubset.SetTextureCoordinate(index : integer; const Value : RVector2);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].TextureCoordinate := Value;
end;

procedure TMeshAssetSubset.SetVertex(index : integer; const Value : RMeshAssetVertex);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index] := Value;
end;

procedure TMeshAssetSubset.SetVertexCount(const Value : integer);
begin
  if length(FVertices) > 0 then
      raise EMeshAssetInvalidOperation.Create('TMeshAssetSubset: Vertices already contains data, change size is not supported.');
  setlength(FVertices, Value);
end;

procedure TMeshAssetSubset.SetVertexPosition(index : integer; const Value : RVector3);
begin
  assert((index >= 0) and (index < length(FVertices)));
  FVertices[index].Position := Value;
end;

{ TMeshAssetBone }

procedure TMeshAssetBone.ApplyBoneMatrixOnSubset;
var
  i : integer;
  SubsetMatrix : RMatrix;
begin
  if TargetSubsetCount > 0 then
  begin
    SubsetMatrix := ComputeCompleteMatrix;
    for i := 0 to TargetSubsetCount - 1 do
        TargetSubsets[i].MeshOffsetMatrix := ComputeCompleteMatrix;
  end;
  for i := 0 to ChildCount - 1 do
      Children[i].ApplyBoneMatrixOnSubset;
end;

function TMeshAssetBone.ComputeCompleteMatrix : RMatrix;
begin
  if IsRootNode then
      result := LocalTransform
  else
      result := Parent.ComputeCompleteMatrix * LocalTransform;
end;

constructor TMeshAssetBone.Create(Name : string);
begin
  inherited Create();
  FName := name;
end;

function TMeshAssetBone.GetTargetSubset(index : integer) : TMeshAssetSubset;
begin
  assert((index >= 0) and (index < length(FTargetSubsets)));
  result := FTargetSubsets[index];
end;

function TMeshAssetBone.GetTargetSubsetCount : integer;
begin
  result := length(FTargetSubsets);
end;

procedure TMeshAssetBone.SetTargetSubset(index : integer; const Value : TMeshAssetSubset);
begin
  assert((index >= 0) and (index < length(FTargetSubsets)));
  FTargetSubsets[index] := Value;
end;

procedure TMeshAssetBone.SetTargetSubsetCount(const Value : integer);
begin
  setlength(FTargetSubsets, Value);
end;

{ TMeshAssetAnimationKey<K> }

constructor TMeshAssetAnimationChannel<K>.Create;
begin

end;

constructor TMeshAssetAnimationChannel<K>.CreateFromStream(Stream : TStream);
var
  KeyFrameCountData : integer;
begin
  Stream.ReadData(KeyFrameCountData);
  KeyFrameCount := KeyFrameCountData;
  Stream.Read(FKeyFrames[0], KeyFrameCount * SizeOf(K));
end;

function TMeshAssetAnimationChannel<K>.GetKeyFrame(index : integer) : K;
begin
  assert((index >= 0) and (index < length(FKeyFrames)));
  result := FKeyFrames[index];
end;

function TMeshAssetAnimationChannel<K>.GetKeyFrameCount : integer;
begin
  result := length(FKeyFrames);
end;

procedure TMeshAssetAnimationChannel<K>.SaveToStream(Stream : TStream);
begin
  Stream.WriteData(KeyFrameCount);
  Stream.Write(FKeyFrames[0], KeyFrameCount * SizeOf(K));
end;

procedure TMeshAssetAnimationChannel<K>.SetKeyFrame(index : integer; const Value : K);
begin
  assert((index >= 0) and (index < length(FKeyFrames)));
  FKeyFrames[index] := Value;
end;

procedure TMeshAssetAnimationChannel<K>.SetKeyFrameCount(const Value : integer);
begin
  setlength(FKeyFrames, Value);
end;

{ TMeshAssetAnimation }

function TMeshAssetAnimation.AsBoneAnimation : TMeshAssetAnimationBone;
begin
  assert(AnimationType = atBoneAnimation);
  result := self as TMeshAssetAnimationBone;
end;

function TMeshAssetAnimation.AsMorphAnimation : TMeshAssetAnimationMorph;
begin
  assert(AnimationType = atMorphAnimation);
  result := self as TMeshAssetAnimationMorph;
end;

constructor TMeshAssetAnimation.Create(Name : ShortString);
begin
  FName := name;
end;

constructor TMeshAssetAnimation.CreateFromStream(Stream : TStream);
begin
  Stream.Read(FName, SizeOf(ShortString));
end;

destructor TMeshAssetAnimation.Destroy;
begin
  inherited;
end;

procedure TMeshAssetAnimation.SaveToStream(Stream : TStream);
begin
  Stream.Write(FName, SizeOf(ShortString));
end;

{ TMeshAsset }

procedure TMeshAsset.ClipAnimationsAgainstTimeSlot(StartTime, EndTime : integer);
var
  i : integer;
begin
  for i := 0 to AnimationCount - 1 do
      Animations[i].ClipAnimationsAgainstTimeSlot(StartTime, EndTime);
end;

procedure TMeshAsset.CollapseSubsets(DropDummySubsets : boolean);
const
  TEST_WEIGHTS : ABoneWeights = (1, 0, 0, 0);
  TEST_BONES : ABoneIndices   = (0, 0, 0, 0);
var
  CollapsedSubset : TMeshAssetSubset;
  MorphTarget : TMeshAssetMorphTarget;
  i, i2, i3 : integer;
  VertexCount : integer;
  currentVertexIndex : integer;
  vertex : RMeshAssetVertex;
  meshTransformIT, meshTransformI : RMatrix;
  SkinBoneLinkMap : TDictionary<integer, integer>;
  LinkIndex : integer;
  Link : RSkinBoneLink;
  SkinDataFound : boolean;
  /// <summary> Returns index of BoneLink, if bone link already exists in new subset, else -1.</summary>
  function SearchForBoneLink(const BoneLink : RSkinBoneLink) : integer;
  var
    i : integer;
  begin
    result := -1;
    for i := 0 to CollapsedSubset.SkinBoneLinkCount - 1 do
      if CollapsedSubset.SkinBoneLinks[i].TargetBone = BoneLink.TargetBone then
      begin
        Exit(i);
      end;
  end;

begin
  CollapsedSubset := nil;
  // no need for collapse, if there no more then one Subset
  if SubsetCount > 1 then
  begin
    CollapsedSubset := TMeshAssetSubset.Create;
    CollapsedSubset.MeshOffsetMatrix := RMatrix.IDENTITY;
    // first count overall vertices count
    VertexCount := 0;
    for i := 0 to SubsetCount - 1 do
      if (not DropDummySubsets or Subsets[i].HasTextureCoordinates) then
          VertexCount := VertexCount + Subsets[i].VertexCount;
    // set vertexcount
    CollapsedSubset.VertexCount := VertexCount;
    currentVertexIndex := 0;
    SkinBoneLinkMap := TDictionary<integer, integer>.Create();
    // if any subset has skindata, the complete collapsed model needs skindata, else the skinnig animation shader
    // would move any vertex with bonecount = 0 to ZERO
    SkinDataFound := False;
    for i := 0 to SubsetCount - 1 do
        SkinDataFound := SkinDataFound or Subsets[i].HasSkin;
    if SkinDataFound then
      // if there is any Subset without skindata, need a dummy skin entry that point to rootnode (Identity)
      for i := 0 to SubsetCount - 1 do
        if not Subsets[i].HasSkin then
        begin
          Link.BoneSpaceMatrix := RMatrix.IDENTITY;
          Link.TargetBone := 'RootNode';
          CollapsedSubset.SkinBoneLinkCount := CollapsedSubset.SkinBoneLinkCount + 1;
          CollapsedSubset.SkinBoneLinks[CollapsedSubset.SkinBoneLinkCount - 1] := Link;
          Break;
        end;

    for i := 0 to SubsetCount - 1 do
      // drop Subset if DropDummySubsets is true and Subset has not texture coordinates
      if (not DropDummySubsets or Subsets[i].HasTextureCoordinates) then
      begin
        CollapsedSubset.HasColor := CollapsedSubset.HasColor or Subsets[i].HasColor;
        CollapsedSubset.HasNormals := CollapsedSubset.HasNormals or Subsets[i].HasNormals;
        CollapsedSubset.HasTangents := CollapsedSubset.HasTangents or Subsets[i].HasTangents;
        CollapsedSubset.HasBinormals := CollapsedSubset.HasBinormals or Subsets[i].HasBinormals;
        CollapsedSubset.HasTextureCoordinates := CollapsedSubset.HasTextureCoordinates or Subsets[i].HasTextureCoordinates;
        meshTransformIT := Subsets[i].MeshOffsetMatrix.Get3x3.Inverse.Transpose;
        meshTransformI := Subsets[i].MeshOffsetMatrix.Inverse;
        if Subsets[i].HasSkin then
        begin
          SkinBoneLinkMap.Clear;
          for i2 := 0 to Subsets[i].SkinBoneLinkCount - 1 do
          begin
            Link := Subsets[i].SkinBoneLinks[i2];
            Link.BoneSpaceMatrix := Link.BoneSpaceMatrix * meshTransformI;
            LinkIndex := SearchForBoneLink(Link);
            // if link not already exists, add them
            if LinkIndex = -1 then
            begin
              LinkIndex := CollapsedSubset.SkinBoneLinkCount;
              CollapsedSubset.SkinBoneLinkCount := CollapsedSubset.SkinBoneLinkCount + 1;
              CollapsedSubset.SkinBoneLinks[LinkIndex] := Link;
            end;
            // add link to map, because vertices link index has to be adjusted
            SkinBoneLinkMap.Add(i2, LinkIndex);
          end;
        end;
        for i2 := 0 to Subsets[i].VertexCount - 1 do
        begin
          assert(currentVertexIndex < VertexCount);
          // assign all data of vertex
          vertex := Subsets[i].Vertices[i2];
          // modify position and normal, by apply MeshOffsetMatrix
          vertex.Position := Subsets[i].MeshOffsetMatrix * vertex.Position;
          if Subsets[i].HasNormals then
              vertex.Normal := (meshTransformIT * vertex.Normal).Normalize;
          // if this Subset has a skin, map BoneLinkIndices to new index
          if Subsets[i].HasSkin then
          begin
            for i3 := 0 to MAXINFLUENCINGBONES - 1 do
                vertex.Bones[i3] := SkinBoneLinkMap[vertex.Bones[i3]];
          end
          // else if any subset (before or after this subset) has skindata, emulate skindata by point to Root_Bone (Identity matrix)
          else if SkinDataFound then
          begin
            // root bone always one index 0
            vertex.Bones[0] := 0;
            vertex.BoneWeight[0] := 1;
            vertex.BoneCount := 1;
          end;
          CollapsedSubset.Vertices[currentVertexIndex] := vertex;
          inc(currentVertexIndex);
        end;
        for i2 := 0 to Subsets[i].MorphTargetCount - 1 do
        begin
          MorphTarget := TMeshAssetMorphTarget.Create;
          MorphTarget.Name := Subsets[i].MorphTargets[i2].Name;
          CollapsedSubset.MorphTargetCount := CollapsedSubset.MorphTargetCount + 1;
          CollapsedSubset.MorphTargets[CollapsedSubset.MorphTargetCount - 1] := MorphTarget;
          MorphTarget.DifferencePositionCount := VertexCount;
          assert(currentVertexIndex - Subsets[i].VertexCount + Subsets[i].MorphTargets[i2].DifferencePositionCount <= VertexCount);
          for i3 := 0 to Subsets[i].MorphTargets[i2].DifferencePositionCount - 1 do
          begin
            MorphTarget.DifferencePosition[currentVertexIndex - Subsets[i].VertexCount + i3] := Subsets[i].MeshOffsetMatrix.Get3x3 * Subsets[i].MorphTargets[i2].DifferencePosition[i3];
          end;
        end;
      end;
    SkinBoneLinkMap.Free;
    for i := SubsetCount - 1 downto 0 do
        Subsets[i].Free;
    // if new CollapsedSubset does not contain any vertex data, drop the complete CollapsedSubset
    // this can occur, if e.g. the MeshAsset only contains dummy subsets (=subsets without any texture coordinates)
    if CollapsedSubset.VertexCount > 0 then
    begin
      setlength(FSubsets, 1);
      FSubsets[0] := CollapsedSubset;
    end
    else
    begin
      CollapsedSubset.Free;
      FSubsets := nil;
    end;
  end;

end;

constructor TMeshAsset.Create;
begin
  FSkeleton := TTree<TMeshAssetBone>.Create();
end;

destructor TMeshAsset.Destroy;
begin
  FSkeleton.Free;
  HArray.FreeAllObjects<TMeshAssetAnimation>(FAnimations, true);
  HArray.FreeAllObjects<TMeshAssetSubset>(FSubsets, true);
  inherited;
end;

function TMeshAsset.GetAnimation(index : integer) : TMeshAssetAnimation;
begin
  assert((index >= 0) and (index < length(FAnimations)));
  result := FAnimations[index];
end;

function TMeshAsset.GetAnimationCount : integer;
begin
  result := length(FAnimations);
end;

function TMeshAsset.GetHasAnimation : boolean;
begin
  result := length(FAnimations) > 0;
end;

function TMeshAsset.GetSubset(index : integer) : TMeshAssetSubset;
begin
  assert((index >= 0) and (index < length(FSubsets)));
  result := FSubsets[index];
end;

function TMeshAsset.GetSubsetByName(SubsetName : string) : TMeshAssetSubset;
begin
  result := Subsets[GetSubsetIndexByName(SubsetName)];
end;

function TMeshAsset.GetSubsetCount : integer;
begin
  result := length(FSubsets);
end;

function TMeshAsset.GetSubsetIndexByName(SubsetName : string) : integer;
var
  i : integer;
  found : boolean;
begin
  result := -1;
  found := False;
  for i := 0 to SubsetCount - 1 do
    if Subsets[i].SubsetName = SubsetName then
    begin
      result := i;
      found := true;
      Break;
    end;
  if not found then
      raise ENotFoundException.CreateFmt('TMeshAsset.GetSubsetIndexByName: Could not found any Subset with SubsetName "%s"', [SubsetName]);
end;

procedure TMeshAsset.SetAnimation(index : integer; const Value : TMeshAssetAnimation);
begin
  assert((index >= 0) and (index < length(FAnimations)));
  FAnimations[index] := Value;
end;

procedure TMeshAsset.SetAnimationCount(const Value : integer);
begin
  setlength(FAnimations, Value);
end;

procedure TMeshAsset.SetSubset(index : integer; const Value : TMeshAssetSubset);
begin
  assert((index >= 0) and (index < length(FSubsets)));
  FSubsets[index] := Value;
end;

procedure TMeshAsset.SetSubsetByName(SubsetName : string; const Value : TMeshAssetSubset);
begin
  Subsets[GetSubsetIndexByName(SubsetName)] := Value;
end;

procedure TMeshAsset.SetSubsetCount(const Value : integer);
begin
  setlength(FSubsets, Value);
end;

{ RSkinBoneLink }

constructor RSkinBoneLink.Create(const BoneSpaceMatrix : RMatrix; const TargetBone : string);
begin
  self.BoneSpaceMatrix := BoneSpaceMatrix;
  self.TargetBone := TargetBone;
end;

{ TMeshAssetAnimation<K> }

destructor TMeshAssetAnimation<K>.Destroy;
begin
  HArray.FreeAllObjects<K>(FAnimationChannels);
  inherited;
end;

function TMeshAssetAnimation<K>.GetAnimationChannel(index : integer) : K;
begin
  result := FAnimationChannels[index];
end;

function TMeshAssetAnimation<K>.GetAnimationChannelCount : integer;
begin
  result := length(FAnimationChannels);
end;

procedure TMeshAssetAnimation<K>.SetAnimationChannel(index : integer; const Value : K);
begin
  assert((index >= 0) and (index < length(FAnimationChannels)));
  FAnimationChannels[index] := Value;
end;

procedure TMeshAssetAnimation<K>.SetAnimationChannelCount(const Value : integer);
begin
  setlength(FAnimationChannels, Value);
end;

{ TMeshAssetAnimationBone }

procedure TMeshAssetAnimationBone.ClipAnimationsAgainstTimeSlot(StartTime, EndTime : integer);
var
  animChannel : TMeshAssetAnimationChannelBone;
begin
  for animChannel in FAnimationChannels do
  begin
    animChannel.ClipAnimationsAgainstTimeSlot(StartTime, EndTime);
  end;
end;

constructor TMeshAssetAnimationBone.Create(Name : ShortString);
begin
  FAnimationType := atBoneAnimation;
  inherited Create(name);
end;

constructor TMeshAssetAnimationBone.CreateFromStream(Stream : TStream);
var
  AnimationChannelCountData, i : integer;
begin
  FAnimationType := atBoneAnimation;
  inherited CreateFromStream(Stream);
  Stream.ReadData(AnimationChannelCountData);
  AnimationChannelCount := AnimationChannelCountData;
  for i := 0 to AnimationChannelCount - 1 do
      AnimationChannels[i] := TMeshAssetAnimationChannelBone.CreateFromStream(Stream);
end;

procedure TMeshAssetAnimationBone.SaveToStream(Stream : TStream);
var
  i : integer;
begin
  inherited;
  Stream.WriteData(AnimationChannelCount);
  for i := 0 to AnimationChannelCount - 1 do
      AnimationChannels[i].SaveToStream(Stream);
end;

{ TMeshAssetAnimationMorph }

procedure TMeshAssetAnimationMorph.ClipAnimationsAgainstTimeSlot(StartTime,
  EndTime : integer);
var
  animChannel : TMeshAssetAnimationChannelMorph;
begin
  for animChannel in FAnimationChannels do
  begin
    animChannel.ClipAnimationsAgainstTimeSlot(StartTime, EndTime);
  end;
end;

constructor TMeshAssetAnimationMorph.Create(Name : ShortString);
begin
  FAnimationType := atMorphAnimation;
  inherited Create(name);
end;

constructor TMeshAssetAnimationMorph.CreateFromStream(Stream : TStream);
var
  AnimationChannelCountData, i : integer;
begin
  FAnimationType := atMorphAnimation;
  inherited CreateFromStream(Stream);
  Stream.ReadData(AnimationChannelCountData);
  AnimationChannelCount := AnimationChannelCountData;
  for i := 0 to AnimationChannelCount - 1 do
      AnimationChannels[i] := TMeshAssetAnimationChannelMorph.CreateFromStream(Stream);
end;

procedure TMeshAssetAnimationMorph.SaveToStream(Stream : TStream);
var
  i : integer;
begin
  inherited;
  Stream.WriteData(AnimationChannelCount);
  for i := 0 to AnimationChannelCount - 1 do
      AnimationChannels[i].SaveToStream(Stream);
end;

{ TMeshAssetMorphTarget }

function TMeshAssetMorphTarget.GetDifferencePositionCount : integer;
begin
  result := length(FDiffPositions);
end;

function TMeshAssetMorphTarget.GetDiffPosition(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FDiffPositions)));
  result := FDiffPositions[index];
end;

procedure TMeshAssetMorphTarget.SetDifferencePositionCount(const Value : integer);
begin
  setlength(FDiffPositions, Value);
end;

procedure TMeshAssetMorphTarget.SetDiffPosition(index : integer; const Value : RVector3);
begin
  assert((index >= 0) and (index < length(FDiffPositions)));
  FDiffPositions[index] := Value;
end;

{ TMeshAssetAnimationChannelBone }

procedure TMeshAssetAnimationChannelBone.ClipAnimationsAgainstTimeSlot(StartTime, EndTime : integer);
var
  i : integer;
  newKeyFrames : TArray<RKeyFrameBone>;
  newKeyFrameCount : integer;
begin
  setlength(newKeyFrames, KeyFrameCount);
  newKeyFrameCount := 0;
  for i := 0 to KeyFrameCount - 1 do
    if inRange(KeyFrames[i].Time, StartTime, EndTime) then
    begin
      newKeyFrames[newKeyFrameCount] := KeyFrames[i];
      newKeyFrames[newKeyFrameCount].Time := newKeyFrames[newKeyFrameCount].Time - StartTime;
      inc(newKeyFrameCount);
    end;
  setlength(newKeyFrames, newKeyFrameCount);
  FKeyFrames := newKeyFrames;
end;

constructor TMeshAssetAnimationChannelBone.CreateFromStream(Stream : TStream);
begin
  inherited;
  Stream.Read(FTargetBone, SizeOf(ShortString));
end;

procedure TMeshAssetAnimationChannelBone.SaveToStream(Stream : TStream);
begin
  inherited;
  Stream.Write(TargetBone, SizeOf(ShortString));
end;

{ TMeshAssetAnimationChannelMorph }

procedure TMeshAssetAnimationChannelMorph.ClipAnimationsAgainstTimeSlot(StartTime, EndTime : integer);
var
  i : integer;
  newKeyFrames : TArray<RKeyFrameMorph>;
  newKeyFrameCount : integer;
  startFound, endFound : boolean;
begin
  startFound := False;
  endFound := False;
  setlength(newKeyFrames, KeyFrameCount + 2); // maybe an additional start and endframe
  newKeyFrameCount := 0;
  for i := 0 to KeyFrameCount - 1 do
    if inRange(KeyFrames[i].Time, StartTime, EndTime) then
    begin
      startFound := startFound or (KeyFrames[i].Time = StartTime);
      endFound := endFound or (KeyFrames[i].Time = EndTime);
      newKeyFrames[newKeyFrameCount] := KeyFrames[i];
      newKeyFrames[newKeyFrameCount].Time := newKeyFrames[newKeyFrameCount].Time - StartTime;
      inc(newKeyFrameCount);
    end;

  // not startkey found, create one
  if not startFound then
  begin
    HArray.Insert<RKeyFrameMorph>(newKeyFrames, HArray.InterpolateLinear<RKeyFrameMorph>(FKeyFrames, StartTime,
      function(const Key : RKeyFrameMorph) : Single
      begin
        result := Key.Time;
      end,
      function(itemA, itemB : RKeyFrameMorph; s : Single) : RKeyFrameMorph
      begin
        result := itemA.Lerp(itemB, s);
      end), 0);
    newKeyFrames[0].Time := 0;
    inc(newKeyFrameCount);
  end;

  // not endkey found, create one
  if not endFound then
  begin
    newKeyFrames[newKeyFrameCount] := HArray.InterpolateLinear<RKeyFrameMorph>(FKeyFrames, EndTime,
      function(const Key : RKeyFrameMorph) : Single
      begin
        result := Key.Time;
      end,
      function(itemA, itemB : RKeyFrameMorph; s : Single) : RKeyFrameMorph
      begin
        result := itemA.Lerp(itemB, s);
      end);
    newKeyFrames[newKeyFrameCount].Time := EndTime - StartTime;
    inc(newKeyFrameCount);
  end;
  setlength(newKeyFrames, newKeyFrameCount);
  FKeyFrames := newKeyFrames;
end;

constructor TMeshAssetAnimationChannelMorph.CreateFromStream(Stream : TStream);
begin
  inherited CreateFromStream(Stream);
  Stream.Read(FMorphTarget, SizeOf(ShortString));
end;

procedure TMeshAssetAnimationChannelMorph.SaveToStream(Stream : TStream);
begin
  inherited;
  Stream.Write(MorphTarget, SizeOf(ShortString));
end;

{ RKeyFrameMorph }

function RKeyFrameMorph.Lerp(OtherKey : RKeyFrameMorph; Factor : Single) : RKeyFrameMorph;
begin
  result.Time := round(self.Time * (1 - Factor) + OtherKey.Time * Factor);
  result.Weight := self.Weight * (1 - Factor) + OtherKey.Weight * Factor;
end;

end.

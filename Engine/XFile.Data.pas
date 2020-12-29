unit XFile.Data;

interface

uses
  XFile.Loader,
  FBXFileLoader,
  Generics.Collections,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.DataStructures,
  SysUtils,
  Windows;

type
  EXFileDataNotAvailable = class(Exception);
  EXFileUnsupportedData = class(Exception);

  RSkinBoneLink = record
    BoneSpaceMatrix : RMatrix;
    TargetBone : string;
  end;

  D3DDECLUSAGE = (
    D3DDECLUSAGE_POSITION = 0,
    D3DDECLUSAGE_BLENDWEIGHT = 1,
    D3DDECLUSAGE_BLENDINDICES = 2,
    D3DDECLUSAGE_NORMAL = 3,
    D3DDECLUSAGE_PSIZE = 4,
    D3DDECLUSAGE_TEXCOORD = 5,
    D3DDECLUSAGE_TANGENT = 6,
    D3DDECLUSAGE_BINORMAL = 7,
    D3DDECLUSAGE_TESSFACTOR = 8,
    D3DDECLUSAGE_POSITIONT = 9,
    D3DDECLUSAGE_COLOR = 10,
    D3DDECLUSAGE_FOG = 11,
    D3DDECLUSAGE_DEPTH = 12,
    D3DDECLUSAGE_SAMPLE = 13);

  D3DDECLTYPE = (
    D3DDECLTYPE_FLOAT1 = 0,
    D3DDECLTYPE_FLOAT2 = 1,
    D3DDECLTYPE_FLOAT3 = 2,
    D3DDECLTYPE_FLOAT4 = 3,
    D3DDECLTYPE_D3DCOLOR = 4,
    D3DDECLTYPE_UBYTE4 = 5,
    D3DDECLTYPE_SHORT2 = 6,
    D3DDECLTYPE_SHORT4 = 7,
    D3DDECLTYPE_UBYTE4N = 8,
    D3DDECLTYPE_SHORT2N = 9,
    D3DDECLTYPE_SHORT4N = 10,
    D3DDECLTYPE_USHORT2N = 11,
    D3DDECLTYPE_USHORT4N = 12,
    D3DDECLTYPE_UDEC3 = 13,
    D3DDECLTYPE_DEC3N = 14,
    D3DDECLTYPE_FLOAT16_2 = 15,
    D3DDECLTYPE_FLOAT16_4 = 16,
    D3DDECLTYPE_UNUSED = 17);

  RDeclElement = record
    DeclType : D3DDECLTYPE;
    Usage : D3DDECLUSAGE;
    UsageIndex : DWord;
    function GetSize : DWord;
  end;

const
  MAXINFLUENCINGBONES = 4;
  MINBONEWEIGHT       = 0.001;

  KEYTYPEROTATION   = 1;
  KEYTYPESCALE      = 2;
  KEYTYPEPOSITION   = 3;
  KEYTYPEMATRIXKEYS = 4;

type
  ABoneIndices = array [0 .. MAXINFLUENCINGBONES - 1] of integer;
  ABoneWeights = array [0 .. MAXINFLUENCINGBONES - 1] of Single;

  TXFileSubset = class
    private type
      RXFileVertex = record
        Position : RVector3;
        Normal : RVector3;
        Tangent : RVector3;
        Binormal : RVector3;
        TextureCoordinate : RVector2;
        // index to bonelink
        Bones : ABoneIndices;
        // weight for bonelink
        BoneWeight : ABoneWeights;
        BoneCount : integer;
      end;
    private
      FHasNormals : boolean;
      FHasTangents : boolean;
      FHasBinormals : boolean;
      FHasTextureCoordinates : boolean;
      FMeshOffsetMatrix : RMatrix;
      FVertices : TArray<RXFileVertex>;
      FSkinBoneLinks : TArray<RSkinBoneLink>;
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
    public
      property MeshOffsetMatrix : RMatrix read FMeshOffsetMatrix;
      property VertexPositions[index : integer] : RVector3 read GetVertexPosition;
      property HasNormals : boolean read FHasNormals;
      property HasTangents : boolean read FHasTangents;
      property HasBinormals : boolean read FHasBinormals;
      property Normals[index : integer] : RVector3 read GetNormal;
      property Tangents[index : integer] : RVector3 read GetTangent;
      property Binormals[index : integer] : RVector3 read GetBinormal;
      property HasTextureCoordinates : boolean read FHasTextureCoordinates;
      property TextureCoordinate[index : integer] : RVector2 read GetTextureCoordinate;
      property VertexCount : integer read GetVertexCount;
      property HasSkin : boolean read GetHasSkin;
      property BoneIndices[index : integer] : ABoneIndices read GetBonesIndices;
      property BoneWeights[index : integer] : ABoneWeights read GetBoneWeight;
      property BoneInfluencingCount[index : integer] : integer read GetBoneInfluencingCount;
      property SkinBoneLinks[index : integer] : RSkinBoneLink read GetSkinBoneLink;
      property SkinBoneLinkCount : integer read GetSkinBoneLinkCount;
      constructor Create(SourceData : TDataNode);
      destructor Destroy; override;
  end;

  TXFileBone = class(TTreeNode<TXFileBone>)
    private
      FName : string;
      FUnknownMatrix : RMatrix;
    public
      property name : string read FName;
      /// <summary> Matrix saved for every bone, dont know the sense of this matrix.
      /// msdn says: "Defines a local transform for a frame [in that case frame = bone] (and all its child objects). ",
      /// but it is not the BoneSpaceMatrix!</summary>
      property UnknownMatrix : RMatrix read FUnknownMatrix;
      constructor Create(Name : string; SourceData : TDataNode);
  end;

  TAnimationKey = class
    private type
      RKeyFrame = record
        public
          Time : Cardinal;
          AnimationMatrix : RMatrix;
      end;
    private
      FTargetBone : string;
      FKeyFrames : TArray<RKeyFrame>;
      function GetKeyFrame(index : integer) : RKeyFrame;
      function GetKeyFrameCount : integer;
    public
      property TargetBone : string read FTargetBone;
      property KeyFrames[index : integer] : RKeyFrame read GetKeyFrame;
      property KeyFrameCount : integer read GetKeyFrameCount;
      constructor Create(TargetBone : string; SourceData : TDataNode);
  end;

  TAnimation = class
    private
      FName : string;
      FAnimationKeys : TObjectList<TAnimationKey>;
      function GetAnimationKey(index : integer) : TAnimationKey;
      function GetAnimationKeyCount : integer;
    public
      property name : string read FName;
      property AnimationKeys[index : integer] : TAnimationKey read GetAnimationKey;
      property AnimationKeyCount : integer read GetAnimationKeyCount;
      constructor Create(Name : string; SourceData : TDataNode);
      destructor Destroy; override;
  end;

  TXFileData = class
    private
      FSubsets : TObjectList<TXFileSubset>;
      FSkeleton : TTree<TXFileBone>;
      FAnimations : TObjectList<TAnimation>;
      function GetSubset(index : integer) : TXFileSubset;
      function GetSubsetCount : integer;
      function GetAnimation(index : integer) : TAnimation;
      function GetAnimationCount : integer;
      function GetHasAnimation : boolean;
    public
      property Skeleton : TTree<TXFileBone> read FSkeleton;
      property Subsets[index : integer] : TXFileSubset read GetSubset;
      property SubsetCount : integer read GetSubsetCount;
      property HasAnimation : boolean read GetHasAnimation;
      property Animations[index : integer] : TAnimation read GetAnimation;
      property AnimationCount : integer read GetAnimationCount;
      constructor Create(FileLoader : TXFileLoader); overload;
      constructor Create(FileLoad : TFBXFileLoader); overload;
      destructor Destroy; override;
  end;

implementation

{ TXFileData }

constructor TXFileData.Create(FileLoader : TXFileLoader);
  procedure SearchForMeshRecursive(node : TObjectDictionary<string, TDataNode>);
  var
    Name : string;
  begin
    if node = nil then exit;
    for name in node.Keys do
    begin
      if node[name] = nil then continue;

      if (node[name].Members <> nil) and node[name].Members.ContainsKey('Mesh') then
      begin
        FSubsets.Add(TXFileSubset.Create(node[name]));
        exit;
      end
      else if (name = 'Mesh') and (node[name].DataType.Name = 'Mesh') then
      begin
        FSubsets.Add(TXFileSubset.Create(node[name]));
        exit;
      end;
      SearchForMeshRecursive(node[name].Members);
    end;
  end;

var
  Name : string;
begin
  FSubsets := TObjectList<TXFileSubset>.Create();
  FSkeleton := TTree<TXFileBone>.Create(True);
  FAnimations := TObjectList<TAnimation>.Create(True);
  // create dummy rootbone
  FSkeleton.AddRootNode(TXFileBone.Create('RootDummyNode 3124111', nil));
  // collect all bones
  for name in FileLoader.Data.Members.Keys do
    if not FileLoader.Data[name].Members.ContainsKey('Mesh') and (FileLoader.Data[name].DataType.Name = 'Frame') then
    begin
      FSkeleton.RootNode.AddChild(TXFileBone.Create(name, FileLoader.Data[name]));
    end;
  // collect meshdata
  SearchForMeshRecursive(FileLoader.Data.Members);
  // collect all animation data
  for name in FileLoader.Data.Members.Keys do
    if FileLoader.Data.Members[name].DataType.Name = 'AnimationSet' then
    begin
      FAnimations.Add(TAnimation.Create(name, FileLoader.Data.Members[name]));
    end;
end;

constructor TXFileData.Create(FileLoad : TFBXFileLoader);
begin

end;

destructor TXFileData.Destroy;
begin
  FSkeleton.Free;
  FAnimations.Free;
  FSubsets.Free;
  inherited;
end;

function TXFileData.GetAnimation(index : integer) : TAnimation;
begin
  assert((index >= 0) and (index < FAnimations.Count));
  result := FAnimations[index];
end;

function TXFileData.GetAnimationCount : integer;
begin
  result := FAnimations.Count;
end;

function TXFileData.GetHasAnimation : boolean;
begin
  result := FAnimations.Count > 0;
end;

function TXFileData.GetSubset(index : integer) : TXFileSubset;
begin
  assert((index >= 0) and (index < FSubsets.Count));
  result := FSubsets[index];
end;

function TXFileData.GetSubsetCount : integer;
begin
  result := FSubsets.Count;
end;

{ TXFileSubset }

constructor TXFileSubset.Create(SourceData : TDataNode);
  function GetFrameTransformMatrixRecursive(SourceData : TDataNode) : RMatrix;
  begin
    if SourceData = nil then exit(RMatrix.IDENTITY);
    if SourceData.Members.ContainsKey('FrameTransformMatrix') then
        result := SourceData['FrameTransformMatrix']['frameMatrix']['matrix'].AsMatrix * GetFrameTransformMatrixRecursive(SourceData.Parent)
    else result := GetFrameTransformMatrixRecursive(SourceData.Parent);
  end;

  function GetDeclDataBlockSize(DeclElements : TArray<RDeclElement>) : DWord;
  var
    i : integer;
  begin
    result := 0;
    for i := 0 to length(DeclElements) - 1 do
        result := result + DeclElements[i].GetSize;
  end;

var
  nVertices : DWord;
  localVertices : TArray<RXFileVertex>;
  tmpArrayVec2 : ARVector2;
  tmpArrayVec3 : ARVector3;
  nDeclElements : DWord;
  DeclElements : TArray<RDeclElement>;
  nDeclData : DWord;
  DeclDataBlockSize : DWord;
  DeclData : ADWord;
  nTangents, nNormals, nBinormals, nTexCoords : DWord;
  faceVertexIndices : ADWord;
  Face : ADWord;
  nFaces : DWord;
  i, i2 : integer;
  nBones, nWeights : integer;
  Name : AnsiString;
  BoneVertexIndices : ADWord;
  BoneWeights : ASingle;

begin
  if SourceData.DataType.Name <> 'Mesh' then
  begin
    FMeshOffsetMatrix := GetFrameTransformMatrixRecursive(SourceData['Mesh']).Transpose;
    SourceData := SourceData['Mesh'];
    assert(SourceData.DataType.Name = 'Mesh');
  end
  else
  begin
    FMeshOffsetMatrix := RMatrix.IDENTITY;
  end;
  // load vertex data (<> Meshvertexdata, because Vertices could be indexed)
  nVertices := SourceData['nVertices'].AsDWord;
  setlength(localVertices, nVertices);
  tmpArrayVec3 := SourceData['vertices'].AsARVector3;
  for i := 0 to nVertices - 1 do
      localVertices[i].Position := tmpArrayVec3[i];
  // load texturecoord data
  // not every mesh contains texturecoordinates, test it before load
  FHasTextureCoordinates := False;
  if SourceData.Members.ContainsKey('MeshTextureCoords') then
  begin
    nTexCoords := SourceData['MeshTextureCoords']['nTextureCoords'].AsDWord;
    assert(nVertices = nTexCoords);
    tmpArrayVec2 := SourceData['MeshTextureCoords']['textureCoords'].AsARVector2;
    assert(integer(nTexCoords) = length(tmpArrayVec2));
    for i := 0 to nVertices - 1 do
        localVertices[i].TextureCoordinate := tmpArrayVec2[i];
    FHasTextureCoordinates := True;
  end;
  // load normal data
  // not every mesh contains normals, test it before load
  FHasNormals := False;
  if SourceData.Members.ContainsKey('MeshNormals') then
  begin
    nNormals := SourceData['MeshNormals']['nNormals'].AsDWord;
    tmpArrayVec3 := SourceData['MeshNormals']['normals'].AsARVector3;
    assert(integer(nNormals) = length(tmpArrayVec3));
    for i := 0 to nVertices - 1 do
        localVertices[i].Normal := tmpArrayVec3[i];
    FHasNormals := True;
  end;

  // load DeclData (special binarydata) can contain normals, tangents, texcoords,...
  if SourceData.Members.ContainsKey('DeclData') then
  begin
    assert(FHasNormals = False);
    // get datatypes is present in DeclData
    nDeclElements := SourceData['DeclData']['nElements'].AsDWord;
    setlength(DeclElements, nDeclElements);
    for i := 0 to nDeclElements - 1 do
    begin
      // get type
      DeclElements[i].Usage := D3DDECLUSAGE(TDataNodeArray(SourceData['DeclData']['Elements']).Values[i]['Usage'].AsDWord);
      DeclElements[i].UsageIndex := TDataNodeArray(SourceData['DeclData']['Elements']).Values[i]['UsageIndex'].AsDWord;
      DeclElements[i].DeclType := D3DDECLTYPE(TDataNodeArray(SourceData['DeclData']['Elements']).Values[i]['Type'].AsDWord);
      case DeclElements[i].Usage of
        D3DDECLUSAGE_NORMAL : FHasNormals := True;
        D3DDECLUSAGE_TANGENT : FHasTangents := True;
        D3DDECLUSAGE_BINORMAL : FHasBinormals := True;
        D3DDECLUSAGE_TEXCOORD : FHasTextureCoordinates := True;
      else raise EXFileUnsupportedData.Create('TXFileSubset.Create: Declelementusage not supported!');
      end;
    end;
    nDeclData := SourceData['DeclData']['nDWords'].AsDWord;
    DeclData := SourceData['DeclData']['data'].AsADWord;
    // every declaredata is organized as block
    DeclDataBlockSize := GetDeclDataBlockSize(DeclElements);
    assert(nDeclData mod DeclDataBlockSize = 0);
    // datacounter
    i := 0;
    // elementcounter
    i2 := 0;
    while i < nDeclData do
    begin
      // skip all usageindex > 0, because this means doubledata (e.g. texcoord 0 and 1) and is not supported
      if DeclElements[i2].UsageIndex = 0 then
        case DeclElements[i2].Usage of
          D3DDECLUSAGE_NORMAL : move(DeclData[i], localVertices[i div DeclDataBlockSize].Normal, DeclElements[i2].GetSize * SizeOf(DWord));
          D3DDECLUSAGE_TANGENT : move(DeclData[i], localVertices[i div DeclDataBlockSize].Tangent, DeclElements[i2].GetSize * SizeOf(DWord));
          D3DDECLUSAGE_BINORMAL : move(DeclData[i], localVertices[i div DeclDataBlockSize].Binormal, DeclElements[i2].GetSize * SizeOf(DWord));
          D3DDECLUSAGE_TEXCOORD : move(DeclData[i], localVertices[i div DeclDataBlockSize].TextureCoordinate, DeclElements[i2].GetSize * SizeOf(DWord));
        end;
      // nextdata
      i := i + DeclElements[i2].GetSize;
      i2 := (i2 + 1) mod nDeclElements;
    end;
  end;

  nBones := 0;
  if SourceData.Members.ContainsKey('XSkinMeshHeader') then
  begin
    nBones := SourceData['XSkinMeshHeader']['nBones'].AsDWord;
  end;
  // Xfile skin save for every bone a skin-bone-link
  setlength(FSkinBoneLinks, nBones);
  // add skin information (bones are read not per subset, but per mesh -> only read skindata, no bonedata expected)
  for i := 0 to nBones - 1 do
  begin
    name := 'SkinWeights' + HGeneric.TertOp<AnsiString>(i >= 1, IntToStr(i), '');
    assert(SourceData.Members.ContainsKey(name));
    FSkinBoneLinks[i].TargetBone := SourceData[name]['transformNodeName'].AsString;
    FSkinBoneLinks[i].BoneSpaceMatrix := SourceData[name]['matrixOffset']['matrix'].AsMatrix;
    nWeights := SourceData[name]['nWeights'].AsDWord;
    BoneWeights := SourceData[name]['weights'].AsAFloat;
    BoneVertexIndices := SourceData[name]['vertexIndices'].AsADWord;
    assert(length(BoneWeights) = length(BoneVertexIndices));
    // apply skindata to vertices
    for i2 := 0 to nWeights - 1 do
    begin
      // skip weights < MINBONEWEIGHT because they won't make difference
      if BoneWeights[i2] >= MINBONEWEIGHT then
      begin
        assert(localVertices[BoneVertexIndices[i2]].BoneCount < MAXINFLUENCINGBONES);
        // set index to current skin-bone-link
        localVertices[BoneVertexIndices[i2]].Bones[localVertices[BoneVertexIndices[i2]].BoneCount] := i;
        localVertices[BoneVertexIndices[i2]].BoneWeight[localVertices[BoneVertexIndices[i2]].BoneCount] := BoneWeights[i2];
        // new bone has set, inc counter
        inc(localVertices[BoneVertexIndices[i2]].BoneCount);
      end;
    end;
  end;

  // load index data
  nFaces := SourceData['nFaces'].AsDWord;
  // every face consist of 3 vertices, need 3 indices per face
  setlength(FVertices, nFaces * 3);

  // resolve index dependencies
  for i := 0 to nFaces - 1 do
  begin
    assert(TDataNodeArray(SourceData['faces']).Values[i]['nFaceVertexIndices'].AsDWord = 3);
    Face := TDataNodeArray(SourceData['faces']).Values[i]['faceVertexIndices'].AsADWord;
    for i2 := 0 to 2 do
    begin
      FVertices[i * 3 + i2] := localVertices[Face[i2]];
    end;
  end;
end;

destructor TXFileSubset.Destroy;
begin
  FVertices := nil;
  inherited;
end;

function TXFileSubset.GetBinormal(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Binormal;
end;

function TXFileSubset.GetBoneInfluencingCount(index : integer) : integer;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].BoneCount;
end;

function TXFileSubset.GetBonesIndices(index : integer) : ABoneIndices;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Bones;
end;

function TXFileSubset.GetBoneWeight(index : integer) : ABoneWeights;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].BoneWeight;
end;

function TXFileSubset.GetHasSkin : boolean;
begin
  result := length(FSkinBoneLinks) > 0;
end;

function TXFileSubset.GetNormal(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FVertices)));
  if HasNormals then result := FVertices[index].Normal
  else raise EXFileDataNotAvailable.Create('TXFileSubset.GetNormal: XFile doesn''t contain normals.');
end;

function TXFileSubset.GetSkinBoneLink(index : integer) : RSkinBoneLink;
begin
  assert((index >= 0) and (index < length(FSkinBoneLinks)));
  result := FSkinBoneLinks[index];
end;

function TXFileSubset.GetSkinBoneLinkCount : integer;
begin
  result := length(FSkinBoneLinks);
end;

function TXFileSubset.GetTangent(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Tangent;
end;

function TXFileSubset.GetTextureCoordinate(index : integer) : RVector2;
begin
  assert((index >= 0) and (index < length(FVertices)));
  if HasTextureCoordinates then result := FVertices[index].TextureCoordinate
  else raise EXFileDataNotAvailable.Create('TXFileSubset.GetNormal: XFile doesn''t contain texturecoordinates.');
end;

function TXFileSubset.GetVertexCount : integer;
begin
  result := length(FVertices);
end;

function TXFileSubset.GetVertexPosition(index : integer) : RVector3;
begin
  assert((index >= 0) and (index < length(FVertices)));
  result := FVertices[index].Position;
end;

{ TXFileBone }

constructor TXFileBone.Create(Name : string; SourceData : TDataNode);
var
  Key : AnsiString;
begin
  inherited Create();
  FName := name;
  if SourceData <> nil then
  begin
    FUnknownMatrix := SourceData['FrameTransformMatrix']['frameMatrix']['matrix'].AsMatrix;
    for Key in SourceData.Members.Keys do
      if SourceData[Key].DataType.Name = 'Frame' then
      begin
        AddChild(TXFileBone.Create(Key, SourceData[Key]));
      end;
  end;
end;

{ TAnimation }

constructor TAnimation.Create(Name : string; SourceData : TDataNode);
var
  Key, TargetBoneName : AnsiString;
begin
  FAnimationKeys := TObjectList<TAnimationKey>.Create();
  FName := name;
  // load data for all animationkeys
  for Key in SourceData.Members.Keys do
  begin
    assert(SourceData[Key].DataType.Name = 'Animation');
    assert(SourceData[Key].Members.ContainsKey('Reference'));
    assert(SourceData[Key].Members.ContainsKey('AnimationKey'));
    TargetBoneName := SourceData[Key]['Reference'].AsString;
    FAnimationKeys.Add(TAnimationKey.Create(TargetBoneName, SourceData[Key]['AnimationKey']));
  end;
end;

destructor TAnimation.Destroy;
begin
  FAnimationKeys.Free;
  inherited;
end;

function TAnimation.GetAnimationKey(index : integer) : TAnimationKey;
begin
  result := FAnimationKeys[index];
end;

function TAnimation.GetAnimationKeyCount : integer;
begin
  result := FAnimationKeys.Count;
end;

{ TAnimtionKey }

constructor TAnimationKey.Create(TargetBone : string; SourceData : TDataNode);
var
  KeyType, nKeys, nValues : DWord;
  AnimationKeys : TDataNodeArray;
  i : integer;
begin
  FTargetBone := TargetBone;

  // TimeKeys := TList<RTimeKey>.Create;
  // check keytype
  KeyType := SourceData['keyType'].AsDWord;
  if KeyType <> KEYTYPEMATRIXKEYS then raise ENotSupportedException.Create('TAnimation.TAnimtionKey.Create: For animation only matrix keys supported.');

  nKeys := SourceData['nKeys'].AsDWord;
  setlength(FKeyFrames, nKeys);

  AnimationKeys := TDataNodeArray(SourceData['keys']);
  for i := 0 to nKeys - 1 do
  begin
    assert(AnimationKeys.Values[i].DataType.Name = 'TimedFloatKeys');
    FKeyFrames[i].Time := AnimationKeys.Values[i]['time'].AsDWord;
    {$IFDEF DEBUG}
    nValues := AnimationKeys.Values[i]['tfkeys']['nValues'].AsDWord;
    assert(nValues = 16);
    {$ENDIF}
    FKeyFrames[i].AnimationMatrix := AnimationKeys.Values[i]['tfkeys']['values'].AsMatrix;
    assert((i = 0) or (FKeyFrames[i].Time > FKeyFrames[i - 1].Time));
  end;
  assert(KeyFrameCount >= 2);
end;

function TAnimationKey.GetKeyFrame(index : integer) : RKeyFrame;
begin
  assert((index >= 0) and (index < length(FKeyFrames)));
  result := FKeyFrames[index];
end;

function TAnimationKey.GetKeyFrameCount : integer;
begin
  result := length(FKeyFrames);
end;

{ RDeclElement }

function RDeclElement.GetSize : DWord;
begin
  case DeclType of
    D3DDECLTYPE_FLOAT1 : result := 1;
    D3DDECLTYPE_FLOAT2 : result := 2;
    D3DDECLTYPE_FLOAT3 : result := 3;
    D3DDECLTYPE_FLOAT4 : result := 4;
  else raise EXFileUnsupportedData.Create('RDeclElement.GetSize: DeclType not supported!');
  end;
end;

end.

unit Engine.AssetLoader.XFileLoader;

interface

uses
  Generics.Collections,
  Winapi.Windows,
  System.SysUtils,
  Engine.AssetLoader,
  Engine.AssetLoader.MeshAsset,
  Engine.Math,
  Engine.Helferlein,
  XFile.Loader;

type

  EXFileUnsupportedData = class(Exception);

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

  TXFileAssetLoader = class(TAssetLoader)
    private const
      ANIMATIONSPEEDCORRECTION = 1 / 5.33333333;
    private
      function ReadSubset(SourceData : TDataNode) : TMeshAssetSubset;
      function ReadMain(SourceData : XFile.Loader.TXFileLoader) : TMeshAsset;
      function ReadBone(BoneName : string; SourceData : TDataNode) : TMeshAssetBone;
      function ReadAnimation(AnimationName : string; SourceData : TDataNode) : TMeshAssetAnimationBone;
      function ReadAnimationKey(TargetBoneName : string; SourceData : TDataNode) : TMeshAssetAnimationChannelBone;
    public
      function LoadAsset(FileName : string) : TObject; override;

      class constructor Create();
  end;

const
  MINBONEWEIGHT = 0.001;

  KEYTYPEROTATION   = 1;
  KEYTYPESCALE      = 2;
  KEYTYPEPOSITION   = 3;
  KEYTYPEMATRIXKEYS = 4;

implementation

{ TXFileLoader }

class constructor TXFileAssetLoader.Create;
begin
  // TAssetManager.RegisterLoader(TXFileAssetLoader.Create, ['.x'])
end;

function TXFileAssetLoader.LoadAsset(FileName : string) : TObject;
var
  XFileData : XFile.Loader.TXFileLoader;
begin
  XFileData := nil;
  try
    XFileData := XFile.Loader.TXFileLoader.CreateFromFile(FileName);
    result := ReadMain(XFileData);
  finally
    XFileData.Free;
  end;
end;

function TXFileAssetLoader.ReadAnimation(AnimationName : string; SourceData : TDataNode) : TMeshAssetAnimationBone;
var
  key, TargetBoneName : string;
  i : integer;
begin
  result := TMeshAssetAnimationBone.Create(ShortString(AnimationName));
  result.AnimationChannelCount := SourceData.Members.Count;
  // load data for all animationkeys
  i := 0;
  for key in SourceData.Members.Keys do
  begin
    assert(SourceData[key].DataType.Name = 'Animation');
    assert(SourceData[key].Members.ContainsKey('Reference'));
    assert(SourceData[key].Members.ContainsKey('AnimationKey'));
    TargetBoneName := string(SourceData[key]['Reference'].AsString);
    result.AnimationChannels[i] := ReadAnimationKey(TargetBoneName, SourceData[key]['AnimationKey']);
    inc(i);
  end;
end;

function TXFileAssetLoader.ReadAnimationKey(TargetBoneName : string; SourceData : TDataNode) : TMeshAssetAnimationChannelBone;
var
  KeyType, nKeys, nValues : DWord;
  AnimationKeys : TDataNodeArray;
  i : integer;
  KeyFrame : RKeyFrameBone;
begin
  result := TMeshAssetAnimationChannelBone.Create;
  result.TargetBone := ShortString(TargetBoneName);
  // TimeKeys := TList<RTimeKey>.Create;
  // check keytype
  KeyType := SourceData['keyType'].AsDWord;
  if KeyType <> KEYTYPEMATRIXKEYS then raise ENotSupportedException.Create('TXFileAssetLoader: For animation only matrix keys supported.');

  nKeys := SourceData['nKeys'].AsDWord;
  result.KeyFrameCount := nKeys;

  AnimationKeys := TDataNodeArray(SourceData['keys']);
  for i := 0 to nKeys - 1 do
  begin
    assert(AnimationKeys.Values[i].DataType.Name = 'TimedFloatKeys');
    KeyFrame.Time := round(AnimationKeys.Values[i]['time'].AsDWord * ANIMATIONSPEEDCORRECTION);
    {$IFDEF DEBUG}
    nValues := AnimationKeys.Values[i]['tfkeys']['nValues'].AsDWord;
    assert(nValues = 16);
    {$ENDIF}
    // KeyFrame.AnimationMatrix := AnimationKeys.Values[i]['tfkeys']['values'].AsMatrix.Transpose;
    result.KeyFrames[i] := KeyFrame;
    assert((i = 0) or (result.KeyFrames[i].Time > result.KeyFrames[i - 1].Time));
  end;
  assert(result.KeyFrameCount >= 2);
end;

function TXFileAssetLoader.ReadBone(BoneName : string; SourceData : TDataNode) : TMeshAssetBone;
var
  key : string;
begin
  result := TMeshAssetBone.Create(BoneName);
  if SourceData <> nil then
  begin
    result.LocalTransform := SourceData['FrameTransformMatrix']['frameMatrix']['matrix'].AsMatrix.Transpose;
    for key in SourceData.Members.Keys do
      if SourceData[key].DataType.Name = 'Frame' then
      begin
        result.AddChild(ReadBone(key, SourceData[key]));
      end;
  end;
end;

function TXFileAssetLoader.ReadMain(SourceData : XFile.Loader.TXFileLoader) : TMeshAsset;
var
  subsetList : TList<TMeshAssetSubset>;

  procedure SearchForMeshRecursive(Node : TObjectDictionary<string, TDataNode>);
  var
    Name : string;
  begin
    if Node = nil then exit;
    for name in Node.Keys do
    begin
      if Node[name] = nil then continue;
      if (Node[name].Members <> nil) and Node[name].Members.ContainsKey('Mesh') then
      begin
        subsetList.Add(ReadSubset(Node[name]));
        exit;
      end
      else if (name = 'Mesh') and (Node[name].DataType.Name = 'Mesh') then
      begin
        subsetList.Add(ReadSubset(Node[name]));
        exit;
      end;
      SearchForMeshRecursive(Node[name].Members);
    end;
  end;

var
  i : integer;
  Name : string;
  animationList : TList<TMeshAssetAnimation>;
begin
  result := TMeshAsset.Create;
  // create dummy rootbone
  result.Skeleton.AddRootNode(TMeshAssetBone.Create('Dummy____RootNode'));
  result.Skeleton.RootNode.LocalTransform := RMatrix.IDENTITY;
  // collect all bones
  for name in SourceData.Data.Members.Keys do
    if not SourceData.Data[name].Members.ContainsKey('Mesh') and (SourceData.Data[name].DataType.Name = 'Frame') then
    begin
      result.Skeleton.RootNode.AddChild(ReadBone(name, SourceData.Data[name]));
    end;

  // collect meshdata
  subsetList := TList<TMeshAssetSubset>.Create;
  SearchForMeshRecursive(SourceData.Data.Members);
  result.SubsetCount := subsetList.Count;
  for i := 0 to subsetList.Count - 1 do
      result.Subsets[i] := subsetList[i];
  subsetList.Free;

  // collect all animation data
  animationList := TList<TMeshAssetAnimation>.Create;
  for name in SourceData.Data.Members.Keys do
    if SourceData.Data.Members[name].DataType.Name = 'AnimationSet' then
    begin
      animationList.Add(ReadAnimation(name, SourceData.Data.Members[name]));
    end;
  result.AnimationCount := animationList.Count;
  for i := 0 to animationList.Count - 1 do
      result.Animations[i] := animationList[i];
  animationList.Free;
end;

function TXFileAssetLoader.ReadSubset(SourceData : TDataNode) : TMeshAssetSubset;
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
  i, i2 : DWord;
  nVertices, nTexCoords, nNormals, nDeclElements, nDeclData, DeclDataBlockSize,
    nBones, nWeights, nFaces : DWord;
  localVertices : TArray<RMeshAssetVertex>;
  tmpArrayVec2 : ARVector2;
  tmpArrayVec3 : ARVector3;
  DeclElements : TArray<RDeclElement>;
  DeclData, face, boneVertexIndices : ADWord;
  Name : string;
  boneLink : RSkinBoneLink;
  boneWeights : ASingle;

begin
  result := TMeshAssetSubset.Create;
  if SourceData.DataType.Name <> 'Mesh' then
  begin
    result.MeshOffsetMatrix := GetFrameTransformMatrixRecursive(SourceData['Mesh']).Transpose;
    SourceData := SourceData['Mesh'];
    assert(SourceData.DataType.Name = 'Mesh');
  end
  else
  begin
    result.MeshOffsetMatrix := RMatrix.IDENTITY;
  end;
  // load vertex data (<> Meshvertexdata, because Vertices could be indexed)
  nVertices := SourceData['nVertices'].AsDWord;
  setlength(localVertices, nVertices);
  tmpArrayVec3 := SourceData['vertices'].AsARVector3;
  for i := 0 to nVertices - 1 do
      localVertices[i].Position := tmpArrayVec3[i];
  // load texturecoord data
  // not every mesh contains texturecoordinates, test it before load
  result.HasTextureCoordinates := False;
  if SourceData.Members.ContainsKey('MeshTextureCoords') then
  begin
    nTexCoords := SourceData['MeshTextureCoords']['nTextureCoords'].AsDWord;
    assert(nVertices = nTexCoords);
    tmpArrayVec2 := SourceData['MeshTextureCoords']['textureCoords'].AsARVector2;
    assert(integer(nTexCoords) = length(tmpArrayVec2));
    for i := 0 to nVertices - 1 do
        localVertices[i].TextureCoordinate := tmpArrayVec2[i];
    result.HasTextureCoordinates := True;
  end;
  // load normal data
  // not every mesh contains normals, test it before load
  result.HasNormals := False;
  if SourceData.Members.ContainsKey('MeshNormals') then
  begin
    nNormals := SourceData['MeshNormals']['nNormals'].AsDWord;
    tmpArrayVec3 := SourceData['MeshNormals']['normals'].AsARVector3;
    assert(integer(nNormals) = length(tmpArrayVec3));
    for i := 0 to nVertices - 1 do
        localVertices[i].Normal := tmpArrayVec3[i];
    result.HasNormals := True;
  end;

  // load DeclData (special binarydata) can contain normals, tangents, texcoords,...
  if SourceData.Members.ContainsKey('DeclData') then
  begin
    assert(result.HasNormals = False);
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
        D3DDECLUSAGE_NORMAL : result.HasNormals := True;
        D3DDECLUSAGE_TANGENT : result.HasTangents := True;
        D3DDECLUSAGE_BINORMAL : result.HasBinormals := True;
        D3DDECLUSAGE_TEXCOORD : result.HasTextureCoordinates := True;
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
  result.SkinBoneLinkCount := nBones;
  // add skin information (bones are read not per subset, but per mesh -> only read skindata, no bonedata expected)
  for i := 0 to nBones - 1 do
  begin
    name := 'SkinWeights' + HGeneric.TertOp<string>(i >= 1, IntToStr(i), '');
    assert(SourceData.Members.ContainsKey(name));
    boneLink.TargetBone := string(SourceData[name]['transformNodeName'].AsString);
    boneLink.BoneSpaceMatrix := SourceData[name]['matrixOffset']['matrix'].AsMatrix.Transpose;
    result.SkinBoneLinks[i] := boneLink;
    nWeights := SourceData[name]['nWeights'].AsDWord;
    boneWeights := SourceData[name]['weights'].AsAFloat;
    boneVertexIndices := SourceData[name]['vertexIndices'].AsADWord;
    assert(length(boneWeights) = length(boneVertexIndices));
    // apply skindata to vertices
    for i2 := 0 to nWeights - 1 do
    begin
      // skip weights < MINBONEWEIGHT because they won't make difference
      if boneWeights[i2] >= MINBONEWEIGHT then
      begin
        assert(localVertices[boneVertexIndices[i2]].BoneCount < MAXINFLUENCINGBONES);
        // set index to current skin-bone-link
        localVertices[boneVertexIndices[i2]].Bones[localVertices[boneVertexIndices[i2]].BoneCount] := i;
        localVertices[boneVertexIndices[i2]].BoneWeight[localVertices[boneVertexIndices[i2]].BoneCount] := boneWeights[i2];
        // new bone has set, inc counter
        inc(localVertices[boneVertexIndices[i2]].BoneCount);
      end;
    end;
  end;

  // load index data
  nFaces := SourceData['nFaces'].AsDWord;
  // every face consist of 3 vertices, need 3 indices per face
  result.VertexCount := nFaces * 3;
  // resolve index dependencies
  for i := 0 to nFaces - 1 do
  begin
    assert(TDataNodeArray(SourceData['faces']).Values[i]['nFaceVertexIndices'].AsDWord = 3);
    face := TDataNodeArray(SourceData['faces']).Values[i]['faceVertexIndices'].AsADWord;
    for i2 := 0 to 2 do
    begin
      result.Vertices[i * 3 + i2] := localVertices[face[i2]];
    end;
  end;
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

initialization

TXFileAssetLoader.ClassName;

end.

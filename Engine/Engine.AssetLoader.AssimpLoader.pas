unit Engine.AssetLoader.AssimpLoader;

interface

uses
  SysUtils,
  Math,
  Classes,
  Windows,
  Generics.Collections,
  Generics.Defaults,
  Engine.Math,
  Engine.Helferlein,
  Engine.AssetLoader,
  Engine.AssetLoader.MeshAsset,
  assimpheader,
  FBXFile.Loader;

type
  EAssimpError = class(Exception);
  EAssimpUnsupportedData = class(Exception);

  EnumTempKeyType = (ktScale, ktTranslate, ktRotate);
  SetTempKeyType = set of EnumTempKeyType;

  TTempKeyFrame = class
    Time : double;
    Scale : RVector3;
    Translate : RVector3;
    Rotation : RQuaternion;
    KeyTypes : SetTempKeyType;
    /// <summary> Interpolate all missing values</summary>
    procedure Interpolate(KeysBefore, KeysAfter : array of TTempKeyFrame);
    /// <summary> Return true, if all data (scale, translate and rotate) is present</summary>
    function HasCompleteData : boolean;
  end;

  TTempSubanimation = class
    private
      FBoneName : string;
      FKeys : TObjectList<TTempKeyFrame>;
    public
      constructor Create(BoneName : string);
      procedure ReadKeyData(DataSource : Pointer; KeyType : EnumTempKeyType; KeyCount : integer);
      procedure InterpolateData;
      function ToMeshAssetAnimationKey(TimeCorrectionFactor : single) : TMeshAssetAnimationChannelBone;
      destructor Destroy; override;
  end;

  TAssimpAssetLoader = class(TAssetLoader)
    private
      FTimeCorrectionFactor : single;
      function ReadSubset(Mesh : PAiMesh) : TMeshAssetSubset;
      function ReadMain(Scene : PAiScene) : TMeshAsset;
      function ReadBone(Mesh : TMeshAsset; Node : PAiNode) : TMeshAssetBone;
      function ReadAnimation(Animation : PAiAnimation) : TMeshAssetAnimationBone;
      function ReadMorphDataFromFBXFile(var Scene : TMeshAsset; FBXFileName : string) : TFBXScene;
      procedure CheckErrors(Condition : boolean);
    public
      class constructor Create;
      function LoadAsset(FileName : string) : TObject; override;
      destructor Destroy; override;
  end;

implementation

const
  DUMMYNODE_KEYWORD = '_$AssimpFbx$';

function ConvertFBXTime(Time : int64) : integer;
begin
  result := round(Time / 46186158); // refrence: http://download.autodesk.com/us/fbx/FBX_SDK_Help/files/fbxsdkref/ktime_8h-source.html
end;

{ TASSIMPAssetLoader }

procedure TAssimpAssetLoader.CheckErrors(Condition : boolean);
begin
  // if condition
  if not Condition then
      raise EAssimpError.Create(string(aiGetErrorString));
end;

class constructor TAssimpAssetLoader.Create;
begin
  TAssetManager.RegisterLoader(TAssimpAssetLoader.Create, ['.fbx', '.animfbx', '.obj', '.blend', '.3ds', '.x', '.dae']);
end;

destructor TAssimpAssetLoader.Destroy;
begin
  inherited;
end;

procedure LogCallback(message, user : PAiChar); cdecl;
var
  logtext : Ansistring;
begin
  logtext := Ansistring(message);
  writeln(logtext);
end;

function TAssimpAssetLoader.LoadAsset(FileName : string) : TObject;
var
  aiScene : PAiScene;
  FBXScene : TFBXScene;
  store : PAiPropertyStore;
  stream : TStream;
  buffer : TArray<Byte>;
  startTime, endTime : integer;
  fileFormat : string;
begin
  stream := nil;
  try
    fileFormat := ExtractFileExt(FileName).ToLowerInvariant;
    if (ExtractFileExt(FileName).ToLowerInvariant = '.fbx') or (ExtractFileExt(FileName).ToLowerInvariant = '.animfbx') then
    begin
      // set fileformat to fbx, because animfbx are also pure fbx files
      fileFormat := '.fbx';
      FTimeCorrectionFactor := 1000 / 30;
    end
    else if ExtractFileExt(FileName).ToLowerInvariant = '.x' then
        FTimeCorrectionFactor := 1 / 5;
    stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    setlength(buffer, stream.Size);
    stream.Read(buffer, stream.Size);
    initAssimp();
    // log.callback := LogCallback;
    // log.user := nil;
    // allocConsole();
    // aiAttachLogStream(@log);
    store := aiCreatePropertyStore;
    assert(store <> nil);
    // aiEnableVerboseLogging(AI_TRUE);
    // aiSetImportPropertyInteger(store, PAiChar(AI_CONFIG_IMPORT_FBX_PRESERVE_PIVOTS), AI_FALSE);
    // aiScene := aiImportFileFromMemoryWithProperties(@buffer[0], stream.Size, AI_POSTPROCESS_TRIANGULATE
    // or AI_POSTPROCESS_MAKELEFTHANDED or AI_POSTPROCESS_FLIPWINDINGORDER or AI_POSTPROCESS_FLIPUVS or AI_POSTPROCESS_CALCTANGENTSPACE, PAiChar(Ansistring(ExtractFileExt(FileName))), store);
    aiScene := aiImportFileFromMemoryWithProperties(@buffer[0], stream.Size,
      AI_POSTPROCESS_TRIANGULATE or AI_POSTPROCESS_FLIPUVS, PAiChar(Ansistring(fileFormat)), store);
    CheckErrors(aiScene <> nil);
    result := ReadMain(aiScene);
    aiReleasePropertyStore(store);
    // Currently assimp does not support morphanimation, so use an intern fbx loader to extract morphdata
    if ExtractFileExt(FileName).ToLowerInvariant = '.fbx' then
    begin
      FBXScene := ReadMorphDataFromFBXFile(TMeshAsset(result), FileName);
      startTime := ConvertFBXTime(FBXScene.GlobalSetting['TimeSpanStart'].DataAsInt64);
      endTime := ConvertFBXTime(FBXScene.GlobalSetting['TimeSpanStop'].DataAsInt64);
      TMeshAsset(result).ClipAnimationsAgainstTimeSlot(startTime, endTime);
      FBXScene.Free;
    end;
  finally
    // no need to release, will used more than once
    // releaseAssimp();
    stream.Free;
  end;
end;

function TTempKeyFrame.HasCompleteData : boolean;
begin
  result := KeyTypes = [ktScale, ktTranslate, ktRotate];
end;

procedure TTempKeyFrame.Interpolate(KeysBefore, KeysAfter : array of TTempKeyFrame);
var
  dt : single;
  i : integer;
  missingValues : SetTempKeyType;
  missingValue : EnumTempKeyType;
  KeyBefore, KeyAfter : TTempKeyFrame;
  targetKey : TTempKeyFrame;
begin
  // all values - present values -> missing values, order is unimportant because set
  missingValues := [ktTranslate, ktScale, ktRotate] - KeyTypes;
  for missingValue in missingValues do
  begin
    KeyBefore := nil;
    KeyAfter := nil;
    // get key providing missingValue before current key
    for i := length(KeysBefore) - 1 downto 0 do
      if missingValue in KeysBefore[i].KeyTypes then
      begin
        KeyBefore := KeysBefore[i];
        break;
      end;
    // get key providing missingValue after current key
    for i := 0 to length(KeysAfter) - 1 do
      if missingValue in KeysAfter[i].KeyTypes then
      begin
        KeyAfter := KeysAfter[i];
        break;
      end;
    // interpolate key
    // handle if only one key providing value is found -> simple assign missing value
    if not(assigned(KeyBefore) and assigned(KeyAfter)) then
    begin
      targetKey := HGeneric.TertOp<TTempKeyFrame>(assigned(KeyBefore), KeyBefore, KeyAfter);
      assert(assigned(targetKey));
      case missingValue of
        ktScale : Scale := targetKey.Scale;
        ktTranslate : Translate := targetKey.Translate;
        ktRotate : Rotation := targetKey.Rotation;
      end;
    end
    else
    begin
      dt := Time - KeyBefore.Time / (KeyAfter.Time - KeyBefore.Time);
      case missingValue of
        ktScale : Scale := KeyBefore.Scale.Lerp(KeyAfter.Scale, dt);
        ktTranslate : Translate := KeyBefore.Translate.Lerp(KeyAfter.Translate, dt);
        ktRotate : Rotation := KeyBefore.Rotation.SLerp(KeyAfter.Rotation, dt);
      end;
    end;
    KeyTypes := KeyTypes + [missingValue];
  end;
end;

{ TTempSubanimation }

constructor TTempSubanimation.Create(BoneName : string);
begin
  FKeys := TObjectList<TTempKeyFrame>.Create();
  FBoneName := BoneName;
end;

destructor TTempSubanimation.Destroy;
begin
  FKeys.Free;
  inherited;
end;

procedure TTempSubanimation.InterpolateData;
var
  i : integer;
  keys : TArray<TTempKeyFrame>;
begin
  keys := FKeys.ToArray;
  for i := 0 to FKeys.Count - 1 do
  begin
    FKeys[i].Interpolate(copy(keys, 0, i), copy(keys, i + 1, FKeys.Count - i + 1));
  end;
end;

procedure TTempSubanimation.ReadKeyData(DataSource : Pointer; KeyType : EnumTempKeyType; KeyCount : integer);
var
  i : integer;
  currentKeyIndex : integer;
  tempKeyFrame : TTempKeyFrame;

  // Search for correct position (depend on timestamp) to insert keyframe, if an keyframe
  // with timestamp already exists, keyframe will returned
  function GetOrAddKeyFrame(Timestamp : double) : TTempKeyFrame;
  begin
    result := nil;
    // end of list or position in list is fine ()
    if (currentKeyIndex + 1 > FKeys.Count) or (FKeys[currentKeyIndex].Time > Timestamp) then
    begin
      FKeys.Insert(currentKeyIndex, TTempKeyFrame.Create);
      result := FKeys[currentKeyIndex];
      result.Time := Timestamp;
    end
    // timestamps match? no need for new key, simple return key
    else if FKeys[currentKeyIndex].Time = Timestamp then
    begin
      result := FKeys[currentKeyIndex];
    end
    // timestamp greate else current key, make step and try again
    else if FKeys[currentKeyIndex].Time < Timestamp then
    begin
      inc(currentKeyIndex);
      result := GetOrAddKeyFrame(Timestamp);
    end;
    if not((currentKeyIndex = 0) or (FKeys[currentKeyIndex - 1].Time < FKeys[currentKeyIndex].Time)) then

        assert((currentKeyIndex = 0) or (FKeys[currentKeyIndex - 1].Time < FKeys[currentKeyIndex].Time));
  end;

begin
  currentKeyIndex := 0;
  // Init list with keys
  for i := 0 to KeyCount - 1 do
  begin
    tempKeyFrame := GetOrAddKeyFrame(PAiVectorKey(DataSource).mTime);
    case KeyType of
      ktScale :
        begin
          tempKeyFrame.Scale := PAiVectorKey(DataSource).mValue;
          inc(PAiVectorKey(DataSource));
        end;
      ktTranslate :
        begin
          tempKeyFrame.Translate := PAiVectorKey(DataSource).mValue;
          inc(PAiVectorKey(DataSource));
        end;
      ktRotate :
        begin
          tempKeyFrame.Rotation := PAiQuatKey(DataSource).mValue;
          inc(PAiQuatKey(DataSource));
        end;
    end;
    tempKeyFrame.KeyTypes := tempKeyFrame.KeyTypes + [KeyType];
  end;
end;

function TTempSubanimation.ToMeshAssetAnimationKey(TimeCorrectionFactor : single) : TMeshAssetAnimationChannelBone;
var
  i : integer;
  keyFrame : RKeyFrameBone;
begin
  result := TMeshAssetAnimationChannelBone.Create;
  result.TargetBone := ShortString(FBoneName);
  result.KeyFrameCount := FKeys.Count;
  for i := 0 to FKeys.Count - 1 do
  begin
    keyFrame.Translation := FKeys[i].Translate;
    keyFrame.Scale := FKeys[i].Scale;
    keyFrame.Rotation := FKeys[i].Rotation;
    // convert time from ticks to msec (@30 ticks per secound = default speed)
    keyFrame.Time := round(FKeys[i].Time * TimeCorrectionFactor);
    result.KeyFrames[i] := keyFrame;
  end;
end;

function TAssimpAssetLoader.ReadAnimation(Animation : PAiAnimation) : TMeshAssetAnimationBone;
var
  anim : PPAiNodeAnim;
  i : integer;
  channels : TObjectDictionary<string, TTempSubanimation>;
  subAnimation : TTempSubanimation;
  subAnimations : TArray<TTempSubanimation>;
begin
  result := TMeshAssetAnimationBone.Create(Animation.mName.AsString);
  channels := TObjectDictionary<string, TTempSubanimation>.Create([doOwnsValues]);
  anim := PPAiNodeAnim(Animation.mChannels);
  if Animation.mNumMeshChannels > 0 then
      raise EAssimpUnsupportedData.Create('TAssimpAssetLoader: Does not support morph animations.');
  for i := 0 to Animation.mNumChannels - 1 do
  begin
    // not already exists, create one
    begin
      subAnimation := TTempSubanimation.Create(anim^.mNodeName.AsString);
      channels.Add(anim^.mNodeName.AsString, subAnimation);
    end;
    subAnimation.ReadKeyData(anim^.mPositionKeys, ktTranslate, anim^.mNumPositionKeys);
    subAnimation.ReadKeyData(anim^.mScalingKeys, ktScale, anim^.mNumScalingKeys);
    subAnimation.ReadKeyData(anim^.mRotationKeys, ktRotate, anim^.mNumRotationKeys);
    inc(anim);
  end;
  result.AnimationChannelCount := channels.Count;
  subAnimations := channels.Values.ToArray;
  for i := 0 to channels.Count - 1 do
  begin
    subAnimations[i].InterpolateData;
    result.AnimationChannels[i] := subAnimations[i].ToMeshAssetAnimationKey(FTimeCorrectionFactor);
  end;
  channels.Free;
end;

function TAssimpAssetLoader.ReadBone(Mesh : TMeshAsset; Node : PAiNode) : TMeshAssetBone;
var
  i : integer;
  meshIndex : PAiUInt;
  child : PPAiNode;
begin
  // assert(not Node.mName.AsString.Contains(DUMMYNODE_KEYWORD));
  result := TMeshAssetBone.Create(Node.mName.AsString);
  result.LocalTransform := RMatrix(Node.mTransformation);
  if Node.mNumMeshes > 0 then
  begin
    meshIndex := Node.mMeshes;
    for i := 0 to Node.mNumMeshes - 1 do
    begin
      result.TargetSubsetCount := result.TargetSubsetCount + 1;
      result.TargetSubsets[result.TargetSubsetCount - 1] := Mesh.Subsets[meshIndex^];
      result.TargetSubsets[result.TargetSubsetCount - 1].SubsetName := result.name;
      inc(meshIndex);
    end;
  end;
  if Node.mNumChildren > 0 then
  begin
    child := Node.mChildren;
    for i := 0 to Node.mNumChildren - 1 do
    begin
      result.AddChild(ReadBone(Mesh, child^));
      inc(child);
    end;
  end;
end;

function TAssimpAssetLoader.ReadMain(Scene : PAiScene) : TMeshAsset;
var
  i : integer;
  Mesh : PPAiMesh;
  Animation : PPAiAnimation;
begin
  result := TMeshAsset.Create;
  // read Subsets
  result.SubsetCount := Scene.mNumMeshes;
  Mesh := Scene.mMeshes;
  for i := 0 to Scene.mNumMeshes - 1 do
  begin
    result.Subsets[i] := ReadSubset(Mesh^);
    // get next mesh in list
    inc(Mesh);
  end;
  assert(Scene.mRootNode <> nil);
  // read bones
  result.Skeleton.AddRootNode(ReadBone(result, Scene.mRootNode));
  result.Skeleton.RootNode.ApplyBoneMatrixOnSubset;
  // read animation
  if Scene.mNumAnimations > 0 then
  begin
    assert(Scene.mAnimations <> nil);
    Animation := Scene.mAnimations;
    result.AnimationCount := Scene.mNumAnimations;
    for i := 0 to Scene.mNumAnimations - 1 do
    begin
      result.Animations[i] := ReadAnimation(Animation^);
      inc(Animation);
    end;
  end;

end;

function TAssimpAssetLoader.ReadMorphDataFromFBXFile(var Scene : TMeshAsset; FBXFileName : string) : TFBXScene;
var
  FBXScene : TFBXScene;
  FileParser : TFBXFileParser;
  Model, Geometry, FBXMorphTarget, MorphTargetGeometrie, AnimationCurve : TFBXObject;
  ModelName, MorphTargetName : string;
  i, i2, i3, i4, key_count, vertexCount, faceCount, index : integer;
  start_time, end_time : int64;
  Animation : TMeshAssetAnimationMorph;
  Subset : TMeshAssetSubset;
  MorphTarget : TMeshAssetMorphTarget;
  indexedVertices, resolvedIndexedVertices, Vertices, GeometryIndexedVertices, vectorArray : TArray<RVector3>;
  GeometryVertices : TArray<RMeshAssetVertex>;
  indices, FBXIndices : TArray<integer>;
  AnimationChannel : TMeshAssetAnimationChannelMorph;
  value_array : TArray<single>;
  time_array : TArray<int64>;
  keyFrame : RKeyFrameMorph;
  // maps the fbx vertex index (key) (after flatten index) to index of a assimp vertex (value)
  FBXToAssimpMap : TDictionary<integer, integer>;

  procedure CalcFBXToAssimpMap();
  var
    AssimpIndices : TDictionary<RMeshAssetVertex, integer>;
    i : integer;
  begin
    FBXToAssimpMap := TDictionary<integer, integer>.Create;
    AssimpIndices := TDictionary<RMeshAssetVertex, integer>.Create(
      TEqualityComparer<RMeshAssetVertex>.Construct(
      function(const Left, Right : RMeshAssetVertex) : boolean
      begin
        result := Left.Position.SimilarTo(Right.Position) and Left.Normal.SimilarTo(Right.Normal);
      end,
      function(const Value : RMeshAssetVertex) : integer
      begin
        result := Value.Position.GetHashValue xor Value.Normal.GetHashValue;
      end));
    assert(length(GeometryVertices) = Subset.vertexCount);
    for i := 0 to Subset.vertexCount - 1 do
        AssimpIndices.AddOrSetValue(Subset.Vertices[i], i);
    for i := 0 to length(GeometryVertices) - 1 do
        FBXToAssimpMap.Add(i, AssimpIndices[GeometryVertices[i]]);
    AssimpIndices.Free;
  end;

  function CheckHasMorphTargets(Model : TFBXObject) : boolean;
  var
    i : integer;
    Geometry : TFBXObject;
  begin
    result := False;
    if length(Model.FilterConnectionsByType(foGeometry)) >= 1 then
    begin
      assert(length(Model.FilterConnectionsByType(foGeometry)) = 1);
      Geometry := Model.FilterConnectionsByType(foGeometry)[0];
      assert(Geometry.ObjectType = foGeometry);
      for i := 0 to Geometry.ConnectionCount - 1 do
          result := result or ((Geometry.Connections[i].ObjectType = foDeformer) and Geometry.Connections[i].name.Contains('Morpher'));
    end;
  end;

const
  ANIMATION_MOPRH_NAME = 'AnimStack::Take 001';

begin
  try
    FileParser := TFBXFileParser.CreateFromFile(FBXFileName);
    FBXScene := TFBXScene.Create(FileParser.Data);
    result := FBXScene;
    start_time := FBXScene.GlobalSetting['TimeSpanStart'].DataAsInt64;
    end_time := FBXScene.GlobalSetting['TimeSpanStop'].DataAsInt64;
    for i := 0 to FBXScene.Root.ConnectionCount - 1 do
      // only load morphdata from models that really has Morphdata, else the preprocessing steps, like loading vertexdata
      // and calculate the assimp <-> FBX map would be a waste of time
      if CheckHasMorphTargets(FBXScene.Root.Connections[i]) then
      begin
        Model := FBXScene.Root.Connections[i];
        assert(Model.ObjectType = foModel);
        // atm only one animation (with name "AnimStack::Take 001") is supported, so created it for morph if not present else get it
        Animation := nil;
        for i2 := 0 to Scene.AnimationCount - 1 do
          if (Scene.Animations[i2].AnimationType = atMorphAnimation) and (Scene.Animations[i2].name = ANIMATION_MOPRH_NAME) then
              Animation := Scene.Animations[i2].AsMorphAnimation;
        // no morph animation already exists, create one
        if Animation = nil then
        begin
          Animation := TMeshAssetAnimationMorph.Create(ANIMATION_MOPRH_NAME);
          Scene.AnimationCount := Scene.AnimationCount + 1;
          Scene.Animations[Scene.AnimationCount - 1] := Animation;
        end;

        if length(Model.FilterConnectionsByType(foGeometry)) >= 1 then
        begin
          assert(length(Model.FilterConnectionsByType(foGeometry)) = 1);
          Geometry := Model.FilterConnectionsByType(foGeometry)[0];

          // load position data and use indices to flattern indexed vertex data to a pure vertexarray
          vertexCount := Geometry.Properties['Vertices'].DataArrayElementCount div 3;
          vectorArray := Geometry.Properties['Vertices'].DataAsVector3Array;
          faceCount := Geometry.Properties['PolygonVertexIndex'].ArrayElementCount div 3;
          GeometryVertices := nil;
          setlength(GeometryVertices, faceCount * 3);
          indices := Geometry.Properties['PolygonVertexIndex'].DataAsIntArray;
          for i2 := 0 to faceCount * 3 - 1 do
          begin
            index := indices[i2];
            // -1 marks end of polygon
            if sign(index) = -1 then
                index := index xor -1;
            GeometryVertices[i2].Position := vectorArray[index];
            // write adjusted (removed -1 marker) back to indexarray
            indices[i2] := index;
          end;
          // load normals
          assert(Geometry.Properties['LayerElementNormal']['MappingInformationType'].DataAsString = 'ByPolygonVertex');
          assert(Geometry.Properties['LayerElementNormal']['ReferenceInformationType'].DataAsString = 'Direct');
          vectorArray := Geometry.Properties['LayerElementNormal']['Normals'].DataAsVector3Array;
          assert(length(vectorArray) = length(GeometryVertices));
          for i2 := 0 to max(length(vectorArray), length(GeometryVertices)) - 1 do
              GeometryVertices[i2].Normal := vectorArray[i2];

          ModelName := Model.name.Replace('Model::', '').Replace('::Model', '');
          Subset := Scene.SubsetsByName[ModelName];
          CalcFBXToAssimpMap;
          assert(Geometry.ObjectType = foGeometry);
          for i2 := 0 to Geometry.ConnectionCount - 1 do
          begin
            if (Geometry.Connections[i2].ObjectType = foDeformer) and Geometry.Connections[i2].name.Contains('Morpher') then
            begin
              assert(Geometry.Connections[i2].SubName = 'BlendShape');
              // iterate over all morphtargets
              for i3 := 0 to Geometry.Connections[i2].ConnectionCount - 1 do
                // ignore geometry, because this is the parent
                if Geometry.Connections[i2].Connections[i3].ObjectType <> foGeometry then
                begin
                  FBXMorphTarget := Geometry.Connections[i2].Connections[i3];
                  assert(FBXMorphTarget.ObjectType = foDeformer);
                  assert(FBXMorphTarget.name.Contains('SubDeformer'));
                  assert(FBXMorphTarget.SubName = 'BlendShapeChannel');

                  // if geometrie, this describe a FBXMorphTarget, so use this information to annotate already loaded
                  // subsetdata
                  MorphTargetGeometrie := FBXMorphTarget.GetConnectionByType(foGeometry);
                  // get name of FBXMorphTarget
                  MorphTargetName := MorphTargetGeometrie.name.Replace('Geometry::', '');
                  assert(MorphTargetGeometrie.SubName = 'Shape');
                  Subset.MorphTargetCount := Subset.MorphTargetCount + 1;
                  MorphTarget := TMeshAssetMorphTarget.Create;
                  MorphTarget.name := MorphTargetName;
                  Subset.MorphTargets[Subset.MorphTargetCount - 1] := MorphTarget;
                  indexedVertices := MorphTargetGeometrie.Properties['Vertices'].DataAsVector3Array;
                  FBXIndices := MorphTargetGeometrie.Properties['Indexes'].DataAsIntArray;
                  MorphTarget.DifferencePositionCount := length(indices);
                  setlength(resolvedIndexedVertices, length(indices));
                  for i4 := 0 to length(FBXIndices) - 1 do
                  begin
                    resolvedIndexedVertices[FBXIndices[i4]] := indexedVertices[i4];
                  end;

                  for i4 := 0 to length(indices) - 1 do
                  begin
                    MorphTarget.DifferencePosition[i4] := resolvedIndexedVertices[indices[i4]];
                  end;

                  AnimationCurve := FBXMorphTarget.GetConnectionByType(foAnimationCurveNode).GetConnectionByType(foAnimationCurve);
                  assert(AnimationCurve.name.Contains('AnimCurve'));
                  Animation.AnimationChannelCount := Animation.AnimationChannelCount + 1;
                  AnimationChannel := TMeshAssetAnimationChannelMorph.Create;
                  Animation.AnimationChannels[Animation.AnimationChannelCount - 1] := AnimationChannel;
                  AnimationChannel.MorphTarget := ShortString(MorphTargetName);
                  value_array := AnimationCurve.Properties['KeyValueFloat'].DataAsFloatArray;
                  time_array := AnimationCurve.Properties['KeyTime'].DataAsInt64Array;
                  assert(length(value_array) = length(time_array));
                  AnimationChannel.KeyFrameCount := length(value_array);
                  key_count := 0;
                  for i4 := 0 to length(value_array) - 1 do
                    // skip all frames that are not in Range of current scene
                    if InRange(time_array[i4], start_time, end_time) then
                    begin
                      keyFrame.Time := ConvertFBXTime(time_array[i4]);
                      keyFrame.Weight := value_array[i4];
                      AnimationChannel.KeyFrames[key_count] := keyFrame;
                      inc(key_count);
                    end;
                  AnimationChannel.KeyFrameCount := key_count;
                end;
            end;
          end;
          FBXToAssimpMap.Free;
        end;
      end;
  finally
    FileParser.Free;
  end;
end;

function TAssimpAssetLoader.ReadSubset(Mesh : PAiMesh) : TMeshAssetSubset;
var
  Vertices : TArray<RMeshAssetVertex>;
  vertex, Normal, tangent, binormal, texCoord : PAiVector3D;
  color : PAiColor4D;
  bone : PPAiBone;
  Weight : PAiVertexWeight;
  face : PAiFace;
  i, i2, i3, index, searchIndex : integer;
  Value : single;
  indices : TArray<integer>;
begin
  result := TMeshAssetSubset.Create;
  result.MeshOffsetMatrix := RMatrix.IDENTITY;
  if Mesh.mPrimitiveTypes <> AI_PRIMITIVETYPE_TRIANGLE then
      raise EAssimpUnsupportedData.Create('TAssimpAssetLoader: Only supports triangletype.');
  assert(Mesh.mNumVertices > 0);
  CheckErrors(Mesh.mVertices <> nil);
  setlength(Vertices, Mesh.mNumVertices);
  FillChar(Vertices[0], Mesh.mNumVertices * SizeOf(RMeshAssetVertex), 0);
  vertex := Mesh.mVertices;
  if Mesh.mColors[0] <> nil then
  begin
    result.HasColor := True;
    color := Mesh.mColors[0];
  end
  else color := nil;
  // normals?
  if Mesh.mNormals <> nil then
  begin
    result.HasNormals := True;
    Normal := Mesh.mNormals;
  end
  else Normal := nil;
  // texture coordinates? only support one channel
  if Mesh.mTextureCoords[0] <> nil then
  begin
    result.HasTextureCoordinates := True;
    if not Mesh.mNumUVComponents[0] = 2 then
        raise EAssimpUnsupportedData.Create('TAssimpAssetLoader: Only support 2D texturecoordinates.');
    texCoord := Mesh.mTextureCoords[0];
  end
  else texCoord := nil;
  // tangents?
  if Mesh.mTangents <> nil then
  begin
    result.HasTangents := True;
    tangent := Mesh.mTangents;
  end
  else tangent := nil;
  // binormals?
  if Mesh.mBitangents <> nil then
  begin
    result.HasBinormals := True;
    binormal := Mesh.mBitangents;
  end
  else binormal := nil;

  for i := 0 to Mesh.mNumVertices - 1 do
  begin
    Vertices[i].Position := vertex^;
    inc(vertex);
    if color <> nil then
    begin
      Vertices[i].color := RColor.CreateFromSingle(color^.r, color^.g, color^.b, color^.a);
      inc(color);
    end;
    if Normal <> nil then
    begin
      Vertices[i].Normal := Normal^;
      inc(Normal);
    end;
    if texCoord <> nil then
    begin
      Vertices[i].TextureCoordinate := RVector2.Create(texCoord^.x, texCoord^.y);
      inc(texCoord);
    end;
    if tangent <> nil then
    begin
      Vertices[i].tangent := tangent^;
      inc(tangent);
    end;
    if binormal <> nil then
    begin
      Vertices[i].binormal := binormal^;
      inc(binormal);
    end;
  end;

  // collect all bones
  if Mesh.mNumBones > 0 then
  begin
    result.SkinBoneLinkCount := Mesh.mNumBones;
    bone := Mesh.mBones;
    for i := 0 to Mesh.mNumBones - 1 do
    begin
      result.SkinBoneLinks[i] := RSkinBoneLink.Create(RMatrix(bone^.mOffsetMatrix), bone^.mName.AsString);
      Weight := bone^.mWeights;
      for i2 := 0 to bone^.mNumWeights - 1 do
      begin
        // index to SkinBoneLink

        index := Vertices[Weight.mVertexId].BoneCount;
        // if there are a vertex that is influenced by too many bones, discard the least important bone (including the new bone)
        if index >= MAXINFLUENCINGBONES then
        begin
          searchIndex := -1;
          Value := MaxSingle;
          for i3 := 0 to MAXINFLUENCINGBONES do
          begin
            // new lowest influencevalue found
            if Value > (HArray.ConvertDynamicToTArray(Vertices[Weight.mVertexId].BoneWeight) + [single(Weight.mWeight)])[i3] then
            begin
              Value := (HArray.ConvertDynamicToTArray(Vertices[Weight.mVertexId].BoneWeight) + [single(Weight.mWeight)])[i3];
              searchIndex := i3;
            end;
          end;
          if searchIndex < MAXINFLUENCINGBONES then
          begin
            Vertices[Weight.mVertexId].Bones[searchIndex] := i;
            Vertices[Weight.mVertexId].BoneWeight[searchIndex] := Weight.mWeight;
          end;
        end
        else
        begin
          // add new influencing bone to vertex
          Vertices[Weight.mVertexId].Bones[index] := i;
          Vertices[Weight.mVertexId].BoneWeight[index] := Weight.mWeight;
          // new bone
          inc(Vertices[Weight.mVertexId].BoneCount);
        end;
        inc(Weight);
      end;
      inc(bone);
    end;
  end;

  // dissolve all faces
  assert(Mesh.mNumFaces > 0);
  CheckErrors(Mesh.mFaces <> nil);
  // every face consists of 3 vertices
  result.vertexCount := Mesh.mNumFaces * 3;
  // also saves a list of índices
  setlength(indices, Mesh.mNumFaces * 3);
  face := Mesh.mFaces;
  for i := 0 to Mesh.mNumFaces - 1 do
  begin
    assert(face.mNumIndices = 3);
    for i2 := 0 to 2 do
    begin
      result.Vertices[i * 3 + i2] := Vertices[face.asArray[i2]];
      indices[i * 3 + i2] := face.asArray[i2];
    end;
    inc(face);
  end;
end;

initialization

TAssimpAssetLoader.ClassName;

end.

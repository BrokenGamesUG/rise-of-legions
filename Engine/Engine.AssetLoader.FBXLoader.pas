unit Engine.AssetLoader.FBXLoader;

interface


uses

  SysUtils,
  Math,
  Classes,
  Windows,
  Generics.Collections,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.AssetLoader,
  Engine.AssetLoader.MeshAsset,
  FBXFile.Loader,
  Engine.Serializer;

type
  EFBXLoaderError = class(Exception);

  TFBXAssetLoader = class(TAssetLoader)
    private
      FIndiceMap : TDictionary<string, TArray<Integer>>;
      function ConvertFBXTime(time : int64) : LongWord;
      function ReadSubset(Data : TFBXObject; ModelName : string) : TMeshAssetSubset;
      function ReadBone(Data : TFBXNode) : TMeshAssetBone;
      function ReadScene(Data : TFBXScene) : TMeshAsset;
    public
      class constructor Create;
      function LoadAsset(FileName : string) : TObject; override;
      destructor Destroy; override;
  end;

implementation


{ TFBXAssetLoader }

function TFBXAssetLoader.ConvertFBXTime(time : int64) : LongWord;
begin
  result := round(time / 46186158000 * 1000);
end;

class constructor TFBXAssetLoader.Create;
begin
  TAssetManager.RegisterLoader(TFBXAssetLoader.Create, ['.basefbx', '.morphfbx', '.binaryfbx']);
end;

destructor TFBXAssetLoader.Destroy;
begin
  inherited;
end;

function TFBXAssetLoader.LoadAsset(FileName : string) : TObject;
var
  Parser : TFBXFileParser;
  Scene : TFBXScene;
begin
  Parser := TFBXFileParser.CreateFromFile(FileName);
  FIndiceMap := TDictionary < string, TArray < Integer >>.Create();
  Scene := TFBXScene.Create(Parser.Data);
  result := ReadScene(Scene);
  Scene.Free;
  Parser.Free;
  FIndiceMap.Free;
end;

function TFBXAssetLoader.ReadBone(Data : TFBXNode) : TMeshAssetBone;
begin
  result := TMeshAssetBone.Create('Root_Node');
  result.LocalTransform := RMatrix.IDENTITY;
end;

procedure CleanUp(FileName : string);
var
  list : TStrings;
  blacklist : TArray<string>;
  i : Integer;
begin
  list := TStringList.Create;
  blacklist := ['<HashCode', '<FCount', '<FComparer', '<FGrowThreshold', '<FOnKeyNotify', '<FOnValueNotify', '<FKeyCollection',
    '<FValueCollection', '<FOwnerships', '</FItems>', '<FItems', '<FOnNotify', '<element_3/>', '<element_2/>'];
  list.LoadFromFile(FileName);
  i := 0;
  while i < list.Count do
  begin
    if HString.StartWith(list[i].Trim, blacklist) then
    begin
      list.Delete(i);
      Continue;
    end
    else if list[i].Trim.StartsWith('<element') and (list[i + 1].Trim = '<HashCode>-1</HashCode>') then
    begin
      list.Delete(i);
      list.Delete(i);
      list.Delete(i);
      list.Delete(i);
      list.Delete(i);
      Continue;
    end;
    inc(i);
  end;
  list.SaveToFile(FileName);
  list.Free;
end;

function TFBXAssetLoader.ReadScene(Data : TFBXScene) : TMeshAsset;
var
  Model, Geometry, MorphTargetGeometrie, AnimationCurve, FBXMorphTarget : TFBXObject;
  Subset : TMeshAssetSubset;
  prop : TFBXProperty;
  floatArray, value_array : TArray<single>;
  indexedVertices, Vertices : TArray<RVector3>;
  indices : TArray<Integer>;
  time_array : TArray<int64>;
  start_time, end_time : int64;
  i, i2, i3, i4, i5, key_count : Integer;
  matrix : RMatrix;
  MorphTargetName, ModelName : string;
  found : boolean;
  animation : TMeshAssetAnimationMorph;
  AnimationChannel : TMeshAssetAnimationChannelMorph;
  MorphTarget : TMeshAssetMorphTarget;
  keyFrame : RKeyFrameMorph;
begin
  result := TMeshAsset.Create;
  result.Skeleton.AddRootNode(ReadBone(nil));
  start_time := Data.GlobalSetting['TimeSpanStart'].DataAsInt64;
  end_time := Data.GlobalSetting['TimeSpanStop'].DataAsInt64;
  for i := 0 to Data.Root.ConnectionCount - 1 do
  begin
    Model := Data.Root.Connections[i];
    assert(Model.ObjectType = foModel);
    if length(Model.FilterConnectionsByType(foGeometry)) >= 1 then
    begin
      assert(length(Model.FilterConnectionsByType(foGeometry)) = 1);
      Geometry := Model.FilterConnectionsByType(foGeometry)[0];
      assert(Geometry.ObjectType = foGeometry);
      result.SubsetCount := result.SubsetCount + 1;
      // because name has format "Model::Sphere001", remove prename
      ModelName := Model.name.Replace('Model::', '');
      result.Subsets[result.SubsetCount - 1] := ReadSubset(Geometry, ModelName);

      matrix := RMatrix.IDENTITY;
      // build matrix from properties
      if Model.Properties['Properties70'].HasSubProperty('PreRotation') then
      begin
        floatArray := Model.Properties['Properties70']['PreRotation'].DataAsFloatArray;
        matrix := matrix * RMatrix.CreateRotationX(-DegToRad(floatArray[0]));
        matrix := matrix * RMatrix.CreateRotationY(DegToRad(floatArray[1]));
        matrix := matrix * RMatrix.CreateRotationZ(DegToRad(floatArray[2]));
      end;
      if Model.Properties['Properties70'].HasSubProperty('Lcl Rotation') then
      begin
        floatArray := Model.Properties['Properties70']['Lcl Rotation'].DataAsFloatArray;
        matrix := matrix * RMatrix.CreateRotationX(-DegToRad(floatArray[0]));
        matrix := matrix * RMatrix.CreateRotationY(DegToRad(floatArray[1]));
        matrix := matrix * RMatrix.CreateRotationZ(DegToRad(floatArray[2]));
      end;
      if Model.Properties['Properties70'].HasSubProperty('Lcl Translation') then
      begin
        prop := Model.Properties['Properties70']['Lcl Translation'];
        matrix.Translation := prop.DataAsVector3;
      end;
      result.Subsets[result.SubsetCount - 1].MeshOffsetMatrix := matrix;
    end;
  end;
  for i := 0 to Data.Root.ConnectionCount - 1 do
  begin
    Model := Data.Root.Connections[i];
    assert(Model.ObjectType = foModel);
    if length(Model.FilterConnectionsByType(foGeometry)) >= 1 then
    begin
      assert(length(Model.FilterConnectionsByType(foGeometry)) = 1);
      Geometry := Model.FilterConnectionsByType(foGeometry)[0];
      ModelName := Model.name.Replace('Model::', '');
      Subset := result.SubsetsByName[ModelName];
      assert(Geometry.ObjectType = foGeometry);
      for i2 := 0 to Geometry.ConnectionCount - 1 do
      begin
        if (Geometry.Connections[i2].ObjectType = foDeformer) and (Geometry.Connections[i2].name = 'Deformer::Morpher') then
        begin
          assert(Geometry.Connections[i2].name = 'Deformer::Morpher');
          assert(Geometry.Connections[i2].SubName = 'BlendShape');
          animation := TMeshAssetAnimationMorph.Create('AnimStack::Take 001');
          result.AnimationCount := result.AnimationCount + 1;
          result.Animations[result.AnimationCount - 1] := animation;
          // iterate over all morphtargets
          for i3 := 0 to Geometry.Connections[i2].ConnectionCount - 1 do
            // ignore geometry, because this is the parent
            if Geometry.Connections[i2].Connections[i3].ObjectType <> foGeometry then
            begin
              FBXMorphTarget := Geometry.Connections[i2].Connections[i3];
              assert(FBXMorphTarget.ObjectType = foDeformer);
              assert(FBXMorphTarget.name.StartsWith('SubDeformer::'));
              assert(FBXMorphTarget.SubName = 'BlendShapeChannel');

              // if geometrie, this describe a morphtarget, so use this information to annotate already loaded
              // subsetdata
              MorphTargetGeometrie := FBXMorphTarget.GetConnectionByType(foGeometry);
              // get name of morphtarget
              MorphTargetName := MorphTargetGeometrie.name.Replace('Geometry::', '');
              assert(MorphTargetGeometrie.SubName = 'Shape');
              Subset.MorphTargetCount := Subset.MorphTargetCount + 1;
              MorphTarget := TMeshAssetMorphTarget.Create;
              MorphTarget.name := MorphTargetName;
              Subset.MorphTargets[Subset.MorphTargetCount - 1] := MorphTarget;
              indexedVertices := MorphTargetGeometrie.Properties['Vertices'].DataAsVector3Array;
              indices := FIndiceMap[Subset.SubsetName];
              MorphTarget.DifferencePositionCount := length(indices);
              for i4 := 0 to length(indices) - 1 do
              begin
                MorphTarget.DifferencePosition[i4] := indexedVertices[indices[i4]];
              end;

              AnimationCurve := FBXMorphTarget.GetConnectionByType(foAnimationCurveNode).GetConnectionByType(foAnimationCurve);
              assert(AnimationCurve.name = 'AnimCurve::');
              animation.AnimationChannelCount := animation.AnimationChannelCount + 1;
              AnimationChannel := TMeshAssetAnimationChannelMorph.Create;
              animation.AnimationChannels[animation.AnimationChannelCount - 1] := AnimationChannel;
              AnimationChannel.MorphTarget := ShortString(MorphTargetName);
              value_array := AnimationCurve.Properties['KeyValueFloat'].DataAsFloatArray;
              time_array := AnimationCurve.Properties['KeyTime'].DataAsInt64Array;
              assert(length(value_array) = length(time_array));
              AnimationChannel.KeyFrameCount := length(value_array);
              key_count := 0;
              for i4 := 0 to length(value_array) - 1 do
              begin
                // skip all frames that are not in Range of current scene
                if InRange(time_array[i4], start_time, end_time) then
                begin
                  keyFrame.time := ConvertFBXTime(time_array[i4] - start_time);
                  keyFrame.Weight := value_array[i4];
                  AnimationChannel.KeyFrames[key_count] := keyFrame;
                  inc(key_count);
                end;
              end;
              AnimationChannel.KeyFrameCount := key_count;
            end;
        end;
      end;
    end;
  end;
  // TXMLSerializer.SaveObjectToFile(Data.Root, 'c:\test.xml');
  // CleanUp('c:\test.xml');
end;

function TFBXAssetLoader.ReadSubset(Data : TFBXObject; ModelName : string) : TMeshAssetSubset;
var
  indexedVertices, Vertices : TArray<RMeshAssetVertex>;
  vertexCount, faceCount, i, index : Integer;
  floatArray : TArray<single>;
  integerArray, indices : TArray<Integer>;
begin
  result := TMeshAssetSubset.Create;
  result.SubsetName := ModelName;

  vertexCount := Data.Properties['Vertices'].DataArrayElementCount div 3;
  setlength(indexedVertices, vertexCount);
  floatArray := Data.Properties['Vertices'].DataAsFloatArray;
  assert(vertexCount = length(floatArray) div 3);
  for i := 0 to (length(floatArray) div 3) - 1 do
  begin
    indexedVertices[i].Position := RVector3.Create(
      floatArray[i * 3 + 0],
      floatArray[i * 3 + 1],
      floatArray[i * 3 + 2]);
  end;
  faceCount := Data.Properties['PolygonVertexIndex'].ArrayElementCount div 3;
  setlength(Vertices, faceCount * 3);
  integerArray := Data.Properties['PolygonVertexIndex'].DataAsIntArray;
  assert(faceCount * 3 = length(integerArray));
  setlength(indices, length(integerArray));
  for i := 0 to faceCount * 3 - 1 do
  begin
    index := integerArray[i];
    // -1 marks end of polygon
    if sign(index) = -1 then
        index := index xor -1;
    Vertices[i] := indexedVertices[index];
    indices[i] := index;
  end;
  FIndiceMap.Add(ModelName, indices);
  // load normals
  assert(Data.Properties['LayerElementNormal']['MappingInformationType'].DataAsString = 'ByPolygonVertex');
  assert(Data.Properties['LayerElementNormal']['ReferenceInformationType'].DataAsString = 'Direct');
  floatArray := Data.Properties['LayerElementNormal']['Normals'].DataAsFloatArray;
  for i := 0 to (length(floatArray) div 3) - 1 do
  begin
    Vertices[i].Normal := RVector3.Create(
      floatArray[i * 3 + 0],
      floatArray[i * 3 + 1],
      floatArray[i * 3 + 2]);
  end;
  result.HasNormals := True;

  // load binormals if there any present
  if Data.HasProperty('LayerElementBinormal') then
  begin
    assert(Data.Properties['LayerElementBinormal']['MappingInformationType'].DataAsString = 'ByPolygonVertex');
    assert(Data.Properties['LayerElementBinormal']['ReferenceInformationType'].DataAsString = 'Direct');
    floatArray := Data.Properties['LayerElementBinormal']['Binormals'].DataAsFloatArray;
    for i := 0 to (length(floatArray) div 3) - 1 do
    begin
      Vertices[i].Binormal := RVector3.Create(
        floatArray[i * 3 + 0],
        floatArray[i * 3 + 1],
        floatArray[i * 3 + 2]);
    end;
    result.HasBinormals := True;
  end
  else result.HasBinormals := False;

  // load tangents if there any present
  if Data.HasProperty('LayerElementTangent') then
  begin
    assert(Data.Properties['LayerElementTangent']['MappingInformationType'].DataAsString = 'ByPolygonVertex');
    assert(Data.Properties['LayerElementTangent']['ReferenceInformationType'].DataAsString = 'Direct');
    floatArray := Data.Properties['LayerElementTangent']['Tangents'].DataAsFloatArray;
    for i := 0 to (length(floatArray) div 3) - 1 do
    begin
      Vertices[i].Tangent := RVector3.Create(
        floatArray[i * 3 + 0],
        floatArray[i * 3 + 1],
        floatArray[i * 3 + 2]);
    end;
    result.HasTangents := True;
  end
  else result.HasTangents := False;

  result.HasTextureCoordinates := True;

  // tranfer calculated vertices into model
  result.vertexCount := length(Vertices);
  for i := 0 to length(Vertices) - 1 do
      result.Vertices[i] := Vertices[i];
end;

initialization

TFBXAssetLoader.ClassName;

end.

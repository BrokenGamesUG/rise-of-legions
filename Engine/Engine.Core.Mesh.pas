unit Engine.Core.Mesh;

interface

uses
  // ========= Delphi =========
  System.SysUtils,
  System.Classes,
  // ========= Engine ========
  Engine.Vertex,
  Engine.Math,
  Engine.Math.Collision3D,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.AssetLoader.MeshAsset;

const
  ENGINEMESH_FORMAT_EXTENSION = '.msh';

type
  EEngineRawMeshError = class(Exception);

  REngineRawMeshBone = packed record
    Name : string[128];
    Matrix : RMatrix4x3;
    ChildCount : integer;
    constructor Create(const Name : string; const Matrix : RMatrix4x3; ChildCount : integer);
  end;

  REngineRawSkinBoneLink = packed record
    TargetBoneName : string[128];
    OffsetMatrix : RMatrix4x3;
    constructor Create(const TargetBoneName : string; const OffsetMatrix : RMatrix4x3);
  end;

  /// <summary> A very raw engine own fileformat for meshes. Uses to fastload
  /// meshes including bone and morph animation .</summary>
  TEngineRawMesh = class
    private const
      FILE_IDENTIFIER : string[4]  = '%KMF';
      CURRENT_VERSION : string[4]  = 'V.01';
      HEADER_PROTECTOR : string[4] = AnsiChar($6A) + AnsiChar($B5) + AnsiChar($3C) + AnsiChar($6A);
      CHUNK_PROTECTOR : string[4]  = AnsiChar($4F) + AnsiChar($E0) + AnsiChar($5A) + AnsiChar($94);
    private type
      /// <summary> Preheader is read before any other data is read from file and should NEVER
      /// changed, because changes of different formats will only determined after prehader was read.</summary>
      RPreHeader = packed record
        FileIdentifier : string[4];
        /// <summary> Inspired by PNG fileformat 4 bytes for minimum file missuse safety.</summary>
        Protector : string[4];
        Version : string[4];
        HeaderLength : UInt32;
        class function Create : RPreHeader; static;
      end;

      /// <summary> Basedata for mesh. Some of this data is necessary to process further data that is saved.</summary>
      RHeader = packed record
        MorphTargetCount : UInt32;
        BoundingBox : RAABB;
        BoundingSphere : RSphere;
        /// <summary> MD5 filehash from originalfile.</summary>
        OriginalFileHash : string[32];
      end;

      /// <summary> Introdata for vertexdata chunk.  right after data of size datasize.</summary>
      RVertexDataHeader = packed record
        Protector : string[4];
        /// <summary> Size of single vertex clipped against MorphTargetCount to ensure engine vertex size has not changed.</summary>
        VertexSize : UInt32;
        VerticesCount : UInt32;
      end;

      RIndexDataHeader = packed record
        Protector : string[4];
        IndicesCount : UInt32;
      end;

      RBoneDataHeader = packed record
        Protector : string[4];
        BoneCount : UInt32;
      end;

      RSkinDataHeader = packed record
        Protector : string[4];
        SkinBoneLinkCount : UInt32;
      end;

      RAnimationDataHeader = packed record
        Protector : string[4];
        BoneAnimationCount : UInt32;
        MorphAnimationCount : UInt32;
      end;
    private
      FOriginalFileHash : string;
      FOwnsData : boolean;
      FVertexData : AVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight;
      FMorphTargetCount : UInt32;
      FBoundingBox : RAABB;
      FIndexData : TArray<LongWord>;
      FBoundingSphere : RSphere;
      FBoneData : TArray<REngineRawMeshBone>;
      FSkinData : TArray<REngineRawSkinBoneLink>;
      FMorphAnimationData : TArray<TMeshAssetAnimationMorph>;
      FBoneAnimationData : TArray<TMeshAssetAnimationBone>;
      FMorphtargetMapping : TArray<ShortString>;
      FColorData : TArray<RVector4>;
      function GetMorphtargetMapping : TArray<string>;
      procedure SetMorphtargetMapping(const Value : TArray<string>);
    public
      class function ConvertFileNameToRaw(const FileName : string) : string; static;
    public
      property MorphTargetCount : UInt32 read FMorphTargetCount write FMorphTargetCount;
      property BoundingBox : RAABB read FBoundingBox write FBoundingBox;
      property BoundingSphere : RSphere read FBoundingSphere write FBoundingSphere;
      property VertexData : AVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight read FVertexData write FVertexData;
      property ColorData : TArray<RVector4> read FColorData write FColorData;
      property IndexData : TArray<LongWord> read FIndexData write FIndexData;
      property BoneData : TArray<REngineRawMeshBone> read FBoneData write FBoneData;
      property SkinData : TArray<REngineRawSkinBoneLink> read FSkinData write FSkinData;
      property BoneAnimationData : TArray<TMeshAssetAnimationBone> read FBoneAnimationData write FBoneAnimationData;
      property MorphAnimationData : TArray<TMeshAssetAnimationMorph> read FMorphAnimationData write FMorphAnimationData;
      property MorphtargetMapping : TArray<string> read GetMorphtargetMapping write SetMorphtargetMapping;
      property OriginalFileHash : string read FOriginalFileHash;
      // property Data : TArray < RSuperPointer < Cardinal >> read FData;
      /// <summary> Init internal data and infodata, like width/height, with data from parameter data.
      /// CAUTION: The data is NOT copied, so if data is accessed or method save is called, after passed data was freed, errors will occur.</summary>
      constructor CreateEmpty(const OriginalFilename : string);
      /// <summary> Init internal data and and infodata, like width/height, with data from memory stream.
      /// CAUTION: The data is NOT copied, so if data is accessed or method save is called, after passed memory stream was freed, errors will occur.</summary>
      constructor CreateFromStream(Stream : TStream);
      constructor LoadHeaderFromFile(const FileName : string);
      procedure SaveToFile(const FileName : string);
      destructor Destroy; override;
  end;

implementation

{ TEngineRawMesh }

class function TEngineRawMesh.ConvertFileNameToRaw(const FileName : string) : string;
begin
  result := ChangeFileExt(FileName, ENGINEMESH_FORMAT_EXTENSION);
end;

constructor TEngineRawMesh.CreateEmpty(const OriginalFilename : string);
begin
  FOriginalFileHash := HFileIO.FileToMD5Hash(OriginalFilename);
  FOwnsData := False;
end;

constructor TEngineRawMesh.CreateFromStream(Stream : TStream);
var
  PreHeader : RPreHeader;
  Header : RHeader;
  VertexDataHeader : RVertexDataHeader;
  IndexDataHeader : RIndexDataHeader;
  BoneDataHeader : RBoneDataHeader;
  SkinDataHeader : RSkinDataHeader;
  AnimationDataHeader : RAnimationDataHeader;
  i, MorphtargetMappingLength : integer;
begin
  FOwnsData := True;
  Stream.Read(PreHeader, SizeOf(RPreHeader));
  if not((PreHeader.Protector = HEADER_PROTECTOR) and (PreHeader.FileIdentifier = FILE_IDENTIFIER) and (PreHeader.Version = CURRENT_VERSION)) then
      raise EEngineRawMeshError.CreateFmt('TEngineRawMesh.CreateFromMemoryStream: Invalid fileformat. StreamSize: %d, StreamPosition: %d', [Stream.Size, Stream.Position]);
  Stream.Read(Header, SizeOf(RHeader));
  MorphTargetCount := Header.MorphTargetCount;
  BoundingBox := Header.BoundingBox;
  BoundingSphere := Header.BoundingSphere;
  FOriginalFileHash := string(Header.OriginalFileHash);

  // read vertex data from file
  Stream.Read(VertexDataHeader, SizeOf(RVertexDataHeader));
  if VertexDataHeader.Protector <> CHUNK_PROTECTOR then
      raise EEngineRawMeshError.Create('TEngineRawMesh.CreateFromMemoryStream: Invalid chunk protector.');
  if VertexDataHeader.VertexSize <> UInt32(RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.GetSize(MorphTargetCount)) then
      raise EEngineRawMeshError.Create('TEngineRawMesh.CreateFromMemoryStream: VertexSize missmatch. Meshfile not compatible with current engine version.');
  SetLength(FVertexData, VertexDataHeader.VerticesCount);
  Stream.Read(FVertexData[0], SizeOf(RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight) * VertexDataHeader.VerticesCount);

  // read vertex color data from file
  SetLength(FColorData, VertexDataHeader.VerticesCount);
  Stream.Read(FColorData[0], SizeOf(RVector4) * VertexDataHeader.VerticesCount);

  // read index data from file
  Stream.Read(IndexDataHeader, SizeOf(RIndexDataHeader));
  if IndexDataHeader.Protector <> CHUNK_PROTECTOR then
      raise EEngineRawMeshError.Create('TEngineRawMesh.CreateFromMemoryStream: Invalid chunk protector.');
  SetLength(FIndexData, IndexDataHeader.IndicesCount);
  Stream.Read(FIndexData[0], SizeOf(LongWord) * IndexDataHeader.IndicesCount);

  // read bone data from file
  Stream.Read(BoneDataHeader, SizeOf(RBoneDataHeader));
  if BoneDataHeader.Protector <> CHUNK_PROTECTOR then
      raise EEngineRawMeshError.Create('TEngineRawMesh.CreateFromMemoryStream: Invalid chunk protector.');
  SetLength(FBoneData, BoneDataHeader.BoneCount);
  Stream.Read(FBoneData[0], SizeOf(REngineRawMeshBone) * BoneDataHeader.BoneCount);

  // read skin data from file
  Stream.Read(SkinDataHeader, SizeOf(RSkinDataHeader));
  if SkinDataHeader.Protector <> CHUNK_PROTECTOR then
      raise EEngineRawMeshError.Create('TEngineRawMesh.CreateFromMemoryStream: Invalid chunk protector.');
  SetLength(FSkinData, SkinDataHeader.SkinBoneLinkCount);
  Stream.Read(FSkinData[0], SizeOf(REngineRawSkinBoneLink) * SkinDataHeader.SkinBoneLinkCount);

  // read animation data from file
  Stream.Read(AnimationDataHeader, SizeOf(RAnimationDataHeader));
  if AnimationDataHeader.Protector <> CHUNK_PROTECTOR then
      raise EEngineRawMeshError.Create('TEngineRawMesh.CreateFromMemoryStream: Invalid chunk protector.');
  SetLength(FBoneAnimationData, AnimationDataHeader.BoneAnimationCount);
  for i := 0 to AnimationDataHeader.BoneAnimationCount - 1 do
      FBoneAnimationData[i] := TMeshAssetAnimationBone.CreateFromStream(Stream);
  SetLength(FMorphAnimationData, AnimationDataHeader.MorphAnimationCount);
  for i := 0 to AnimationDataHeader.MorphAnimationCount - 1 do
      FMorphAnimationData[i] := TMeshAssetAnimationMorph.CreateFromStream(Stream);
  MorphtargetMappingLength := Stream.ReadAny<integer>();
  SetLength(FMorphtargetMapping, MorphtargetMappingLength);
  Stream.Read(FMorphtargetMapping[0], SizeOf(ShortString) * MorphtargetMappingLength);
  assert(Stream.EoF);
end;

destructor TEngineRawMesh.Destroy;
begin
  if FOwnsData then
  begin
    HArray.FreeAllObjects<TMeshAssetAnimationMorph>(FMorphAnimationData);
    HArray.FreeAllObjects<TMeshAssetAnimationBone>(FBoneAnimationData);
  end;
  inherited;
end;

function TEngineRawMesh.GetMorphtargetMapping : TArray<string>;
begin
  result := HArray.Map<ShortString, string>(FMorphtargetMapping,
    function(const Value : ShortString) : string
    begin
      result := string(Value);
    end);
end;

constructor TEngineRawMesh.LoadHeaderFromFile(const FileName : string);
var
  Filecontent : TFileStream;
  PreHeader : RPreHeader;
  Header : RHeader;
begin
  Filecontent := nil;
  try
    Filecontent := TFileStream.Create(FileName, fmOpenRead);
    Filecontent.Read(PreHeader, SizeOf(RPreHeader));
    if not((PreHeader.Protector = HEADER_PROTECTOR) and (PreHeader.FileIdentifier = FILE_IDENTIFIER) and (PreHeader.Version = CURRENT_VERSION)) then
        raise EEngineRawMeshError.Create('TEngineRawMesh.CreateFromMemoryStream: Invalid fileformat.');
    Filecontent.Read(Header, SizeOf(RHeader));
    FOriginalFileHash := string(Header.OriginalFileHash);
  finally
    Filecontent.Free;
  end;
end;

procedure TEngineRawMesh.SaveToFile(const FileName : string);
var
  FileStream : TFileStream;
  PreHeader : RPreHeader;
  Header : RHeader;
  VertexDataHeader : RVertexDataHeader;
  IndexDataHeader : RIndexDataHeader;
  BoneDataHeader : RBoneDataHeader;
  SkinDataHeader : RSkinDataHeader;
  AnimationDataHeader : RAnimationDataHeader;
  i : integer;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    PreHeader := RPreHeader.Create;
    FileStream.Write(PreHeader, SizeOf(RPreHeader));
    Header.OriginalFileHash := ShortString(OriginalFileHash);
    Header.MorphTargetCount := MorphTargetCount;
    Header.BoundingBox := BoundingBox;
    Header.BoundingSphere := BoundingSphere;
    FileStream.Write(Header, SizeOf(RHeader));

    // write vertex data to file
    assert(length(VertexData) > 0);
    VertexDataHeader.Protector := CHUNK_PROTECTOR;
    VertexDataHeader.VertexSize := RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight.GetSize(MorphTargetCount);
    VertexDataHeader.VerticesCount := length(VertexData);
    FileStream.Write(VertexDataHeader, SizeOf(RVertexDataHeader));
    FileStream.Write(VertexData[0], SizeOf(RVertexMorphPositionNormalSNormalTextureTangentBinormalBoneIndicesWeight) * length(VertexData));

    // write vertex color data to file
    assert(length(ColorData) = length(VertexData));
    FileStream.Write(ColorData[0], SizeOf(RVector4) * length(ColorData));

    // write index data to file
    IndexDataHeader.Protector := CHUNK_PROTECTOR;
    IndexDataHeader.IndicesCount := length(IndexData);
    FileStream.Write(IndexDataHeader, SizeOf(RIndexDataHeader));
    FileStream.Write(IndexData[0], SizeOf(LongWord) * length(IndexData));

    // write bone data to file
    BoneDataHeader.Protector := CHUNK_PROTECTOR;
    BoneDataHeader.BoneCount := length(BoneData);
    FileStream.Write(BoneDataHeader, SizeOf(RBoneDataHeader));
    FileStream.Write(BoneData[0], SizeOf(REngineRawMeshBone) * length(BoneData));

    // write skin data to file
    SkinDataHeader.Protector := CHUNK_PROTECTOR;
    SkinDataHeader.SkinBoneLinkCount := length(SkinData);
    FileStream.Write(SkinDataHeader, SizeOf(RSkinDataHeader));
    FileStream.Write(SkinData[0], SizeOf(REngineRawSkinBoneLink) * length(SkinData));

    // write animation data to file
    AnimationDataHeader.Protector := CHUNK_PROTECTOR;
    AnimationDataHeader.BoneAnimationCount := length(BoneAnimationData);
    AnimationDataHeader.MorphAnimationCount := length(MorphAnimationData);
    FileStream.Write(AnimationDataHeader, SizeOf(RAnimationDataHeader));
    for i := 0 to length(BoneAnimationData) - 1 do
        BoneAnimationData[i].SaveToStream(FileStream);
    for i := 0 to length(MorphAnimationData) - 1 do
        MorphAnimationData[i].SaveToStream(FileStream);
    FileStream.WriteAny<integer>(length(FMorphtargetMapping));
    FileStream.Write(FMorphtargetMapping[0], SizeOf(ShortString) * length(FMorphtargetMapping));
  finally
    FileStream.Free;
  end;
end;

procedure TEngineRawMesh.SetMorphtargetMapping(const Value : TArray<string>);
begin
  FMorphtargetMapping := HArray.Map<string, ShortString>(Value,
    function(const Value : string) : ShortString
    begin
      result := ShortString(Value);
    end);
end;

{ TEngineRawMesh.RPreHeader }

class function TEngineRawMesh.RPreHeader.Create : RPreHeader;
begin
  result.FileIdentifier := TEngineRawMesh.FILE_IDENTIFIER;
  result.Protector := TEngineRawMesh.HEADER_PROTECTOR;
  result.Version := TEngineRawMesh.CURRENT_VERSION;
  result.HeaderLength := SizeOf(RHeader);
end;

{ REngineRawMeshBone }

constructor REngineRawMeshBone.Create(const Name : string; const Matrix : RMatrix4x3; ChildCount : integer);
begin
  assert(name.length <= 128);
  self.Name := ShortString(name);
  self.Matrix := Matrix;
  self.ChildCount := ChildCount;
end;

{ REngineRawSkinBoneLink }

constructor REngineRawSkinBoneLink.Create(const TargetBoneName : string; const OffsetMatrix : RMatrix4x3);
begin
  self.TargetBoneName := ShortString(TargetBoneName);
  self.OffsetMatrix := OffsetMatrix;
end;

end.

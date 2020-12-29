unit Engine.Core.Texture;

interface

uses
  // ========= Delphi =========
  System.SysUtils,
  System.Classes,
  // ========= Third-Party =====
  IdHashCRC,
  // ========= Engine ========
  Engine.Helferlein.Windows,
  Engine.GfxApi.Types;

const
  ENGINETEXTURE_FORMAT_EXTENSION = '.tex';

type
  EEngineRawTextureError = class(Exception);

  /// <summary> A very raw engine own fileformat for textures. Uses to fastload
  /// textures including mipmaps.</summary>
  TEngineRawTexture = class
    private const
      FILE_IDENTIFIER : string[4]  = '%KTF';
      CURRENT_VERSION : string[4]  = 'V.01';
      HEADER_PROTECTOR : string[4] = AnsiChar($0D) + AnsiChar($A0) + AnsiChar($1A) + AnsiChar($0A);
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

      /// <summary> Basedata for texture. Some of this data is necessary to process further data that is saved.</summary>
      RHeader = packed record
        Width : UInt32;
        Height : UInt32;
        Format : EnumTextureFormat;
        MipLevels : UInt32;
        /// <summary> MD5 filehash from originalfile.</summary>
        OriginalFileHash : string[32];
      end;

      /// <summary> Introdata for an mip level chunk. If file has multiple mipmap levels, next miplevel chunk starts
      /// right after data of size datasize.</summary>
      RMipLevelChunkHeader = packed record
        Width : UInt32;
        Height : UInt32;
        /// <summary> Minimum safety, if protector value is wrong, data was not correctly loaded or file is corrupted.</summary>
        Protector : string[4];
        DataSize : UInt64;
        /// <summary> If Value > 0, data is RLE compressed.</summary>
        CompressedDataSize : UInt64;
      end;
    private
      FWidth : UInt32;
      FFormat : EnumTextureFormat;
      FMipLevels : UInt32;
      FHeight : UInt32;
      FOriginalFileHash : string;
      FData : TArray<RSuperPointer<Cardinal>>;
      FOwnsData : boolean;
      function RLECompressData(const Data : RSuperPointer<Cardinal>) : TArray<Cardinal>;
      function RLEUncompressData(const CompressedData : RSuperPointer<Cardinal>; CompressedDataCount, Width, Height : UInt32) : RSuperPointer<Cardinal>;
    public
      class function ConvertFileNameToRaw(const FileName : string) : string; static;
    public
      property Width : UInt32 read FWidth;
      property Height : UInt32 read FHeight;
      property Format : EnumTextureFormat read FFormat;
      property MipLevels : UInt32 read FMipLevels;
      property OriginalFileHash : string read FOriginalFileHash;
      property Data : TArray < RSuperPointer < Cardinal >> read FData;
      /// <summary> Init internal data and infodata, like width/height, with data from parameter data.
      /// CAUTION: The data is NOT copied, so if data is accessed or method save is called, after passed data was freed, errors will occur.</summary>
      constructor CreateFromData(const Data : TArray<RSuperPointer<Cardinal>>; Format : EnumTextureFormat; const OriginalFilename : string);
      /// <summary> Init internal data and and infodata, like width/height, with data from memory stream.
      /// CAUTION: The data is NOT copied, so if data is accessed or method save is called, after passed memory stream was freed, errors will occur.</summary>
      constructor CreateFromMemoryStream(Filecontent : TMemoryStream);
      constructor LoadHeaderFromFile(const FileName : string);
      procedure SaveToFile(const FileName : string);
      destructor Destroy; override;
  end;

implementation

{ TEngineRawTexture }

class function TEngineRawTexture.ConvertFileNameToRaw(const FileName : string) : string;
begin
  result := ChangeFileExt(FileName, ENGINETEXTURE_FORMAT_EXTENSION);
end;

constructor TEngineRawTexture.CreateFromData(const Data : TArray<RSuperPointer<Cardinal>>; Format : EnumTextureFormat; const OriginalFilename : string);
begin
  assert(length(Data) >= 1);
  FData := Data;
  FFormat := Format;
  FWidth := Data[0].Width;
  FHeight := Data[0].Height;
  FMipLevels := length(Data);
  FOriginalFileHash := HFileIO.FileToMD5Hash(OriginalFilename);
  FOwnsData := False;
end;

constructor TEngineRawTexture.CreateFromMemoryStream(Filecontent : TMemoryStream);
var
  PreHeader : RPreHeader;
  Header : RHeader;
  MipLevelChunkHeader : RMipLevelChunkHeader;
  CompressedData : RSuperPointer<Cardinal>;
  i : integer;
begin
  FOwnsData := True;
  Filecontent.Read(PreHeader, SizeOf(RPreHeader));
  if not((PreHeader.Protector = HEADER_PROTECTOR) and (PreHeader.FileIdentifier = FILE_IDENTIFIER) and (PreHeader.Version = CURRENT_VERSION)) then
      raise EEngineRawTextureError.CreateFmt('TEngineRawTexture.CreateFromMemoryStream: Invalid fileformat. StreamSize: %d, StreamPosition: %d', [Filecontent.Size, Filecontent.Position]);
  Filecontent.Read(Header, SizeOf(RHeader));
  FWidth := Header.Width;
  FHeight := Header.Height;
  FFormat := Header.Format;
  FMipLevels := Header.MipLevels;
  FOriginalFileHash := string(Header.OriginalFileHash);
  setLength(FData, MipLevels);
  for i := 0 to MipLevels - 1 do
  begin
    Filecontent.Read(MipLevelChunkHeader, SizeOf(RMipLevelChunkHeader));
    if MipLevelChunkHeader.Protector <> CHUNK_PROTECTOR then
        raise EEngineRawTextureError.Create('TEngineRawTexture.CreateFromMemoryStream: Invalid chunk protector.');
    // compressed data needed to umcompressed before used
    if MipLevelChunkHeader.CompressedDataSize > 0 then
    begin
      CompressedData := RSuperPointer<Cardinal>.Create(Pointer(NativeUInt(Filecontent.Memory) + Filecontent.Position));
      FData[i] := RLEUncompressData(CompressedData, MipLevelChunkHeader.CompressedDataSize div SizeOf(Cardinal), MipLevelChunkHeader.Width, MipLevelChunkHeader.Height);
      Filecontent.Seek(MipLevelChunkHeader.CompressedDataSize, soCurrent);
    end
    else
    begin
      FData[i] := RSuperPointer<Cardinal>.Create2D(Pointer(NativeUInt(Filecontent.Memory) + Filecontent.Position), MipLevelChunkHeader.Width, MipLevelChunkHeader.Height);
      Filecontent.Seek(MipLevelChunkHeader.DataSize, soCurrent);
    end;
  end;
  assert(Filecontent.EoF);
end;

destructor TEngineRawTexture.Destroy;
var
  i : integer;
begin
  if FOwnsData then
  begin
    for i := 0 to length(FData) - 1 do
        FData[i].Free;
  end;
  inherited;
end;

constructor TEngineRawTexture.LoadHeaderFromFile(const FileName : string);
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
        raise EEngineRawTextureError.Create('TEngineRawTexture.CreateFromMemoryStream: Invalid fileformat.');
    Filecontent.Read(Header, SizeOf(RHeader));
    FWidth := Header.Width;
    FHeight := Header.Height;
    FFormat := Header.Format;
    FMipLevels := Header.MipLevels;
    FOriginalFileHash := string(Header.OriginalFileHash);
  finally
    Filecontent.Free;
  end;
end;

function TEngineRawTexture.RLECompressData(const Data : RSuperPointer<Cardinal>) : TArray<Cardinal>;
var
  i : integer;
  LastValue, CurrentValue, Counter, CompressedDataCount : Cardinal;
begin
  setLength(result, Data.Width * Data.Height);
  CompressedDataCount := 0;
  LastValue := Data.ReadValue(0);
  Counter := 1;
  for i := 1 to Data.Width * Data.Height - 1 do
  begin
    CurrentValue := Data.ReadValue(i);
    if (CurrentValue <> LastValue) then
    begin
      result[CompressedDataCount] := LastValue;
      result[CompressedDataCount + 1] := Counter;
      inc(CompressedDataCount, 2);
      LastValue := CurrentValue;
      Counter := 1;
    end
    else
        inc(Counter);
    // compression can increase size instead of reduce, so abort here if this happens
    if CompressedDataCount + 2 > Cardinal(length(result)) then
    begin
      result := nil;
      Exit;
    end;
  end;
  // finally write last read value into result, loop will not do it
  result[CompressedDataCount] := LastValue;
  result[CompressedDataCount + 1] := Counter;
  inc(CompressedDataCount, 2);
  // only apply compression if size is < 90%
  if Data.Width * Data.Height * 0.9 > CompressedDataCount then
      setLength(result, CompressedDataCount)
  else
      result := nil;
end;

function TEngineRawTexture.RLEUncompressData(const CompressedData : RSuperPointer<Cardinal>; CompressedDataCount, Width, Height : UInt32) : RSuperPointer<Cardinal>;
var
  i : UInt32;
  i2 : integer;
  Value, Counter : Cardinal;
  CompressedDataPointer, UncompressedDataPointer : PCardinal;
begin
  result := RSuperPointer<Cardinal>.CreateMem2D(Width, Height);
  assert(CompressedDataCount mod 2 = 0);
  i := 0;
  CompressedDataPointer := CompressedData.Memory;
  UncompressedDataPointer := result.Memory;
  while i < CompressedDataCount do
  begin
    Value := CompressedDataPointer^;
    inc(CompressedDataPointer);
    Counter := CompressedDataPointer^;
    inc(CompressedDataPointer);
    inc(i, 2);
    for i2 := 0 to Counter - 1 do
    begin
      UncompressedDataPointer^ := Value;
      inc(UncompressedDataPointer)
    end;
  end;
end;

procedure TEngineRawTexture.SaveToFile(const FileName : string);
var
  FileStream : TFileStream;
  PreHeader : RPreHeader;
  Header : RHeader;
  MipLevelChunkHeader : RMipLevelChunkHeader;
  CompressedData : TArray<Cardinal>;
  i : integer;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    PreHeader := RPreHeader.Create;
    FileStream.Write(PreHeader, SizeOf(RPreHeader));
    Header.Width := Width;
    Header.Height := Height;
    Header.Format := Format;
    Header.MipLevels := length(Data);
    Header.OriginalFileHash := ShortString(OriginalFileHash);
    FileStream.Write(Header, SizeOf(RHeader));
    for i := 0 to MipLevels - 1 do
    begin
      CompressedData := RLECompressData(Data[i]);
      MipLevelChunkHeader.Protector := TEngineRawTexture.CHUNK_PROTECTOR;
      MipLevelChunkHeader.Width := Data[i].Width;
      MipLevelChunkHeader.Height := Data[i].Height;
      MipLevelChunkHeader.DataSize := Data[i].DataSize;
      // will be 0, if data was not compressed
      MipLevelChunkHeader.CompressedDataSize := length(CompressedData) * SizeOf(Cardinal);
      FileStream.Write(MipLevelChunkHeader, SizeOf(RMipLevelChunkHeader));
      if CompressedData <> nil then
          FileStream.Write(CompressedData[0], MipLevelChunkHeader.CompressedDataSize)
      else
          FileStream.Write(Data[i].Memory^, Data[i].DataSize);
    end;
  finally
    FileStream.Free;
  end;
end;

{ TEngineRawTexture.RPreHeader }

class function TEngineRawTexture.RPreHeader.Create : RPreHeader;
begin
  result.FileIdentifier := TEngineRawTexture.FILE_IDENTIFIER;
  result.Protector := TEngineRawTexture.HEADER_PROTECTOR;
  result.Version := TEngineRawTexture.CURRENT_VERSION;
  result.HeaderLength := SizeOf(TEngineRawTexture.RHeader);
end;

end.

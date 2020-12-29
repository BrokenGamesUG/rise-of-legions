unit XFile.MSZip;

interface

uses
  SysUtils,
  Windows,
  Engine.Helferlein,
  Classes,
  zLib,
  Math;

type

  EMSZipBadDataFormat = class(Exception);

  TMSZipDecompressor = class
    procedure DecompressBuffer(OutputBuffer, InputBuffer : Pointer; InputLength : DWord; var OutputLength : DWord); virtual; abstract;
  end;

  TMSZipDecompressorUseZLib = class(TMSZipDecompressor)
    private const
      MSZIPSIGNATURE = ($4B shl 8) or $43; // A two-byte MSZIP signature consisting of the bytes 0x43, 0x4B
      CAB_BLOCKSIZE  = 32 * 1024;          // 32k for each block
      MAX_WBITS      = 15;                 // 15 32K LZ77 window
    private
      ZStream : z_stream;
      First : boolean;
    public
      constructor Create();
      procedure DecompressBuffer(OutputBuffer, InputBuffer : Pointer; InputLength : DWord; var OutputLength : DWord); override;
      destructor Destroy; override;
  end;

implementation

// ------------------------------------------------------------------------------

function MSZipAlloc(opaque : Pointer; Items, Size : Cardinal) : Pointer; cdecl;
begin
  result := AllocMem(Items * Size);
end;

procedure MSZipFree(opaque, address : Pointer); cdecl;
begin
  FreeMem(address);
end;

{ TMSZipDecompressor }

constructor TMSZipDecompressorUseZLib.Create;
begin
  ZStream.zalloc := MSZipAlloc;
  ZStream.zfree := MSZipFree;
  ZStream.opaque := nil;
  First := True;
end;

{$POINTERMATH ON}


procedure TMSZipDecompressorUseZLib.DecompressBuffer(OutputBuffer, InputBuffer : Pointer; InputLength : DWord; var OutputLength : DWord);
var
  Magic : Word;
  Status : Integer;
begin
  Magic := PWord(InputBuffer)^;
  if Magic <> MSZIPSIGNATURE then raise EMSZipBadDataFormat.Create('Fehlermeldung');
  ZStream.next_in := PByte(InputBuffer) + 2;
  ZStream.avail_in := InputLength - 2;
  ZStream.total_in := 0;
  ZStream.next_out := PByte(OutputBuffer);
  ZStream.avail_out := CAB_BLOCKSIZE;
  ZStream.total_out := 0;
  ZStream.data_type := Z_BINARY;
  (* WindowBits is passed < 0 to tell that there is no zlib header.
   * Note that in this case inflate *requires* an extra "dummy" byte
   * after the compressed stream in order to complete decompression and
   * return Z_STREAM_END.
  *)
  if First then
  begin
    Status := inflateInit2(ZStream, -MAX_WBITS);
    First := False;
    if (Status <> Z_OK) then
        raise EMSZipBadDataFormat.Create('TMSZipDecompressor.DecompressBuffer: inflateInit2 error.');
  end;

  while ((ZStream.total_out < CAB_BLOCKSIZE + 12) and (ZStream.total_in < InputLength - 2)) do
  begin

    Status := inflate(ZStream, Z_BLOCK);
    if (Status = Z_STREAM_END) then break;
    if Status <> Z_OK then
    begin
      if Status = Z_MEM_ERROR then raise EOutOfMemory.Create('TMSZipDecompressor.DecompressBuffer: Inflate mem_error.')
      else raise EMSZipBadDataFormat.Create('TMSZipDecompressor.DecompressBuffer: Inflate BadStream. ' + inttostr(Status));
    end;
  end;
  OutputLength := ZStream.total_out;

  Status := inflateReset(ZStream);
  if (Status <> Z_OK) then raise EMSZipBadDataFormat.Create('TMSZipDecompressor.DecompressBuffer: inflateReset error.');
  Status := inflateSetDictionary(ZStream, PByte(OutputBuffer), CAB_BLOCKSIZE - ZStream.avail_out);
  if (Status <> Z_OK) then raise EMSZipBadDataFormat.Create('TMSZipDecompressor.DecompressBuffer: inflateSetDictionary error.');
end;

{$POINTERMATH OFF}


destructor TMSZipDecompressorUseZLib.Destroy;
begin
  inflateEnd(ZStream);
  inherited;
end;

end.

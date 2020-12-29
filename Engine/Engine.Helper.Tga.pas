unit Engine.Helper.Tga;

// Maincode from the GLScene Project, http://glscene.org
// ReWritten by Martin
// TGA
//
// Simple TGA formats supports for Delphi.<br>
// Currently supports only 24 and 32 bits RGB formats (uncompressed
// and RLE compressed).
//
// Based on David McDuffee's document from www.wotsit.org
//
interface

uses
  Classes,
  SysUtils,
  Engine.GFXApi,
  Engine.GFXApi.Types,
  Engine.Helferlein;

type

  // TTGAImage
  //
  { : TGA image load/save capable class for Delphi.<p>
   TGA formats supported : 24 and 32 bits uncompressed or RLE compressed,
   saves only to uncompressed TGA. }
  TTGAImage = class
    private
      procedure SetHeight(const Value : Integer);
      procedure SetWidth(const Value : Integer);
      function GetPixel(x, y : Integer) : RColor;
      procedure SetPixel(x, y : Integer; const Value : RColor);
      procedure SetPixelFormat(const Value : EnumTextureFormat);
    protected
      FPixelFormat : EnumTextureFormat;
      FWidth : Integer;
      FHeight : Integer;
      FBitmap : array of Byte;
      procedure AdjustSize;
      function GetPixelSize : Integer;
    public
      property PixelFormat : EnumTextureFormat read FPixelFormat write SetPixelFormat;
      property Width : Integer read FWidth write SetWidth;
      property Height : Integer read FHeight write SetHeight;
      property Pixel[x : Integer; y : Integer] : RColor read GetPixel write SetPixel;
      procedure LoadFromStream(Stream : TStream);
      procedure SaveToStream(Stream : TStream);
      // ------------------------ default methods ----------------------------
      constructor Create;
      destructor Destroy; override;
  end;

  // ETGAException
  //
  ETGAException = class(Exception)
  end;

  // ------------------------------------------------------------------
  // ------------------------------------------------------------------
  // ------------------------------------------------------------------
implementation

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

type

  // TTGAHeader
  //
  TTGAHeader = packed record
    IDLength : Byte;
    ColorMapType : Byte;
    ImageType : Byte;
    ColorMapOrigin : Word;
    ColorMapLength : Word;
    ColorMapEntrySize : Byte;
    XOrigin : Word;
    YOrigin : Word;
    Width : Word;
    Height : Word;
    PixelSize : Byte;
    ImageDescriptor : Byte;
  end;

  // ReadAndUnPackRLETGA24
  //
procedure ReadAndUnPackRLETGA24(Stream : TStream; destBuf : PChar; totalSize : Integer);
type
  TRGB24 = packed record
    r, g, b : Byte;
  end;

  PRGB24 = ^TRGB24;
var
  n : Integer;
  color : TRGB24;
  bufEnd : PChar;
  b : Byte;
begin
  bufEnd := @destBuf[totalSize];
  while destBuf < bufEnd do
  begin
    Stream.Read(b, 1);
    if b >= 128 then
    begin
      // repetition packet
      Stream.Read(color, 3);
      b := (b and 127) + 1;
      while b > 0 do
      begin
        PRGB24(destBuf)^ := color;
        Inc(destBuf, 3);
        Dec(b);
      end;
    end
    else
    begin
      n := ((b and 127) + 1) * 3;
      Stream.Read(destBuf^, n);
      Inc(destBuf, n);
    end;
  end;
end;

// ReadAndUnPackRLETGA32
//
procedure ReadAndUnPackRLETGA32(Stream : TStream; destBuf : PChar; totalSize : Integer);
type
  TRGB32 = packed record
    r, g, b, a : Byte;
  end;

  PRGB32 = ^TRGB32;
var
  n : Integer;
  color : TRGB32;
  bufEnd : PChar;
  b : Byte;
begin
  bufEnd := @destBuf[totalSize];
  while destBuf < bufEnd do
  begin
    Stream.Read(b, 1);
    if b >= 128 then
    begin
      // repetition packet
      Stream.Read(color, 4);
      b := (b and 127) + 1;
      while b > 0 do
      begin
        PRGB32(destBuf)^ := color;
        Inc(destBuf, 4);
        Dec(b);
      end;
    end
    else
    begin
      n := ((b and 127) + 1) * 4;
      Stream.Read(destBuf^, n);
      Inc(destBuf, n);
    end;
  end;
end;

// ------------------
// ------------------ TTGAImage ------------------
// ------------------

// Create
//
procedure TTGAImage.AdjustSize;
begin
  assert(False, 'Not Implemented, bzw. compilerfehler den ich ausklammern musste.');
  // SetLength(FBitmap, Width, Height);
end;

constructor TTGAImage.Create;
begin
  inherited Create;
end;

// Destroy
//
destructor TTGAImage.Destroy;
begin
  inherited Destroy;
end;

function TTGAImage.GetPixel(x, y : Integer) : RColor;
begin
  raise ENotImplemented.Create('TTGAImage.GetPixelSize');
  // result := FBitmap[x, y];
end;

function TTGAImage.GetPixelSize : Integer;
begin
  raise ENotImplemented.Create('TTGAImage.GetPixelSize');
  // case PixelFormat of
  // else raise ENotSupportedException.Create('Fehlermeldung');
  // end;
end;

// LoadFromStream
//
procedure TTGAImage.LoadFromStream(Stream : TStream);
var
  header : TTGAHeader;
  x, y, rowSize, bufSize : Integer;
  verticalFlip : Boolean;
  unpackBuf : PChar;
  Pixel : Cardinal;
begin
  Stream.Read(header, Sizeof(TTGAHeader));

  if header.ColorMapType <> 0 then
      raise ETGAException.Create('ColorMapped TGA unsupported');

  case header.PixelSize of
    24 : PixelFormat := tfR8G8B8;
    32 : PixelFormat := tfA8R8G8B8;
  else
    raise ETGAException.Create('Unsupported TGA ImageType');
  end;

  Width := header.Width;
  Height := header.Height;
  verticalFlip := ((header.ImageDescriptor and $20) = 0);
  if header.IDLength > 0 then
      Stream.Seek(header.IDLength, soFromCurrent);

  case header.ImageType of
    0 :
      begin // empty image, support is useless but easy ;)
        Width := 0;
        Height := 0;
        Exit;
      end;
    2 :
      begin // uncompressed RGB/RGBA
        if verticalFlip then
        begin
          for y := 0 to Height - 1 do
            for x := 0 to Width - 1 do
            begin
              Stream.Read(Pixel, header.PixelSize div 8);
              assert(False, 'Not Implemented, bzw. compilerfehler den ich ausklammern musste.');
              // case header.PixelSize of
              // // add empty alphachannel
              // 24 : FBitmap[x, Height - y - 1] := (Pixel shr 8) or $FF000000;
              // 32 : FBitmap[x, Height - y - 1] := Pixel;
              // end;
            end;
        end
        else
        begin
          for y := 0 to Height - 1 do
            for x := 0 to Width - 1 do
            begin
              Stream.Read(Pixel, header.PixelSize div 8);
              assert(False, 'Not Implemented, bzw. compilerfehler den ich ausklammern musste.');
              // case header.PixelSize of
              // // add empty alphachannel
              // 24 : FBitmap[x, y] := (Pixel shr 8) or $FF000000;
              // 32 : FBitmap[x, y] := Pixel;
              // end;
            end;
        end;
      end;
    10 :
      begin // RLE encoded RGB/RGBA
        raise Exception.Create('Not Suppoted');
        bufSize := Height * rowSize;
        unpackBuf := GetMemory(bufSize);
        try
          // read & unpack everything
          if header.PixelSize = 24 then
              ReadAndUnPackRLETGA24(Stream, unpackBuf, bufSize)
          else ReadAndUnPackRLETGA32(Stream, unpackBuf, bufSize);
          // fillup bitmap
          if verticalFlip then
          begin
            // Bug with Lazarus k00m
            { for y:=0 to Height-1 do begin
             Move(unPackBuf[y*rowSize], ScanLine[Height-y-1]^, rowSize);
             end; }
          end
          else
          begin
            // Bug with Lazarus k00m
            { for y:=0 to Height-1 do
             Move(unPackBuf[y*rowSize], ScanLine[y]^, rowSize); }
          end;
        finally
          FreeMemory(unpackBuf);
        end;
      end;
  else
    raise ETGAException.Create('Unsupported TGA ImageType ' + IntToStr(header.ImageType));
  end;
end;

// TTGAImage
//
procedure TTGAImage.SaveToStream(Stream : TStream);
var
  y : Integer;
  header : TTGAHeader;
  x : Integer;
  Pixel : Cardinal;
begin
  // prepare the header, essentially made up from zeroes
  FillChar(header, Sizeof(TTGAHeader), 0);
  header.ImageType := 2;
  header.Width := Width;
  header.Height := Height;
  case PixelFormat of
    {$IFDEF MSWINDOWS}
    tfR8G8B8 : header.PixelSize := 24;
    {$ENDIF}
    tfA8R8G8B8 : header.PixelSize := 32;
  else
    raise ETGAException.Create('Unsupported Bitmap format');
  end;
  Stream.Write(header, Sizeof(TTGAHeader));
  for y := 0 to Height - 1 do
    for x := 0 to Width - 1 do
    begin
      assert(False, 'Not Implemented, bzw. compilerfehler den ich ausklammern musste.');
      // Pixel := FBitmap[x, y].color shl (32 - header.PixelSize);
      // save according to dataformat first 24 or 32 bits
      Stream.Write(Pixel, header.PixelSize div 8);
    end;
end;

procedure TTGAImage.SetHeight(const Value : Integer);
begin
  FHeight := Value;
end;

procedure TTGAImage.SetPixel(x, y : Integer; const Value : RColor);
begin
  assert(False, 'Not Implemented, bzw. compilerfehler den ich ausklammern musste.');
  // FBitmap[x, y] := Value;
end;

procedure TTGAImage.SetPixelFormat(const Value : EnumTextureFormat);
begin
  assert(False, 'Not Implemented, bzw. compilerfehler den ich ausklammern musste.');
  // if not Value in [tfR8G8B8, tfA8R8G8B8] then
  // raise ENotSupportedException.Create('TgaImage currently does not support format "' + HRtti.EnumerationToString<EnumTextureFormat>(Value) + '".');
  // FPixelFormat := Value;
end;

procedure TTGAImage.SetWidth(const Value : Integer);
begin
  FWidth := Value;
end;

end.

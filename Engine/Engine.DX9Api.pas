unit Engine.DX9Api;

interface

uses
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Helper.Tga,
  d3dx9,
  d3d9,
  WinApi.Windows,
  Engine.Log,
  Generics.Collections,
  Engine.Math,
  System.SysUtils,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  ImagingDirect3D9,
  Types,
  Engine.Math.Collision2D,
  Math,
  Classes,
  RegularExpressions;

type

  TDirectX9Device = class(TDevice)
    protected
      FDevice : IDirect3DDevice9;
      FGFX : IDirect3D9;
      FSettings : TDeviceSettings;
      FPresentParameters : TD3DPresentParameters;
      class function iCreateDevice(Handle : HWND; Settings : TDeviceSettings) : TDevice; override;
      procedure SetRendertargets(Targets : array of TRendertarget); override;
      procedure BuildPresentParameters;
      /// <summary> Map a predefined engine value to api value.</summary>
      function MapRenderStateValueEngineToApi(Renderstate : EnumRenderstate; Value : Cardinal) : Cardinal;
      /// <summary> Map a api value to predefined engine value.</summary>
      function MapRenderStateValueApiToEngine(Renderstate : EnumRenderstate; Value : Cardinal) : Cardinal;
      procedure ApplySamplerStates;
    public
      procedure SetRealRenderState(Renderstate : EnumRenderstate; Value : Cardinal); override;
      function GetRealRenderState(Renderstate : EnumRenderstate) : Cardinal; override;
      procedure Clear(Flags : SetClearFlags; Color : RColor; z : Single; Stencil : DWord); override;
      procedure SetStreamSource(StreamNumber : longword; pStreamData : TVertexBuffer; OffsetInBytes, Stride : longword); override;
      procedure SetIndices(Indices : TIndexBuffer); override;
      procedure SetVertexDeclaration(vertexdeclaration : TVertexDeclaration); override;
      function GetMaxMRT : byte; override;
      procedure DrawPrimitive(PrimitiveType : EnumPrimitveType; StartIndex, PrimitiveCount : Cardinal); override;
      procedure DrawIndexedPrimitive(PrimitiveType : EnumPrimitveType; BaseVertexIndex : integer; MinVertexIndex, NumVertices, StartIndex, primCount : Cardinal); override;
      function GetRendertarget(Index : integer) : TRendertarget;
      procedure SetViewport(Width, Height : Cardinal); override;
      procedure SetDepthStencilBuffer(Depthbuffer : TDepthStencilBuffer);
      function GetDepthStencilBuffer() : TDepthStencilBuffer;
      procedure ChangeResolution(const NewResolution : RIntVector2); override;
      function CreateDepthStencilBuffer(Width, Height : Cardinal) : TDepthStencilBuffer; override;
      procedure BeginScene; override;
      procedure EndScene; override;
      procedure Present(SourceRect, DestRect : PRect; WindowOverride : HWND); override;
      procedure SaveScreenshotToFile(FileName : string); override;
      destructor Destroy; override;
  end;

  /// <summary> A Shadereffect (Vertexshader+Pixelshader) </summary>
  TDirectX9Shader = class(TShader)
    protected
      Shader : ID3DXEffect;
      Values : TDictionary<string, TD3DXHandle>;
      constructor Create(Device : TDevice);
      /// <summary> Creates a Shader from an string with the given GFXD </summary>
      class function iCreateShader(Device : TDevice) : TShader; override;
      /// <summary> Get the handle, theoretically faster than DirectX </summary>
      function GetHandle(Constant : string) : TD3DXHandle;
      procedure CompileShader(shaderstr : AnsiString); override;
      procedure SetRealBoolean(const ConstantName : string; bool : boolean); override;
      procedure SetRealShaderConstant(const ConstantName : string; Value : Pointer; Size : integer); override;
      procedure SetRealBoolean(const ConstantName : EnumDefaultShaderConstant; bool : boolean); overload; override;
      procedure SetRealShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : integer); overload; override;
      /// <summary> Set the used technique </summary>
      procedure SetShaderTechnique(Technique : string);
    public
      /// <summary> Commit all constant changes within the ShaderBegin and End-Block </summary>
      procedure CommitChanges(); override;
      /// <summary> Sets a texture</summary>
      procedure SetRealTexture(const Slot : EnumTextureSlot; Textur : TTexture; ShaderTarget : EnumShaderType); override;
      /// <summary> Activates a shader. Must be called before rendering the geometry. </summary>
      procedure ShaderBegin; override;
      /// <summary> Deactivates a shader. Must be called after rendering the geometry. </summary>
      procedure ShaderEnd; override;
      destructor Destroy; override;
  end;

  TDirectX9VertexBuffer = class(TVertexBuffer)
    protected
      FVertexBuffer : IDirect3DVertexBuffer9;
      FUsage : SetUsage;
      FPool : TD3DPool;
      class function iCreateVertexBuffer(Length : Cardinal; Usage : SetUsage; Device : TDevice; InitialData : Pointer) : TVertexBuffer; override;
    public
      property VertexBuffer : IDirect3DVertexBuffer9 read FVertexBuffer;
      function LowLock(LockFlags : SetLockFlags = [lfDiscard]) : Pointer; override;
      procedure Lock(); override;
      procedure Unlock; override;
      destructor Destroy; override;
  end;

  TDirectX9IndexBuffer = class(TIndexBuffer)
    protected
      FIndexBuffer : IDirect3DIndexBuffer9;
      FUsage : SetUsage;
      class function iCreateIndexBuffer(Length : longword; Usage : SetUsage; Format : EnumIndexBufferFormat; Device : TDevice; InitialData : Pointer) : TIndexBuffer; override;
    public
      function LowLock(LockFlags : SetLockFlags = [lfDiscard]) : Pointer; override;
      procedure Lock(); override;
      procedure Unlock; override;
      destructor Destroy; override;
  end;

  TDirectX9VertexDeclaration = class(TVertexDeclaration)
    protected
      FVertexDeclaration : IDirect3DVertexDeclaration9;
      Elem : array of TD3DVertexElement9;
      class function iCreateVertexDeclaration(Device : TDevice) : TVertexDeclaration; override;
      function getState : boolean;
      constructor Create(Device : TDevice);
    public
      property vertexdeclaration : IDirect3DVertexDeclaration9 read FVertexDeclaration;
      property Finished : boolean read getState;
      procedure AddVertexElement(elemtype : EnumVertexElementType; Usage : EnumVertexElementUsage; Method : EnumVertexElementMethod = emDefault; StreamID : word = 0; UsageIndex : word = 0); override;
      procedure EndDeclaration; override;
      destructor Destroy; override;
  end;

  TDirectX9Surface = class
    private
      FDirect3DSurface9 : IDirect3DSurface9;
    public
      property Direct3DSurface9 : IDirect3DSurface9 read FDirect3DSurface9;
      constructor Create(Direct3DSurface9 : IDirect3DSurface9);
      destructor Destroy; override;
  end;

  TDirectX9Textur = class(TTexture)
    protected
      FDirect3DTexture9 : IDirect3DTexture9;
      class function iCreateTexture(const Width, Height, MipLevels : Cardinal; Usage : SetUsage; Format : EnumTextureFormat; Device : TDevice) : TTexture; override;
      class function iCreateTextureFromFile(FilePath : string; Device : TDevice; FailSilently : boolean; MipmapHandling : EnumMipMapHandling = mhGenerate; ResizeToPow2 : boolean = true) : TTexture; override;
      procedure LoadTextureFromMemoryStream(const FilePath : string; const Filecontent : TMemoryStream); override;
      function GetSurfaceLevel(Level : longword) : TDirectX9Surface;
      procedure _Resize(newWidth, newHeight : Cardinal; DisableMipLevels : boolean);
    public
      property Direct3DTexture9 : IDirect3DTexture9 read FDirect3DTexture9;
      procedure Resize(newWidth, newHeight : integer); override;
      procedure DisableMipLevels; override;
      procedure Lock; override;
      procedure MakeLockable; override;
      function LowLock(rect : PRect) : Pointer; override;
      procedure SaveToFile(FileName : string; FileFormat : EnumTextureFileType = tfTGA); override;
      function FastCopyAvailable : boolean; override;
      procedure FastCopy(Target : TTexture); override;
      procedure Unlock; override;
      destructor Destroy; override;
  end;

  TDirectX9Rendertarget = class(TRendertarget)
    protected
      FSurface : TDirectX9Surface;
      procedure InitializeTarget(Target : TTexture); override;
      constructor CreateRaw(Device : TDevice; Target : TDirectX9Surface; Width, Height : Cardinal);
    public
      destructor Destroy; override;
  end;

  TDirectX9DepthStencilbuffer = class(TDepthStencilBuffer)
    protected
      FSurface : TDirectX9Surface;
    public
      constructor Create(Surface : TDirectX9Surface); overload;
      class function CreateDepthStencilBuffer(Device : TDevice; Width, Height : Cardinal) : TDepthStencilBuffer; overload; override;
      destructor Destroy; override;
  end;

  { Commented out because there ist no TAnimatedMeshDataX in Engine.Core
   /// <summary> Class that use for loading and rendering Meshes from XFiles with animation.
   /// This implementation is not final and dirty, because its only pool the file not the meshdata!!!!</summary>
   TDirectXAnimatedMeshDataX = class(TGFXDManagedObject<TDirectXAnimatedMeshDataX>)
   protected
   FMeshDataFile : array of Byte;
   FAnimController : ID3DXAnimationController;
   FFrameHierarchy : PD3DXFrame;
   function GetCopy : TDirectXAnimatedMeshDataX; override;
   public
   class function LoadAnimatedMeshFromFile(FileName : string; MeshOptions : DWord; Device : TDevice; pAlloc : ID3DXAllocateHierarchy;
   out ppFrameHierarchy : PD3DXFrame; out ppAnimController : ID3DXAnimationController) : HResult;
   destructor Destroy; override;
   end; }

function RVector3ToTD3DXVector3(vec : RVector3) : TD3DXVector3;
function TD3DXVector3ToRVector3(vec : TD3DXVector3) : RVector3;
function RMatrixToTD3DXMatrix(a : RMatrix) : TD3DXMatrix;
function TD3DXMatrixToRMatrix(a : TD3DXMatrix) : RMatrix;
function RVector2ToTD3DXVector2(a : RVector2) : TD3DXVector2;
function TD3DXVector2ToRVector2(a : TD3DXVector2) : RVector2;
function RVector4ToTD3DXVector4(a : RVector4) : TD3DXVector4;
function TD3DXVector4ToRVector4(a : TD3DXVector4) : RVector4;

implementation

procedure ProcessShaderErrors(shaderstr : AnsiString; errors : ID3DXBuffer);
type
  TCharArray = array of AnsiChar;
var
  CharArray : TCharArray;
  str : string;
begin
  if assigned(errors) then
  begin
    assert(SizeOf(AnsiChar) = 1);
    setlength(CharArray, errors.GetBufferSize);
    CopyMemory(@CharArray[0], errors.GetBufferPointer, errors.GetBufferSize);
    str := HString.AnsiCharArrayToString(CharArray);
    HLog.Log(str + sLineBreak + string(shaderstr));
    raise Exception.Create('Shader couldn''t be created! Errors:' + #10#13 + string(str));
  end;
end;

function RVector3ToTD3DXVector3(vec : RVector3) : TD3DXVector3;
begin
  Result := PD3DXVector3(@vec)^;
end;

function TD3DXVector3ToRVector3(vec : TD3DXVector3) : RVector3;
begin
  Result := PRVector3(@vec)^;
end;

function RMatrixToTD3DXMatrix(a : RMatrix) : TD3DXMatrix;
begin
  Result := PD3DXMatrix(@a)^;
end;

function TD3DXMatrixToRMatrix(a : TD3DXMatrix) : RMatrix;
begin
  Result := PMatrix(@a)^;
end;

function RVector2ToTD3DXVector2(a : RVector2) : TD3DXVector2;
begin
  Result := PD3DXVector2(@a)^;
end;

function TD3DXVector2ToRVector2(a : TD3DXVector2) : RVector2;
begin
  Result := PRVector2(@a)^;
end;

function RVector4ToTD3DXVector4(a : RVector4) : TD3DXVector4;
begin
  Result := PD3DXVector4(@a)^;
end;

function TD3DXVector4ToRVector4(a : TD3DXVector4) : RVector4;
begin
  Result := PRVector4(@a)^;
end;

{ function RColorToRColorValue(a : RColor) : RColorValue;
 begin
 Result.a := (a.Alpha / 255);
 Result.R := (a.Red / 255);
 Result.g := (a.Green / 255);
 Result.b := (a.Blue / 255);
 end;

 function RColorToTColorArray(a : RColor) : TColorArray;
 begin
 Result[0] := (a.Red / 255);
 Result[1] := (a.Green / 255);
 Result[2] := (a.Blue / 255);
 Result[3] := (a.Alpha / 255);
 end; }

function ClearFlagsToCardinal(Flags : SetClearFlags) : Cardinal;
begin
  Result := 0;
  if EnumClearFlags.cfTarget in Flags then Result := Result or D3DCLEAR_TARGET;
  if EnumClearFlags.cfZBuffer in Flags then Result := Result or D3DCLEAR_ZBUFFER;
  if EnumClearFlags.cfStencil in Flags then Result := Result or D3DCLEAR_STENCIL;
end;

function LockFlagsToCardinal(Flags : SetLockFlags) : Cardinal;
begin
  Result := 0;
  if EnumLockFlag.lfReadOnly in Flags then Result := Result or D3DLOCK_READONLY;
  if EnumLockFlag.lfDiscard in Flags then Result := Result or D3DLOCK_DISCARD;
  if EnumLockFlag.lfNoOverwrite in Flags then Result := Result or D3DLOCK_NOOVERWRITE;
end;

function UsageToCardinal(Flags : SetUsage) : Cardinal;
begin
  Result := 0;
  if EnumUsage.usRendertarget in Flags then exit(D3DUSAGE_RENDERTARGET);
  if EnumUsage.usFrequentlyWriteable in Flags then Result := Result or D3DUSAGE_DYNAMIC;
  if not(EnumUsage.usReadable in Flags) and ([usWriteable, usFrequentlyWriteable] * Flags <> []) then Result := Result or D3DUSAGE_WRITEONLY;
end;

{ TDirectX9Shader }

procedure TDirectX9Shader.SetRealBoolean(const ConstantName : string; bool : boolean);
var
  Handle : TD3DXHandle;
begin
  Handle := GetHandle(ConstantName);
  if Handle <> nil then
  begin
    HLog.CheckDX9Error(Shader.SetBool(Handle, bool), 'SetShaderConstant error: ' + ConstantName);
  end;
end;

procedure TDirectX9Shader.SetRealShaderConstant(const ConstantName : string; Value : Pointer; Size : integer);
var
  Handle : TD3DXHandle;
  mat : RMatrix;
begin
  assert(Value <> nil);
  Handle := GetHandle(ConstantName);
  if Handle <> nil then
  begin
    if Size = SizeOf(RMatrix) then
    begin
      mat := PMatrix(Value)^;
      mat := mat.Transpose;
      Value := @mat;
    end;
    HLog.CheckDX9Error(Shader.SetValue(Handle, Value, Size), 'SetShaderConstant error: ' + ConstantName);
  end;
end;

procedure TDirectX9Shader.SetShaderTechnique(Technique : string);
begin
  if FBlockingChanges = sbNone then HLog.CheckDX9Error(Shader.SetTechnique(Shader.GetTechniqueByName(PAnsiChar(AnsiString(Technique)))), 'SetShaderTechnique: ' + Technique);
end;

procedure TDirectX9Shader.CommitChanges;
begin
  HLog.CheckDX9Error(Shader.CommitChanges, 'TDirectX9Shader.CommitChanges');
end;

procedure TDirectX9Shader.CompileShader(shaderstr : AnsiString);
var
  Buffer : ID3DXBuffer;

  procedure SanitizeShader;
  var
    temp : string;
  begin
    temp := string(shaderstr);
    temp := '#define DX9' + sLineBreak + temp;
    // remove cbuffers from the file
    temp := TRegex.SubstituteDirect(temp, 'cbuffer.*?{(.*?)};', '\1', nil, [roSingleLine, roIgnoreCase]);
    shaderstr := AnsiString(temp);
  end;

begin
  SanitizeShader;

  Values.Clear;
  Shader := nil;
  HLog.CheckDX9Error(D3DXCreateEffect(TDirectX9Device(FDevice).FDevice, @AnsiString(shaderstr)[1], Length(AnsiString(shaderstr)), nil, nil, 0, nil, Shader, @Buffer), 'Shadererstellung aus String fehlgeschlagen.');
  if (Buffer = nil) or assigned(Shader) then exit;
  ProcessShaderErrors(shaderstr, Buffer);
end;

constructor TDirectX9Shader.Create(Device : TDevice);
begin
  inherited Create(Device);
  Values := TDictionary<string, TD3DXHandle>.Create;
end;

class function TDirectX9Shader.iCreateShader(Device : TDevice) : TShader;
begin
  Result := Create(Device);
end;

destructor TDirectX9Shader.Destroy;
begin
  if CanDestroyed then
  begin
    inherited;
    Values.Free;
    Shader := nil;
  end;
end;

procedure TDirectX9Shader.SetRealTexture(const Slot : EnumTextureSlot; Textur : TTexture; ShaderTarget : EnumShaderType);
var
  Handle : TD3DXHandle;
begin
  Handle := GetHandle(TEXTURE_SLOT_MAPPING[Slot]);
  if Handle <> nil then
  begin
    if Textur = nil then HLog.CheckDX9Error(Shader.SetTexture(Handle, nil), 'TDirectX9Shader.SetTexture nil')
    else HLog.CheckDX9Error(Shader.SetTexture(Handle, TDirectX9Textur(Textur).Direct3DTexture9), 'TDirectX9Shader.SetTexture');
  end;
end;

procedure TDirectX9Shader.ShaderBegin;
var
  c : Cardinal;
begin
  SetShaderTechnique(DEFAULT_TECHNIQUE_NAME);
  HLog.CheckDX9Error(Shader._Begin(@c, 0), 'TDirectX9Shader.ShaderBegin _Begin');
  HLog.CheckDX9Error(Shader.BeginPass(0), 'TDirectX9Shader.ShaderBegin BeginPass');
end;

procedure TDirectX9Shader.ShaderEnd;
begin
  HLog.CheckDX9Error(Shader.EndPass, 'TDirectX9Shader.ShaderEnd EndPass');
  HLog.CheckDX9Error(Shader._End, 'TDirectX9Shader.ShaderEnd _End');
end;

function TDirectX9Shader.GetHandle(Constant : string) : TD3DXHandle;
begin
  if not Values.TryGetValue(Constant, Result) then
  begin
    Result := Shader.GetParameterByName(nil, PAnsiChar(AnsiString(Constant)));
    Values.Add(Constant, Result);
  end;
end;

procedure TDirectX9Shader.SetRealBoolean(const ConstantName : EnumDefaultShaderConstant; bool : boolean);
begin
  SetRealBoolean(DEFAULT_SHADER_CONSTANT_MAPPING[ConstantName], bool);
end;

procedure TDirectX9Shader.SetRealShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : integer);
begin
  SetRealShaderConstant(DEFAULT_SHADER_CONSTANT_MAPPING[ConstantName], Value, Size);
end;

{ TDirectX9VertexBuffer }

destructor TDirectX9VertexBuffer.Destroy;
begin
  if CanDestroyed then
  begin
    FVertexBuffer := nil;
    inherited;
  end;
end;

class function TDirectX9VertexBuffer.iCreateVertexBuffer(Length : Cardinal; Usage : SetUsage; Device : TDevice; InitialData : Pointer) : TVertexBuffer;
var
  DXVb : TDirectX9VertexBuffer;
begin
  if assigned(InitialData) then
      raise ENotImplemented.Create('TDirectX9IndexBuffer.iCreateIndexBuffer: InitialData not implemented!');
  DXVb := TDirectX9VertexBuffer.Create(Device);
  DXVb.FUsage := Usage;
  if usFrequentlyWriteable in Usage then DXVb.FPool := TD3DPool.D3DPOOL_DEFAULT
  else DXVb.FPool := TD3DPool.D3DPOOL_MANAGED;
  Result := DXVb;
  DXVb.FSize := Length;
  HLog.CheckDX9Error(TDirectX9Device(Device).FDevice.CreateVertexBuffer(DXVb.FSize, UsageToCardinal(DXVb.FUsage), 0, DXVb.FPool, DXVb.FVertexBuffer, nil), 'TDirectX9VertexBuffer.iCreateVertexBuffer: Error occurs on create vertexbuffer.');
end;

procedure TDirectX9VertexBuffer.Lock();
begin
  LowLock();
  inherited;
end;

function TDirectX9VertexBuffer.LowLock(LockFlags : SetLockFlags) : Pointer;
begin
  if not(usFrequentlyWriteable in FUsage) then LockFlags := LockFlags - [lfDiscard, lfNoOverwrite];
  HLog.CheckDX9Error(VertexBuffer.Lock(0, 0, FLocked, LockFlagsToCardinal(LockFlags)), 'TDirectX9VertexBuffer.LowLock');
  Result := FLocked;
end;

procedure TDirectX9VertexBuffer.Unlock;
begin
  inherited;
  HLog.CheckDX9Error(VertexBuffer.Unlock, 'TDirectX9VertexBuffer.Unlock');
end;

{ TDirectX9IndexBuffer }

destructor TDirectX9IndexBuffer.Destroy;
begin
  if CanDestroyed then
  begin
    FIndexBuffer := nil;
    inherited;
  end
end;

class function TDirectX9IndexBuffer.iCreateIndexBuffer(Length : longword; Usage : SetUsage;
  Format : EnumIndexBufferFormat; Device : TDevice; InitialData : Pointer) : TIndexBuffer;
var
  pool : TD3DPool;
begin
  if assigned(InitialData) then
      raise ENotImplemented.Create('TDirectX9IndexBuffer.iCreateIndexBuffer: InitialData not implemented!');
  Result := TDirectX9IndexBuffer.Create(Device);
  TDirectX9IndexBuffer(Result).FUsage := Usage;
  if usFrequentlyWriteable in Usage then pool := TD3DPool.D3DPOOL_DEFAULT
  else pool := TD3DPool.D3DPOOL_MANAGED;
  HLog.CheckDX9Error(TDirectX9Device(Device).FDevice.CreateIndexBuffer(Length, UsageToCardinal(Usage), D3DFORMAT(Format), pool, TDirectX9IndexBuffer(Result).FIndexBuffer, nil), 'TDirectX9IndexBuffer.iCreateIndexBuffer');
  TDirectX9IndexBuffer(Result).FSize := Length;
end;

procedure TDirectX9IndexBuffer.Lock();
begin
  LowLock();
  inherited;
end;

function TDirectX9IndexBuffer.LowLock(LockFlags : SetLockFlags) : Pointer;
begin
  if not(usFrequentlyWriteable in FUsage) then LockFlags := LockFlags - [lfDiscard, lfNoOverwrite];
  HLog.CheckDX9Error(FIndexBuffer.Lock(0, 0, FLocked, LockFlagsToCardinal(LockFlags)), 'TDirectX9IndexBuffer.LowLock');
  Result := FLocked;
end;

procedure TDirectX9IndexBuffer.Unlock;
begin
  HLog.CheckDX9Error(FIndexBuffer.Unlock, 'TDirectX9IndexBuffer.Unlock');
  FLocked := nil;
end;

{ TDirectX9VertexDeclaration }

procedure TDirectX9VertexDeclaration.AddVertexElement(
  elemtype : EnumVertexElementType; Usage : EnumVertexElementUsage;
  Method : EnumVertexElementMethod; StreamID, UsageIndex : word);
var
  i, offset : integer;
begin
  if Finished then exit;
  inherited;
  setlength(Elem, Length(Elem) + 1);
  i := high(Elem);
  Elem[i].Stream := StreamID;
  Elem[i].UsageIndex := UsageIndex;
  case elemtype of
    etFloat1 : Elem[i]._Type := D3DDECLTYPE_FLOAT1;
    etFloat2 : Elem[i]._Type := D3DDECLTYPE_FLOAT2;
    etFloat3 : Elem[i]._Type := D3DDECLTYPE_FLOAT3;
    etFloat4 : Elem[i]._Type := D3DDECLTYPE_FLOAT4;
    etUnused : Elem[i]._Type := D3DDECLTYPE_UNUSED;
  end;
  case Usage of
    euPosition : Elem[i].Usage := D3DDECLUSAGE_POSITION;
    euNormal : Elem[i].Usage := D3DDECLUSAGE_NORMAL;
    euColor : Elem[i].Usage := D3DDECLUSAGE_COLOR;
    euTexturecoordinate : Elem[i].Usage := D3DDECLUSAGE_TEXCOORD;
    euTangent : Elem[i].Usage := D3DDECLUSAGE_TANGENT;
    euBinormal : Elem[i].Usage := D3DDECLUSAGE_BINORMAL;
    euBlendWeight : Elem[i].Usage := D3DDECLUSAGE_BLENDWEIGHT;
    euBlendIndices : Elem[i].Usage := D3DDECLUSAGE_BLENDINDICES;
  end;
  case Method of
    emDefault : Elem[i].Method := D3DDECLMETHOD_DEFAULT;
  end;
  if (i = 0) or (elemtype = etUnused) then offset := 0
  else
  begin
    offset := Elem[i - 1].offset;
    case Elem[i - 1]._Type of
      D3DDECLTYPE_FLOAT1 : inc(offset, 4);
      D3DDECLTYPE_FLOAT2 : inc(offset, 8);
      D3DDECLTYPE_FLOAT3 : inc(offset, 12);
      D3DDECLTYPE_FLOAT4 : inc(offset, 16);
      D3DDECLTYPE_D3DCOLOR : inc(offset, 4);
      D3DDECLTYPE_UNUSED : offset := 0;
    end;
  end;
  Elem[i].offset := offset;
end;

constructor TDirectX9VertexDeclaration.Create(Device : TDevice);
begin
  inherited Create(Device);
end;

destructor TDirectX9VertexDeclaration.Destroy;
begin
  if CanDestroyed then
  begin
    FVertexDeclaration := nil;
    inherited;
  end;
end;

procedure TDirectX9VertexDeclaration.EndDeclaration;
begin
  if Finished then exit;
  AddVertexElement(EnumVertexElementType.etUnused, euPosition, emDefault, $FF, 0);
  HLog.CheckDX9Error(TDirectX9Device(FDevice).FDevice.CreateVertexDeclaration(@Elem[0], FVertexDeclaration), 'TDirectX9VertexDeclaration.EndDeclaration: VertexDeclaration couldn''t be created');
end;

function TDirectX9VertexDeclaration.getState :
  boolean;
begin
  Result := FVertexDeclaration <> nil;
end;

class function TDirectX9VertexDeclaration.iCreateVertexDeclaration(Device : TDevice) : TVertexDeclaration;
begin
  Result := TDirectX9VertexDeclaration.Create(Device);
end;

{ TDirectX9Textur }

destructor TDirectX9Textur.Destroy;
begin
  if CanDestroyed then
  begin
    inherited;
    FDirect3DTexture9 := nil;
  end;
end;

procedure TDirectX9Textur.DisableMipLevels;
begin
  if FMipLevels <> 1 then
  begin
    _Resize(FWidth, FHeight, true);
    FMipLevels := 1;
  end;
end;

procedure TDirectX9Textur.FastCopy(Target : TTexture);
begin
  assert(False, 'TDirectX9Textur.FastCopy: Fast copy is not availabe under DX9, did miss you checked FastCopyAvailable?');
end;

function TDirectX9Textur.FastCopyAvailable : boolean;
begin
  Result := False;
end;

function TDirectX9Textur.GetSurfaceLevel(Level : longword) : TDirectX9Surface;
var
  Surface : IDirect3DSurface9;
begin
  HLog.CheckDX9Error(Direct3DTexture9.GetSurfaceLevel(Level, Surface), 'TDirectX9Textur.GetSurfaceLevel');
  Result := TDirectX9Surface.Create(Surface);
end;

class function TDirectX9Textur.iCreateTexture(const Width, Height, MipLevels : Cardinal; Usage : SetUsage;
  Format : EnumTextureFormat; Device : TDevice) : TTexture;
var
  cwidth, cheight, cmip, cusage : Cardinal;
  cformat : TD3DFormat;
  cpool : TD3DPool;
begin
  Result := TDirectX9Textur.Create(Device);
  TDirectX9Textur(Result).FWidth := Width;
  TDirectX9Textur(Result).FHeight := Height;
  TDirectX9Textur(Result).FFormat := Format;
  TDirectX9Textur(Result).FUsage := Usage;
  TDirectX9Textur(Result).FMipLevels := MipLevels;
  cwidth := Width;
  cheight := Height;
  cmip := MipLevels;
  assert(not(usFrequentlyWriteable in Usage), 'Tobi need to implement this!');
  assert(not(usRendertarget in Usage) or (Usage = [usRendertarget]), 'TDirectX9Textur.iCreateTexture: Rendertargets aren''t lockable!');
  // texture doesn't support writeonly so remove it
  cusage := UsageToCardinal(Usage - [usWriteable]);
  cformat := D3DFORMAT(Format);
  if Usage * [usReadable, usWriteable, usFrequentlyWriteable] = [] then cpool := TD3DPool.D3DPOOL_DEFAULT
  else cpool := TD3DPool.D3DPOOL_MANAGED;
  HLog.CheckDX9Error(D3DXCheckTextureRequirements(TDirectX9Device(Device).FDevice, @cwidth, @cheight, @cmip, cusage, @cformat, cpool), 'TDirectX9Textur.iCreateTexture Check failed.');
  if (cwidth <> Width) or (cheight <> Height) or (cmip <> MipLevels) or (cformat <> D3DFORMAT(Format)) then
  begin
    HLog.Log(System.SysUtils.Format('Specified texture can not be made, (want,dx-suggestion): width(%d/%d) height(%d/%d) miplevels(%d/%d) format(%d/%d) pool(%s) usage(%s)',
      [Width, cwidth, Height, cheight, MipLevels, cmip,
      ord(Format), ord(cformat),
      HRTTI.EnumerationToString<TD3DPool>(cpool), HRTTI.SetToString<SetUsage>(Usage)]));
  end;
  // Create save with possible changed parameters
  HLog.CheckDX9Error(D3DXCreateTexture(TDirectX9Device(Device).FDevice, Width, Height, MipLevels, cusage, cformat, cpool, TDirectX9Textur(Result).FDirect3DTexture9), 'TDirectX9Textur.iCreateTexture: Error occurs on creating texture.');
end;

class function TDirectX9Textur.iCreateTextureFromFile(FilePath : string; Device : TDevice; FailSilently : boolean; MipmapHandling : EnumMipMapHandling; ResizeToPow2 : boolean) : TTexture;
begin
  Result := TDirectX9Textur.Create(Device);
  TDirectX9Textur(Result).FMipmapHandling := MipmapHandling;
  TDirectX9Textur(Result).FResizeToPow2 := ResizeToPow2;
  ContentManager.SubscribeToFile(FilePath, TDirectX9Textur(Result).LoadTextureFromMemoryStream);
end;

procedure TDirectX9Textur.LoadTextureFromMemoryStream(const FilePath : string; const Filecontent : TMemoryStream);
var
  ImageInfo : TD3DXImageInfo;
  Size, mipmaps : Cardinal;
  FileTag : AnsiString;
begin
  Size := HGeneric.TertOp(FResizeToPow2, CDEFAULT, CDEFAULTNONPOW2);
  mipmaps := HGeneric.TertOp(FMipmapHandling = mhGenerate, 0, 1);
  setlength(FileTag, 4);
  Filecontent.Read(FileTag[1], 4);
  Filecontent.Position := 0;
  if FileTag = '8BPS' then
  begin
    if not LoadD3DTextureFromMemory(Filecontent.Memory, Filecontent.Size, TDirectX9Device(FDevice).FDevice, FDirect3DTexture9, @FWidth, @FHeight) then
        raise Exception.Create('TDirectX9Textur.iCreateTextureFromStream: Error occurs on create texture from stream.');
  end
  else
  begin
    HLog.CheckDX9Error(D3DXCreateTextureFromFileInMemoryEx(TDirectX9Device(FDevice).FDevice, Filecontent.Memory, Filecontent.Size, Size, Size, mipmaps, 0, D3DFMT_UNKNOWN, D3DPOOL_DEFAULT, D3DX_DEFAULT, D3DX_DEFAULT, 0, @ImageInfo, nil, FDirect3DTexture9), 'TDirectX9Textur.iCreateTextureFromStream: Error occurs on create texture from stream.');
    FWidth := ImageInfo.Width;
    FHeight := ImageInfo.Height;
    FFormat := EnumTextureFormat(ImageInfo.Format);
  end;
  FMipLevels := mipmaps;
  FUsage := [];
end;

procedure TDirectX9Textur.Lock;
begin
  LowLock;
end;

function TDirectX9Textur.LowLock(rect : PRect) : Pointer;
var
  Lockrect : TD3DLockedRect;
begin
  if FUsage * [usReadable, usWriteable, usFrequentlyWriteable] = [] then raise Exception.Create('TDirectX9Textur.LowLock: Textures with Default-Pool cannot be locked!');
  HLog.CheckDX9Error(Direct3DTexture9.Lockrect(0, Lockrect, System.Types.PRect(rect), 0), 'TDirectX9Textur.LowLock');;
  FLocked := Lockrect.pBits;
  Result := FLocked;
end;

procedure TDirectX9Textur.MakeLockable;
begin
  if FUsage * [usReadable, usWriteable, usFrequentlyWriteable] <> [] then exit;
  FUsage := FUsage + [usReadable, usWriteable];
  _Resize(Width, Height, False);
end;

procedure TDirectX9Textur.Resize(newWidth, newHeight : integer);
begin
  if (newWidth <= 0) or (newHeight <= 0) or ((newWidth = self.Width) and (newHeight = self.Height)) then exit;
  _Resize(newWidth, newHeight, False);
end;

procedure TDirectX9Textur.SaveToFile(FileName : string; FileFormat : EnumTextureFileType);
begin
  case FileFormat of
    tfPNG : HLog.CheckDX9Error(D3DXSaveTextureToFileW(PChar(FileName), D3DXIFF_PNG, self.FDirect3DTexture9, nil), 'TDirectX9Textur.SaveToFile failed to save ' + FileName + ' as png!');
    tfJPG : HLog.CheckDX9Error(D3DXSaveTextureToFileW(PChar(FileName), D3DXIFF_JPG, self.FDirect3DTexture9, nil), 'TDirectX9Textur.SaveToFile failed to save ' + FileName + ' as jpg!');
  else
    assert(False, 'Format ' + HRTTI.EnumerationToString<EnumTextureFileType>(FileFormat) + ' not supported yet');
  end;
end;

procedure TDirectX9Textur.Unlock;
begin
  if assigned(FLocked) then
  begin
    HLog.CheckDX9Error(Direct3DTexture9.UnlockRect(0), 'TDirectX9Textur.Unlock');
    FLocked := nil;
  end;
end;

procedure TDirectX9Textur._Resize(newWidth, newHeight : Cardinal; DisableMipLevels : boolean);
var
  DestTex : IDirect3DTexture9;
  oldSurface, newSurface : IDirect3DSurface9;
  mips : Cardinal;
  pool : TD3DPool;
begin
  if DisableMipLevels then mips := 1
  else mips := FMipLevels;
  if FUsage * [usReadable, usWriteable, usFrequentlyWriteable] = [] then pool := TD3DPool.D3DPOOL_DEFAULT
  else pool := TD3DPool.D3DPOOL_MANAGED;
  HLog.CheckDX9Error(TDirectX9Device(FDevice).FDevice.CreateTexture(newWidth, newHeight, mips, UsageToCardinal(FUsage), D3DFORMAT(FFormat), pool, DestTex, nil), 'Could not create texture for resize!');
  FDirect3DTexture9.GetSurfaceLevel(0, oldSurface);
  DestTex.GetSurfaceLevel(0, newSurface);
  // Faster stretchrect usable?
  if pool = D3DPOOL_DEFAULT then
  begin
    TDirectX9Device(FDevice).FDevice.StretchRect(newSurface, nil, oldSurface, nil, D3DTEXF_LINEAR);
  end
  else
  begin
    D3DXLoadSurfaceFromSurface(newSurface, nil, nil, oldSurface, nil, nil, D3DX_FILTER_LINEAR, 0);
  end;
  FWidth := newWidth;
  FHeight := newHeight;
  FDirect3DTexture9 := nil;
  FDirect3DTexture9 := DestTex;
end;

{ TDirectX9Surface }

constructor TDirectX9Surface.Create(Direct3DSurface9 : IDirect3DSurface9);
begin
  FDirect3DSurface9 := Direct3DSurface9;
end;

destructor TDirectX9Surface.Destroy;
begin
  // dont inherit, need some implementation to provide errors -> ask martin ;)
  // inherited;
end;

{ TDirectX9Device }

procedure TDirectX9Device.ApplySamplerStates;
var
  i : EnumTextureSlot;
  samplerstate : RSamplerState;
  function EnumTextureFilterToD3DTEXTUREFILTERTYPE(Texturefilter : EnumTextureFilter) : D3DTEXTUREFILTERTYPE;
  begin
    case Texturefilter of
      tfAuto : Result := EnumTextureFilterToD3DTEXTUREFILTERTYPE(GetAutoTextureFilter);
      tfPoint : Result := D3DTEXF_POINT;
      tfLinear : Result := D3DTEXF_LINEAR;
      tfAnisotropic : Result := D3DTEXF_ANISOTROPIC;
    else raise ENotSupportedException.Create('TDirectX9Device.ApplySamplerStates: Invalid Texturefilter!');
    end;
  end;

begin
  for i := low(EnumTextureSlot) to high(EnumTextureSlot) do
  begin
    samplerstate := GetSamplerState(i);
    FDevice.SetSamplerState(ord(i), D3DSAMP_ADDRESSU, ord(samplerstate.AddressMode));
    FDevice.SetSamplerState(ord(i), D3DSAMP_ADDRESSV, ord(samplerstate.AddressMode));
    FDevice.SetSamplerState(ord(i), D3DSAMP_ADDRESSW, ord(samplerstate.AddressMode));
    FDevice.SetSamplerState(ord(i), D3DSAMP_MAGFILTER, EnumTextureFilterToD3DTEXTUREFILTERTYPE(samplerstate.Filter));
    FDevice.SetSamplerState(ord(i), D3DSAMP_MINFILTER, EnumTextureFilterToD3DTEXTUREFILTERTYPE(samplerstate.Filter));
    FDevice.SetSamplerState(ord(i), D3DSAMP_MIPFILTER, EnumTextureFilterToD3DTEXTUREFILTERTYPE(samplerstate.Filter));
  end;
end;

procedure TDirectX9Device.BeginScene;
begin
  HLog.CheckDX9Error(FDevice.BeginScene, 'TDirectX9Device.BeginScene');
end;

procedure TDirectX9Device.ChangeResolution(const NewResolution : RIntVector2);
begin
  raise ENotImplemented.Create('TDirectX9Device.ChangeResolution');
end;

procedure TDirectX9Device.Clear(Flags : SetClearFlags; Color : RColor; z : Single; Stencil : DWord);
begin
  HLog.CheckDX9Error(FDevice.Clear(0, nil, ClearFlagsToCardinal(Flags), Color.AsCardinal, z, Stencil), 'TDirectX9Device.Clear');
end;

function TDirectX9Device.CreateDepthStencilBuffer(Width, Height : Cardinal) : TDepthStencilBuffer;
var
  Surface : TDirectX9Surface;
  ISurface : IDirect3DSurface9;
begin
  HLog.CheckDX9Error(FDevice.CreateDepthStencilSurface(Width, Height, FPresentParameters.AutoDepthStencilFormat, FPresentParameters.MultiSampleType, FPresentParameters.MultiSampleQuality, False, ISurface, nil), 'TDirectX9DepthStencilBuffer.iCreate');
  Surface := TDirectX9Surface.Create(ISurface);
  Result := TDirectX9DepthStencilbuffer.Create(Surface);
end;

destructor TDirectX9Device.Destroy;
begin
  inherited;
end;

procedure TDirectX9Device.DrawIndexedPrimitive(PrimitiveType : EnumPrimitveType; BaseVertexIndex : integer; MinVertexIndex, NumVertices, StartIndex, primCount : Cardinal);
var
  pt : TD3DPrimitiveType;
begin
  ApplySamplerStates;
  pt := TD3DPrimitiveType(ord(PrimitiveType));
  HLog.CheckDX9Error(FDevice.DrawIndexedPrimitive(pt, BaseVertexIndex, MinVertexIndex, NumVertices, StartIndex, primCount), 'TDirectX9Device.DrawIndexedPrimitive');
end;

procedure TDirectX9Device.DrawPrimitive(PrimitiveType : EnumPrimitveType; StartIndex, PrimitiveCount : Cardinal);
var
  pt : TD3DPrimitiveType;
begin
  ApplySamplerStates;
  pt := TD3DPrimitiveType(ord(PrimitiveType));
  HLog.CheckDX9Error(FDevice.DrawPrimitive(pt, StartIndex, PrimitiveCount), 'TDirectX9Device.DrawPrimitive');
end;

procedure TDirectX9Device.EndScene;
begin
  HLog.CheckDX9Error(FDevice.EndScene, 'TDirectX9Device.EndScene');
end;

function TDirectX9Device.GetDepthStencilBuffer : TDepthStencilBuffer;
var
  Surface : IDirect3DSurface9;
begin
  HLog.CheckDX9Error(FDevice.GetDepthStencilSurface(Surface), 'TDirectX9Device.GetDepthStencilBuffer');
  Result := TDirectX9DepthStencilbuffer.Create(TDirectX9Surface.Create(Surface));
end;

function TDirectX9Device.GetMaxMRT : byte;
begin
  Result := 4;
end;

procedure TDirectX9Device.BuildPresentParameters;
var
  d3ddm : TD3dDisplayMode;
  DeviceTyp : TD3DDevType;
  maxAAQualy : longword;
  FavoredAALevel : longword;
begin
  fillchar(FPresentParameters, SizeOf(TD3DPresentParameters), 0);
  HLog.CheckDX9Error(FGFX.GetAdapterDisplayMode(D3DAdapter_Default, d3ddm), 'Fehler bei GetAdapterDisplayMode');
  FPresentParameters.Windowed := not FSettings.Fullscreen;
  FPresentParameters.SwapEffect := D3DSWAPEFFECT_DISCARD;
  if FSettings.Fullscreen then
  begin
    FPresentParameters.BackBufferWidth := FSettings.Resolution.Width;
    FPresentParameters.BackBufferHeight := FSettings.Resolution.Height;
    // 32 Bit Colordepth
    FPresentParameters.BackBufferFormat := D3DFMT_X8R8G8B8
  end
  else
  begin
    HLog.CheckDX9Error(FGFX.GetAdapterDisplayMode(D3DAdapter_Default, d3ddm), 'Fehler bei GetAdapterDisplayMode');
    FPresentParameters.BackBufferFormat := d3ddm.Format;
    // if windowedmode, following parameters preset by D3D-Api
    FPresentParameters.PresentationInterval := 0;
    FPresentParameters.FullScreen_RefreshRateInHz := 0;
  end;
  FPresentParameters.BackBufferCount := 0;
  FPresentParameters.EnableAutoDepthStencil := true;
  FPresentParameters.AutoDepthStencilFormat := D3DFMT_D24S8;
  if FSettings.Vsync then FPresentParameters.PresentationInterval := D3DPRESENT_INTERVAL_One
  else FPresentParameters.PresentationInterval := D3DPRESENT_INTERVAL_Immediate;

  // Multisamplinguntestützung testen
  if FSettings.HAL then DeviceTyp := D3DDEVTYPE_HAL
  else DeviceTyp := D3DDEVTYPE_REF;
  maxAAQualy := 0;
  FGFX.CheckDeviceMultiSampleType(D3DAdapter_Default, DeviceTyp, FPresentParameters.BackBufferFormat, FPresentParameters.Windowed, D3DMULTISAMPLE_NONMASKABLE, @maxAAQualy);
  case FSettings.AntialiasingLevel of
    aaNone : FavoredAALevel := 0;
    aa2x : FavoredAALevel := 1;
    aa4x : FavoredAALevel := 2;
    aaEdge : FavoredAALevel := 0;
  else FavoredAALevel := 0;
  end;
  if (FavoredAALevel > 0) then
  begin
    if maxAAQualy > FavoredAALevel then
    begin
      FPresentParameters.MultiSampleType := D3DMULTISAMPLE_NONMASKABLE;
      FPresentParameters.MultiSampleQuality := FavoredAALevel;
    end
    else
    begin
      FPresentParameters.MultiSampleType := D3DMULTISAMPLE_NONE;
      HLog.Log('Die geforderte Antialiasingqualität wird nicht unterstützt.');
    end;
  end
  else FPresentParameters.MultiSampleType := D3DMULTISAMPLE_NONE;
end;

function TDirectX9Device.GetRendertarget(Index : integer) : TRendertarget;
var
  Surface : IDirect3DSurface9;
begin
  HLog.CheckDX9Error(FDevice.GetRendertarget(index, Surface), 'TDirectX9Device.GetRendertarget');
  Result := TDirectX9Rendertarget.CreateRaw(self, TDirectX9Surface.Create(Surface), 0, 0);
end;

class function TDirectX9Device.iCreateDevice(Handle : HWND; Settings : TDeviceSettings) : TDevice;
var
  d3dpp : TD3DPresentParameters;
  Device : TDirectX9Device;
begin
  Device := TDirectX9Device.Create;
  Device.FSettings := Settings;
  // Initialisierung der Grafik starten
  Device.FGFX := Direct3DCreate9(D3D_SDK_VERSION);
  if (Device.FGFX = nil) then
  begin
    HLog.Log('IDirect3D9 konnte nicht initialisiert werden.');
    raise EGraphicInitError.Create('Error while initializing the graphic device: IDirect3D9 couldn''t be initialized.');
  end;
  Device.BuildPresentParameters();
  d3dpp := Device.FPresentParameters;
  if Settings.HAL then HLog.CheckDX9Error(Device.FGFX.CreateDevice(D3DAdapter_Default, D3DDEVTYPE_HAL, Handle, D3DCREATE_HARDWARE_VERTEXPROCESSING, @d3dpp, Device.FDevice), 'Fehler beim Init der Devices')
  else
  begin
    Settings.HAL := False;
    HLog.Log('HAL bzw. hardwareunterstützte Verarbeitung der Veritces wird von der Grafikkarte nicht unterstützt, HAL wird deaktiviert.');
    if Device.FGFX.CreateDevice(D3DAdapter_Default, D3DDEVTYPE_REF, Handle, D3DCREATE_SOFTWARE_VERTEXPROCESSING, @d3dpp, Device.FDevice) <> D3D_OK then raise EGraphicInitError.Create('Error while initializing the graphic device: Your hardware doesn''t support the needed modi!');
  end;
  Result := Device;
  Device.FBackbuffer := Device.GetRendertarget(0);
  Device.FBackbuffer.Width := Settings.Resolution.Width;
  Device.FBackbuffer.Height := Settings.Resolution.Height;
  TDirectX9Rendertarget(Device.FBackbuffer).FDepthStencilBuffer := Device.GetDepthStencilBuffer;
  Settings.CanDeferredShading := true;
  Device.FResolution := Settings.Resolution;
end;

function TDirectX9Device.MapRenderStateValueApiToEngine(Renderstate : EnumRenderstate;
  Value : Cardinal) : Cardinal;
begin
  // bye default no mapping is done
  case Renderstate of
    rsCULLMODE : Result := Value - 1;
  else Result := Value;
  end;
end;

function TDirectX9Device.MapRenderStateValueEngineToApi(Renderstate : EnumRenderstate;
  Value : Cardinal) : Cardinal;
begin
  // bye default no mapping is done
  case Renderstate of
    rsCULLMODE : Result := Value + 1;
  else Result := Value;
  end;
end;

procedure TDirectX9Device.Present(SourceRect, DestRect : PRect; WindowOverride : HWND);
begin
  HLog.CheckDX9Error(FDevice.Present(System.Types.PRect(SourceRect), System.Types.PRect(DestRect), WindowOverride, nil), 'TDirectX9Device.Present');
end;

procedure TDirectX9Device.SaveScreenshotToFile(FileName : string);
begin
  raise ENotImplemented.Create('TDirectX9Device.SaveScreenshotToFile: Not implemented for DX9!');
end;

procedure TDirectX9Device.SetDepthStencilBuffer(Depthbuffer : TDepthStencilBuffer);
begin
  if assigned(Depthbuffer) then
      HLog.CheckDX9Error(FDevice.SetDepthStencilSurface(TDirectX9Surface(TDirectX9DepthStencilbuffer(Depthbuffer).FSurface).Direct3DSurface9), 'TDirectX9Device.SetDepthStencilBuffer')
  else
      HLog.CheckDX9Error(FDevice.SetDepthStencilSurface(nil), 'TDirectX9Device.SetDepthStencilBuffer')
end;

procedure TDirectX9Device.SetIndices(Indices : TIndexBuffer);
begin
  HLog.CheckDX9Error(FDevice.SetIndices(TDirectX9IndexBuffer(Indices).FIndexBuffer), 'TDirectX9Device.SetIndices.');
end;

function TDirectX9Device.GetRealRenderState(Renderstate : EnumRenderstate) : Cardinal;
begin
  HLog.CheckDX9Error(FDevice.GetRenderState(D3DRENDERSTATETYPE(ord(Renderstate)), Result), 'TDirectX9Device.GetRealRenderState: ' + Inttostr(ord(Renderstate)));
  Result := MapRenderStateValueApiToEngine(Renderstate, Result);
end;

procedure TDirectX9Device.SetRealRenderState(Renderstate : EnumRenderstate; Value : Cardinal);
begin
  HLog.CheckDX9Error(FDevice.SetRenderState(D3DRENDERSTATETYPE(ord(Renderstate)), MapRenderStateValueEngineToApi(Renderstate, Value)), 'TDirectX9Device.SetRenderState: ' + Inttostr(ord(Renderstate)) + ' to ' + Inttostr(Value));
end;

procedure TDirectX9Device.SetRendertargets(Targets : array of TRendertarget);
var
  Index : integer;
begin
  assert(Length(Targets) >= 1);
  assert(assigned(Targets[0]));
  // directx 9 doesn't allow rendertargets to have nil gaps between slots
  // clear-loop
  for index := Length(Targets) - 1 downto 0 do
  begin
    if assigned(Targets[index]) then break;
    HLog.CheckDX9Error(FDevice.SetRendertarget(index, nil), 'TDirectX9Device.SetRendertarget(' + Inttostr(index) + ')')
  end;
  // fill loop
  for index := 0 to Length(Targets) - 1 do
  begin
    if not assigned(Targets[index]) then break
    else HLog.CheckDX9Error(FDevice.SetRendertarget(index, TDirectX9Surface(TDirectX9Rendertarget(Targets[index]).FSurface).Direct3DSurface9), 'TDirectX9Device.SetRendertarget(' + Inttostr(index) + ')');
    if (index = 0) then
    begin
      if assigned(Targets[index].DepthStencilBuffer) then SetDepthStencilBuffer(Targets[index].DepthStencilBuffer)
      else
      begin
        if (Targets[0].Size = FBackbuffer.Size) then
            SetDepthStencilBuffer(FBackbuffer.DepthStencilBuffer)
          // else unset depthstencilbuffer
        else
            SetDepthStencilBuffer(nil);
      end;
      SetViewport(Targets[index].Width, Targets[index].Height);
    end;
  end;
end;

procedure TDirectX9Device.SetStreamSource(StreamNumber : longword; pStreamData : TVertexBuffer; OffsetInBytes, Stride : longword);
begin
  HLog.CheckDX9Error(FDevice.SetStreamSource(StreamNumber, TDirectX9VertexBuffer(pStreamData).VertexBuffer, OffsetInBytes, Stride), 'TDirectX9Device.SetStreamSource');
end;

procedure TDirectX9Device.SetVertexDeclaration(vertexdeclaration : TVertexDeclaration);
begin
  HLog.CheckDX9Error(FDevice.SetVertexDeclaration(TDirectX9VertexDeclaration(vertexdeclaration).vertexdeclaration), 'TDirectX9Device.SetVertexDeclaration');
end;

procedure TDirectX9Device.SetViewport(Width, Height : Cardinal);
var
  Viewport : TD3DViewport9;
begin
  Viewport.x := 0;
  Viewport.y := 0;
  Viewport.Width := Width;
  Viewport.Height := Height;
  Viewport.MinZ := 0.0;
  Viewport.MaxZ := 1.0;
  HLog.CheckDX9Error(FDevice.SetViewport(Viewport), 'TDirectX9Device.SetViewport');
end;

{ TDirectX9Rendertarget }

constructor TDirectX9Rendertarget.CreateRaw(Device : TDevice; Target : TDirectX9Surface; Width, Height : Cardinal);
begin
  Create(Device, nil, Width, Height);
  FSurface := Target;
end;

destructor TDirectX9Rendertarget.Destroy;
begin
  FSurface.Free;
  inherited;
end;

procedure TDirectX9Rendertarget.InitializeTarget(Target : TTexture);
begin
  if assigned(Target) then FSurface := TDirectX9Textur(Target).GetSurfaceLevel(0);
end;

{ TDirectX9DepthStencilbuffer }

constructor TDirectX9DepthStencilbuffer.Create(Surface : TDirectX9Surface);
begin
  FSurface := Surface;
end;

class function TDirectX9DepthStencilbuffer.CreateDepthStencilBuffer(Device : TDevice; Width, Height : Cardinal) : TDepthStencilBuffer;
begin
  Result := Device.CreateDepthStencilBuffer(Width, Height);
end;

destructor TDirectX9DepthStencilbuffer.Destroy;
begin
  FSurface.Free;
  inherited;
end;

end.

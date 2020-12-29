unit Engine.DX11Api;

interface

uses
  // ======= Delphi ==========
  System.Generics.Defaults,
  System.Generics.Collections,
  System.SysUtils,
  System.Math,
  System.Classes,
  System.RegularExpressions,
  System.UITypes,
  System.SyncObjs,
  Vcl.Dialogs,
  WinApi.Windows,
  WinApi.D3D11,
  WinApi.DxgiFormat,
  WinApi.DxgiType,
  WinApi.Dxgi,
  WinApi.DXGI1_2,
  WinApi.DXGI1_4,
  WinApi.D3DCommon,

  // ======= Thrid-Party ======
  Imaging,
  ImagingTypes,
  D3DCompiler_JSB,
  D3DX11_JSB,

  // ======= Engine ==========
  Engine.GfxApi,
  Engine.GfxApi.Types,
  Engine.Core.Texture,
  Engine.Log,
  Engine.Math,
  Engine.Helferlein,
  Engine.Helferlein.Windows,
  Engine.Math.Collision2D;

type

  TDirectX11Rendertarget = class;

  AConstantBuffers = array of ID3D11Buffer;

  TDirectX11Device = class(TDevice)
    protected
      FSettings : TDeviceSettings;
      FSwapChain : IDXGISwapChain;
      FDevice : ID3D11Device;
      FDeviceContext : ID3D11DeviceContext;
      FBackbufferTexture : TTexture;
      FRendertarget : TArray<TDirectX11Rendertarget>;
      FPreparedSamplers : array [Boolean] of array [EnumTextureFilter] of array [EnumTexturAddressMode] of ID3D11SamplerState;
      FSetConstantBuffers : AConstantBuffers;
      FSetShader : TShader;
      class function iCreateDevice(Handle : HWND; Settings : TDeviceSettings) : TDevice; override;
      procedure Initialize(Handle : HWND; Settings : TDeviceSettings);
      procedure SetRealRenderState(Renderstate : EnumRenderstate; Value : Cardinal); override;
      function GetRealRenderState(Renderstate : EnumRenderstate) : Cardinal; override;
      procedure ApplyRenderstates;
      procedure ApplySamplerstates;
      function GetRealSamplerState(index : EnumTextureSlot; const SamplerState : RSamplerstate) : ID3D11SamplerState;
      procedure SetTopology(Topo : EnumPrimitveType);
      procedure SetRendertargets(Targets : array of TRendertarget); override;
      procedure SetConstantBuffers(Constantbuffers : AConstantBuffers);
      procedure SetShader(Shader : TShader);
      procedure UpdateSwapchain;
    public
      property Device : ID3D11Device read FDevice;
      property DeviceContext : ID3D11DeviceContext read FDeviceContext;
      procedure Clear(Flags : SetClearFlags; Color : RColor; z : Single; Stencil : DWord); override;
      function CreateDepthStencilBuffer(Width, Height : Cardinal) : TDepthStencilBuffer; override;
      function GetMaxMRT : byte; override;
      function GetDedicatedVideoMemory : Int64; override;
      function GetVideoMemoryInfo : string; override;
      function GetUsedVideoMemory : Int64; override;
      procedure ChangeResolution(const NewResolution : RIntVector2); override;
      procedure BeginScene; override;
      procedure EndScene; override;
      procedure DrawPrimitive(PrimitiveType : EnumPrimitveType; StartIndex, PrimitiveCount : Cardinal); override;
      procedure DrawIndexedPrimitive(PrimitiveType : EnumPrimitveType; BaseVertexIndex : integer; MinVertexIndex, NumVertices, StartIndex, primCount : Cardinal); override;
      procedure SetViewport(Width, Height : Cardinal); override;
      function GetRendertarget(index : integer) : TRendertarget;
      procedure SetStreamSource(StreamNumber : longword; pStreamData : TVertexBuffer; OffsetInBytes, Stride : longword); override;
      procedure SetIndices(Indices : TIndexBuffer); override;
      procedure SetVertexDeclaration(vertexdeclaration : TVertexDeclaration); override;
      procedure SaveScreenshotToFile(Filename : string); override;
      procedure Present(SourceRect, DestRect : PRect; WindowOverride : HWND); override;
      destructor Destroy; override;
  end;

  TDirectX11Texture = class(TTexture)
    protected
      FDevice : TDirectX11Device;
      FDynamic, FIsLocked : Boolean;
      FTexture, FStaging : ID3D11Resource;
      FSRV : ID3D11ShaderResourceView;
      procedure CreateStaging;
      constructor CreateRaw(Texture : ID3D11Texture2D; Size : RIntVector2; Device : TDevice);
      function getSRV : ID3D11ShaderResourceView;
      procedure CheckChannelOrder(Format : DXGI_FORMAT);
      procedure BuildTexture;
      class function iCreateTexture(const Width, Height, MipLevels : Cardinal; Usage : SetUsage; Format : EnumTextureFormat; Device : TDevice) : TTexture; override;
      class function iCreateTextureFromFile(Filename : string; Device : TDevice; FailSilently : Boolean; MipmapHandling : EnumMipMapHandling = mhGenerate; ResizeToPow2 : Boolean = true) : TTexture; override;
      procedure LoadTextureFromMemoryStream(const FilePath : string; const Filecontent : TMemoryStream); override;
      procedure LoadRawTextureFromMemoryStream(const FilePath : string; const Filecontent : TMemoryStream);
    public
      property RawTexture : ID3D11Resource read FTexture;
      property ShaderResourceView : ID3D11ShaderResourceView read getSRV;
      procedure MakeLockable; override;
      procedure DisableMipLevels; override;
      function LowLock(Lockrect : PRect) : Pointer; override;
      procedure Lock(); override;
      procedure Unlock; override;
      procedure Resize(newWidth, newHeight : integer); override;
      function FastCopyAvailable : Boolean; override;
      procedure FastCopy(Target : TTexture); override;
      destructor Destroy; override;
  end;

  TDirectX11Rendertarget = class(TRendertarget)
    protected
      FRenderTargetView : ID3D11RenderTargetView;
      procedure InitializeTarget(Target : TTexture); override;
      constructor CreateRaw(Texture : TTexture; DepthStencilbuffer : TDepthStencilBuffer; Device : TDirectX11Device);
    public
      property RawRTV : ID3D11RenderTargetView read FRenderTargetView;
  end;

  RConstantVariable = record
    Size, Offset : integer;
    IsBool, IsArray : Boolean;
    IsValid : Boolean; // will be initialized with false in default variable array to determine if present
  end;

  TConstantBuffer = class
    strict private
      FConstantBuffer : ID3D11Buffer;
      FSlot : integer;
      FDataBlob : TArray<byte>;
      FVariables : TDictionary<string, RConstantVariable>;
      FDefaultVariables : array [EnumDefaultShaderConstant] of RConstantVariable;
      FDirty : Boolean;
      procedure Analyze(Definition : string);
      procedure BuildConstantbuffer(Device : TDevice);
      procedure SetShaderConstant(const Constant : RConstantVariable; Value : Pointer; Size : integer); overload;
    public
      IsGlobal : Boolean;
      property Slot : integer read FSlot;
      property Variables : TDictionary<string, RConstantVariable> read FVariables;
      constructor Create(Definition : string; Slot : integer; Device : TDevice);
      procedure SetShaderConstant(const ConstantName : string; Value : Pointer; Size : integer); overload;
      procedure SetShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : integer); overload;
      procedure SetConstantbuffer(Device : TDirectX11Device; var bufferarray : AConstantBuffers);
      destructor Destroy; override;
  end;

  TConstantbufferManager = class
    protected
      FConstantBuffers : TDictionary<string, TConstantBuffer>;
      FVariables : TDictionary<string, TConstantBuffer>;
      FDefaultVariables : array [EnumDefaultShaderConstant] of TConstantBuffer;
    public
      constructor Create;
      procedure SetShaderConstant(const ConstantName : string; Value : Pointer; Size : integer); overload;
      procedure SetShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : integer); overload;
      procedure SetConstantBuffers(Device : TDirectX11Device);
      destructor Destroy; override;
  end;

  TConstantbufferManagerManager = class
    strict private
      FConstantBuffers : TObjectDictionary<string, TConstantBuffer>;
      FLock : TCriticalSection;
      function Analyze(Shaderstr : string; Device : TDevice) : TConstantbufferManager;
      // resolves all #ifdef and #infndef
      function ResolveSimpleDefines(Shaderstr : string) : string;
    public
      constructor Create();
      function CreateBuffers(Shaderstr : string; Device : TDevice) : TConstantbufferManager;
      destructor Destroy; override;
  end;

  TDirectX11Shader = class(TShader)
    protected
      FVertexShader : ID3D11VertexShader;
      FPixelShader : ID3D11PixelShader;
      FConstantbufferManager : TConstantbufferManager;
      constructor Create(Device : TDevice);
      /// <summary> Creates a Shader from an string with the given GFXD </summary>
      class function iCreateShader(Device : TDevice) : TShader; override;
      procedure CompileShader(Shaderstr : AnsiString); override;
      procedure BuildConstantbuffers(Shaderstr : string);
      procedure SetRealBoolean(const ConstantName : string; bool : Boolean); override;
      procedure SetRealShaderConstant(const ConstantName : string; Value : Pointer; Size : integer); override;
      procedure SetRealBoolean(const ConstantName : EnumDefaultShaderConstant; bool : Boolean); overload; override;
      procedure SetRealShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : integer); overload; override;
      procedure SetRealTexture(const Slot : EnumTextureSlot; Texture : TTexture; ShaderTarget : EnumShaderType); override;
    public
      procedure CommitChanges(); override;
      procedure ShaderBegin; override;
      procedure ShaderEnd; override;
      destructor Destroy; override;
  end;

  TDirectX11VertexBuffer = class(TVertexBuffer)
    protected
      FVertexbuffer, FStagingBuffer : ID3D11Buffer;
      FDynamic : Boolean;
      class function iCreateVertexBuffer(Length : Cardinal; Usage : SetUsage; Device : TDevice; InitialData : Pointer) : TVertexBuffer; override;
    public
      property RawVertexbuffer : ID3D11Buffer read FVertexbuffer;
      function LowLock(LockFlags : SetLockFlags = []) : Pointer; override;
      procedure Lock(); override;
      procedure Unlock; override;
      destructor Destroy; override;
  end;

  TDirectX11IndexBuffer = class(TIndexBuffer)
    protected
      FIndexbuffer, FStagingBuffer : ID3D11Buffer;
      FDynamic : Boolean;
      class function iCreateIndexBuffer(Length : longword; Usage : SetUsage; Format : EnumIndexBufferFormat; Device : TDevice; InitialData : Pointer) : TIndexBuffer; override;
    public
      property RawIndexBuffer : ID3D11Buffer read FIndexbuffer;
      function LowLock(LockFlags : SetLockFlags = []) : Pointer; override;
      procedure Lock(); override;
      procedure Unlock; override;
      destructor Destroy; override;
  end;

  /// <summary> Aka InputLayout (DX11 Terminology) </summary>
  TDirectX11VertexDeclaration = class(TVertexDeclaration)
    protected
      FInputLayout : ID3D11InputLayout;
      FElements : array of D3D11_INPUT_ELEMENT_DESC;
      FValidationBreaker : AnsiString;
      class function iCreateVertexDeclaration(Device : TDevice) : TVertexDeclaration; override;
      constructor Create(Device : TDevice);
    public
      property InputLayout : ID3D11InputLayout read FInputLayout;
      procedure AddVertexElement(elemtype : EnumVertexElementType; Usage : EnumVertexElementUsage; Method : EnumVertexElementMethod = emDefault; StreamID : word = 0; UsageIndex : word = 0); override;
      procedure EndDeclaration; override;
      destructor Destroy; override;
  end;

  TDirectX11DepthStencilBuffer = class(TDepthStencilBuffer)
    protected
      FDepthStencilView : ID3D11DepthStencilView;
      FDepthStencilBuffer : ID3D11Texture2D;
    public
      property RawDepthStencilView : ID3D11DepthStencilView read FDepthStencilView;
      class function CreateDepthStencilBuffer(Device : TDevice; Width, Height : Cardinal) : TDepthStencilBuffer; override;
  end;

function CheckDX11Ok(ErrorCode : HRESULT) : Boolean;
function CheckDX11Error(ErrorCode : HRESULT; const ErrorMsg : string) : Boolean; overload; inline;
function CheckDX11Error(ErrorCode : HRESULT; const ErrorMsg : string; FormatParameters : array of const) : Boolean; overload;
procedure PrintDX11Error(ErrorCode : HRESULT; const ErrorMsg : string);

var
  DeviceReference : TDirectX11Device;
  ConstantBufferManagerManager : TConstantbufferManagerManager;

  DebugShowMipmapping : Boolean = False;

implementation

function CheckDX11Ok(ErrorCode : HRESULT) : Boolean;
begin
  Result := ErrorCode = S_OK;
end;

// Returns true if error occured
function CheckDX11Error(ErrorCode : HRESULT; const ErrorMsg : string) : Boolean;
begin
  if ErrorCode <> S_OK then
  begin
    PrintDX11Error(ErrorCode, ErrorMsg);
    Result := true;
  end
  else
      Result := False;
end;

// Returns true if error occured
function CheckDX11Error(ErrorCode : HRESULT; const ErrorMsg : string; FormatParameters : array of const) : Boolean;
begin
  if ErrorCode <> S_OK then
  begin
    PrintDX11Error(ErrorCode, Format(ErrorMsg, FormatParameters));
    Result := true;
  end
  else
      Result := False;
end;

procedure PrintDX11Error(ErrorCode : HRESULT; const ErrorMsg : string);
const
  // constants for DirectX error conversion
  _FACD3D           = $876;
  MAKE_D3DHRESULT_R = (1 shl 31) or (_FACD3D shl 16);
var
  tmpstr : string;
begin
  tmpstr := Inttostr(HRESULT(not MAKE_D3DHRESULT_R and ErrorCode));
  case ErrorCode of
    DXGI_STATUS_OCCLUDED, DXGI_ERROR_WAS_STILL_DRAWING : exit;

    E_FAIL : tmpstr := 'E_FAIL';
    E_OUTOFMEMORY : tmpstr := 'E_OUTOFMEMORY';
    E_NOTIMPL : tmpstr := 'E_NOTIMPL';
    S_FALSE : tmpstr := 'S_FALSE';
    E_INVALIDARG : tmpstr := 'E_INVALIDARG';
    DXGI_STATUS_CLIPPED : tmpstr := 'DXGI_STATUS_CLIPPED';
    DXGI_STATUS_NO_REDIRECTION : tmpstr := 'DXGI_STATUS_NO_REDIRECTION';
    DXGI_STATUS_NO_DESKTOP_ACCESS : tmpstr := 'DXGI_STATUS_NO_DESKTOP_ACCESS';
    DXGI_STATUS_GRAPHICS_VIDPN_SOURCE_IN_USE : tmpstr := 'DXGI_STATUS_GRAPHICS_VIDPN_SOURCE_IN_USE';
    DXGI_STATUS_MODE_CHANGED : tmpstr := 'DXGI_STATUS_MODE_CHANGED';
    DXGI_STATUS_MODE_CHANGE_IN_PROGRESS : tmpstr := 'DXGI_STATUS_MODE_CHANGE_IN_PROGRESS';
    DXGI_ERROR_INVALID_CALL : tmpstr := 'DXGI_ERROR_INVALID_CALL';
    DXGI_ERROR_NOT_FOUND : tmpstr := 'DXGI_ERROR_NOT_FOUND';
    DXGI_ERROR_MORE_DATA : tmpstr := 'DXGI_ERROR_MORE_DATA';
    DXGI_ERROR_UNSUPPORTED : tmpstr := 'DXGI_ERROR_UNSUPPORTED';
    DXGI_ERROR_DEVICE_REMOVED :
      begin
        tmpstr := 'DXGI_ERROR_DEVICE_REMOVED';
        if assigned(Engine.DX11Api.DeviceReference) then
        begin
          ErrorCode := Engine.DX11Api.DeviceReference.Device.GetDeviceRemovedReason;
          if ErrorCode <> DXGI_ERROR_DEVICE_REMOVED then
              CheckDX11Error(ErrorCode, ' <- Reason for Device Removed')
          else
              tmpstr := tmpstr + ' (no further reason)';
        end;
        MessageDlg('The system detected that the graphics device has been removed. This is normally a problem on systems with an internal and dedicated graphics device, where they switch dynamically.' + ' Please force the system to use a specific graphics device for this application and restart it.' + ' If the problem persists, please contact the developers.', mtError, [mbOK], 0);
      end;
    DXGI_ERROR_DEVICE_HUNG : tmpstr := 'DXGI_ERROR_DEVICE_HUNG';
    DXGI_ERROR_DEVICE_RESET : tmpstr := 'DXGI_ERROR_DEVICE_RESET';
    DXGI_ERROR_FRAME_STATISTICS_DISJOINT : tmpstr := 'DXGI_ERROR_FRAME_STATISTICS_DISJOINT';
    DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE : tmpstr := 'DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE';
    DXGI_ERROR_DRIVER_INTERNAL_ERROR : tmpstr := 'DXGI_ERROR_DRIVER_INTERNAL_ERROR';
    DXGI_ERROR_NONEXCLUSIVE : tmpstr := 'DXGI_ERROR_NONEXCLUSIVE';
    DXGI_ERROR_NOT_CURRENTLY_AVAILABLE : tmpstr := 'DXGI_ERROR_NOT_CURRENTLY_AVAILABLE';
    DXGI_ERROR_REMOTE_CLIENT_DISCONNECTED : tmpstr := 'DXGI_ERROR_REMOTE_CLIENT_DISCONNECTED';
    DXGI_ERROR_REMOTE_OUTOFMEMORY : tmpstr := 'DXGI_ERROR_REMOTE_OUTOFMEMORY';
  end;
  HLog.Log('0x' + IntToHex(ErrorCode, 8) + ' - ' + tmpstr + ' - ' + ErrorMsg);
end;

procedure ProcessShaderErrors(Shaderstr : AnsiString; errors : ID3DBlob);
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
    HLog.Log(str + sLineBreak + string(Shaderstr));
    raise Exception.Create('Shader couldn''t be created! Errors:' + #10#13 + string(str));
  end;
end;

function FormatToDXGI_FORMAT(Format : EnumTextureFormat) : DXGI_FORMAT;
begin
  Result := DXGI_FORMAT_UNKNOWN;
  case Format of
    tfUNKNOWN : Result := DXGI_FORMAT_UNKNOWN;
    tfR8G8B8 :;
    tfA8R8G8B8 : Result := DXGI_FORMAT_B8G8R8A8_UNORM;
    tfX8R8G8B8 : Result := DXGI_FORMAT_B8G8R8X8_UNORM;
    tfR5G6B5 : Result := DXGI_FORMAT_B5G6R5_UNORM;
    tfX1R5G5B5 :;
    tfA1R5G5B5 : Result := DXGI_FORMAT_B5G5R5A1_UNORM;
    tfA4R4G4B4 :;
    tfR3G3B2 :;
    tfA8 : Result := DXGI_FORMAT_A8_UNORM;
    tfA8R3G3B2 :;
    tfX4R4G4B4 :;
    tfA2B10G10R10 :;
    tfA8B8G8R8 : Result := DXGI_FORMAT_R8G8B8A8_UNORM;
    tfX8B8G8R8 :;
    tfG16R16 : Result := DXGI_FORMAT_R16G16_UNORM;
    tfA2R10G10B10 :;
    tfA16B16G16R16 : Result := DXGI_FORMAT_R16G16B16A16_UNORM;
    tfA8P8 :;
    tfP8 :;
    tfL8 : Result := DXGI_FORMAT_R8_UNORM;
    tfA8L8 :;
    tfA4L4 :;
    tfV8U8 : Result := DXGI_FORMAT_R8G8_SNORM;
    tfL6V5U5 :;
    tfX8L8V8U8 :;
    tfQ8W8V8U8 : Result := DXGI_FORMAT_R8G8B8A8_SNORM;
    tfV16U16 : Result := DXGI_FORMAT_R16G16_SNORM;
    tfA2W10V10U10 :;
    tfA8X8V8U8 :;
    tfL8X8V8U8 :;
    tfUYVY :;
    tfRGBG :;
    tfYUY2 :;
    tfGRGB :;
    tfDXT1 :;
    tfDXT2 :;
    tfDXT3 :;
    tfDXT4 :;
    tfDXT5 :;
    tfD16_LOCKABLE :;
    tfD32 :;
    tfD15S1 :;
    tfD24S8 :;
    tfD24X8 :;
    tfD24X4S4 :;
    tfD16 :;
    tfD32F_LOCKABLE :;
    tfD24FS8 :;
    tfL16 :;
    tfVERTEXDATA :;
    tfQ16W16V16U16 :;
    tfMULTI2_ARGB8 :;
    tfR16F : Result := DXGI_FORMAT_R16_FLOAT;
    tfG16R16F : Result := DXGI_FORMAT_R16G16_FLOAT;
    tfA16B16G16R16F : Result := DXGI_FORMAT_R16G16B16A16_FLOAT;
    tfR32F : Result := DXGI_FORMAT_R32_FLOAT;
    tfG32R32F : Result := DXGI_FORMAT_R32G32_FLOAT;
    tfA32B32G32R32F : Result := DXGI_FORMAT_R32G32B32A32_FLOAT;
    tfCxV8U8 :;
    tfFORCE_DWORD :;
  end;
  assert((Result <> DXGI_FORMAT_UNKNOWN) or (Format = tfUNKNOWN), 'FormatToDXGI_FORMAT: Format ' + HRtti.EnumerationToString<EnumTextureFormat>(Format) + ' not supported by DX11 or Tobi war zu faul alle einzutragen ;P')
end;

function DXGI_FORMATToFormat(Format : DXGI_FORMAT) : EnumTextureFormat;
begin
  Result := tfUNKNOWN;
  case Format of
    DXGI_FORMAT_UNKNOWN : Result := tfUNKNOWN;
    DXGI_FORMAT_B8G8R8A8_UNORM : Result := tfA8R8G8B8;
    DXGI_FORMAT_B8G8R8X8_UNORM : Result := tfX8R8G8B8;
    DXGI_FORMAT_B5G6R5_UNORM : Result := tfR5G6B5;
    DXGI_FORMAT_B5G5R5A1_UNORM : Result := tfA1R5G5B5;
    DXGI_FORMAT_A8_UNORM : Result := tfA8;
    DXGI_FORMAT_R8G8B8A8_UNORM : Result := tfA8B8G8R8;
    DXGI_FORMAT_R16G16_UNORM : Result := tfG16R16;
    DXGI_FORMAT_R16G16B16A16_UNORM : Result := tfA16B16G16R16;
    DXGI_FORMAT_R8_UNORM : Result := tfL8;
    DXGI_FORMAT_R8G8_SNORM : Result := tfV8U8;
    DXGI_FORMAT_R8G8B8A8_SNORM : Result := tfQ8W8V8U8;
    DXGI_FORMAT_R16G16_SNORM : Result := tfV16U16;
    DXGI_FORMAT_R16_FLOAT : Result := tfR16F;
    DXGI_FORMAT_R16G16_FLOAT : Result := tfG16R16F;
    DXGI_FORMAT_R16G16B16A16_FLOAT : Result := tfA16B16G16R16F;
    DXGI_FORMAT_R32_FLOAT : Result := tfR32F;
    DXGI_FORMAT_R32G32_FLOAT : Result := tfG32R32F;
    DXGI_FORMAT_R32G32B32A32_FLOAT : Result := tfA32B32G32R32F;
  end;
  assert((Format <> DXGI_FORMAT_UNKNOWN) or (Result = tfUNKNOWN), 'DXGI_FORMATToFormat: Format not supported by DX11 or Tobi war zu faul alle einzutragen ;P')
end;

function EnumCullModeToD3D11Cullmode(Cullmode : EnumCullmode) : D3D11_CULL_MODE;
begin
  Result := D3D11_CULL_BACK;
  case Cullmode of
    cmNone : Result := D3D11_CULL_NONE;
    cmCW : Result := D3D11_CULL_FRONT;
    cmCCW : Result := D3D11_CULL_BACK;
  end;
  assert((Result <> D3D11_CULL_BACK) or (Cullmode = cmCCW));
end;

function EnumBlendToD3D11Blend(Blend : EnumBlend) : D3D11_BLEND;
begin
  Result := D3D11_BLEND_ONE;
  case Blend of
    blZero : Result := D3D11_BLEND_ZERO;
    blOne : Result := D3D11_BLEND_ONE;
    blSrcColor : Result := D3D11_BLEND_SRC_COLOR;
    blInvSrcColor : Result := D3D11_BLEND_INV_SRC_COLOR;
    blSrcAlpha : Result := D3D11_BLEND_SRC_ALPHA;
    blInvSrcAlpha : Result := D3D11_BLEND_INV_SRC_ALPHA;
    blDestAlpha : Result := D3D11_BLEND_DEST_ALPHA;
    blInvDestAlpha : Result := D3D11_BLEND_INV_DEST_ALPHA;
    blDestColor : Result := D3D11_BLEND_DEST_COLOR;
    blInvDestColor : Result := D3D11_BLEND_INV_DEST_COLOR;
    blSrcAlphaSat : Result := D3D11_BLEND_SRC_ALPHA_SAT;
    blBlendfactor : Result := D3D11_BLEND_BLEND_FACTOR;
  end;
  assert((Result <> D3D11_BLEND_ONE) or (Blend = blOne));
end;

function EnumBlendOpToD3D11BlendOp(BlendOp : EnumBlendOp) : D3D11_BLEND_OP;
begin
  Result := D3D11_BLEND_OP_ADD;
  case BlendOp of
    boAdd : Result := D3D11_BLEND_OP_ADD;
    boSubtract : Result := D3D11_BLEND_OP_SUBTRACT;
    boRevSubtract : Result := D3D11_BLEND_OP_REV_SUBTRACT;
    boMin : Result := D3D11_BLEND_OP_MIN;
    boMax : Result := D3D11_BLEND_OP_MAX;
  end;
  assert((Result <> D3D11_BLEND_OP_ADD) or (BlendOp = boAdd));
end;

{ TDirectX11Device }

class function TDirectX11Device.iCreateDevice(Handle : HWND; Settings : TDeviceSettings) : TDevice;
begin
  Result := TDirectX11Device.Create;
  TDirectX11Device(Result).Initialize(Handle, Settings);
  TDirectX11Device(Result).FResolution := Settings.Resolution;
end;

procedure TDirectX11Device.ApplyRenderstates;
var
  i : integer;
  stencil_ref : Cardinal;
  rasterizer_desc : D3D11_RASTERIZER_DESC;
  state : ID3D11RasterizerState;

  depthstencil_desc : D3D11_DEPTH_STENCIL_DESC;
  dstate : ID3D11DepthStencilState;

  blend_desc : D3D11_BLEND_DESC;
  render_blend : D3D11_RENDER_TARGET_BLEND_DESC;
  bstate : ID3D11BlendState;
begin
  // ZeroMemory(@rasterizer_desc, SizeOf(rasterizer_desc)); all members are set, so this isn't needed
  if assigned(FRenderStates[rsFILLMODE]) then rasterizer_desc.FillMode := D3D11_FILL_MODE(FRenderStates[rsFILLMODE].Value)
  else rasterizer_desc.FillMode := D3D11_FILL_SOLID;
  if assigned(FRenderStates[rsCULLMODE]) then rasterizer_desc.Cullmode := EnumCullModeToD3D11Cullmode(EnumCullmode(FRenderStates[rsCULLMODE].Value))
  else rasterizer_desc.Cullmode := D3D11_CULL_BACK; // aka CCW
  rasterizer_desc.FrontCounterClockwise := False;
  rasterizer_desc.DepthBias := 0;
  rasterizer_desc.DepthBiasClamp := 0;
  rasterizer_desc.SlopeScaledDepthBias := 0;
  rasterizer_desc.DepthClipEnable := true;
  rasterizer_desc.ScissorEnable := False;
  rasterizer_desc.MultisampleEnable := False;
  rasterizer_desc.AntialiasedLineEnable := False;

  CheckDX11Error(Device.CreateRasterizerState(rasterizer_desc, state), 'TDirectX11Device.DrawPrimitive create rasterizer state failed!');
  DeviceContext.RSSetState(state);

  // ZeroMemory(@depthstencil_desc, SizeOf(D3D11_DEPTH_STENCILOP_DESC)); all members are set, so this isn't needed
  if assigned(FRenderStates[rsZENABLE]) then depthstencil_desc.DepthEnable := Boolean(FRenderStates[rsZENABLE].Value)
  else depthstencil_desc.DepthEnable := true;
  if not depthstencil_desc.DepthEnable then depthstencil_desc.DepthWriteMask := D3D11_DEPTH_WRITE_MASK_ZERO
  else if assigned(FRenderStates[rsZWRITEENABLE]) then
  begin
    if Boolean(FRenderStates[rsZWRITEENABLE].Value) then depthstencil_desc.DepthWriteMask := D3D11_DEPTH_WRITE_MASK_ALL
    else depthstencil_desc.DepthWriteMask := D3D11_DEPTH_WRITE_MASK_ZERO;
  end
  else depthstencil_desc.DepthWriteMask := D3D11_DEPTH_WRITE_MASK_ALL;
  if not depthstencil_desc.DepthEnable then depthstencil_desc.DepthFunc := D3D11_COMPARISON_ALWAYS
  else if assigned(FRenderStates[rsZFUNC]) then depthstencil_desc.DepthFunc := D3D11_COMPARISON_FUNC(FRenderStates[rsZFUNC].Value)
  else depthstencil_desc.DepthFunc := D3D11_COMPARISON_LESS;

  // stencil
  if assigned(FRenderStates[rsSTENCILENABLE]) then depthstencil_desc.StencilEnable := Boolean(FRenderStates[rsSTENCILENABLE].Value)
  else depthstencil_desc.StencilEnable := False;
  if assigned(FRenderStates[rsSTENCILREF]) then stencil_ref := Cardinal(FRenderStates[rsSTENCILREF].Value)
  else stencil_ref := 0;
  depthstencil_desc.StencilReadMask := D3D11_DEFAULT_STENCIL_READ_MASK;
  depthstencil_desc.StencilWriteMask := D3D11_DEFAULT_STENCIL_WRITE_MASK;

  // front face stencil
  if assigned(FRenderStates[rsSTENCILFUNC]) then depthstencil_desc.FrontFace.StencilFunc := D3D11_COMPARISON_FUNC(FRenderStates[rsSTENCILFUNC].Value)
  else depthstencil_desc.FrontFace.StencilFunc := D3D11_COMPARISON_ALWAYS;
  if assigned(FRenderStates[rsSTENCILFAIL]) then depthstencil_desc.FrontFace.StencilFailOp := D3D11_STENCIL_OP(FRenderStates[rsSTENCILFAIL].Value)
  else depthstencil_desc.FrontFace.StencilFailOp := D3D11_STENCIL_OP_KEEP;
  if assigned(FRenderStates[rsSTENCILZFAIL]) then depthstencil_desc.FrontFace.StencilDepthFailOp := D3D11_STENCIL_OP(FRenderStates[rsSTENCILZFAIL].Value)
  else depthstencil_desc.FrontFace.StencilDepthFailOp := D3D11_STENCIL_OP_KEEP;
  if assigned(FRenderStates[rsSTENCILPASS]) then depthstencil_desc.FrontFace.StencilPassOp := D3D11_STENCIL_OP(FRenderStates[rsSTENCILPASS].Value)
  else depthstencil_desc.FrontFace.StencilPassOp := D3D11_STENCIL_OP_KEEP;
  // backface stencil
  if assigned(FRenderStates[rsCCW_STENCILFUNC]) then depthstencil_desc.BackFace.StencilFunc := D3D11_COMPARISON_FUNC(FRenderStates[rsCCW_STENCILFUNC].Value)
  else depthstencil_desc.BackFace.StencilFunc := D3D11_COMPARISON_ALWAYS;
  if assigned(FRenderStates[rsCCW_STENCILFAIL]) then depthstencil_desc.BackFace.StencilFailOp := D3D11_STENCIL_OP(FRenderStates[rsCCW_STENCILFAIL].Value)
  else depthstencil_desc.BackFace.StencilFailOp := D3D11_STENCIL_OP_KEEP;
  if assigned(FRenderStates[rsCCW_STENCILZFAIL]) then depthstencil_desc.BackFace.StencilDepthFailOp := D3D11_STENCIL_OP(FRenderStates[rsCCW_STENCILZFAIL].Value)
  else depthstencil_desc.BackFace.StencilDepthFailOp := D3D11_STENCIL_OP_KEEP;
  if assigned(FRenderStates[rsCCW_STENCILPASS]) then depthstencil_desc.BackFace.StencilPassOp := D3D11_STENCIL_OP(FRenderStates[rsCCW_STENCILPASS].Value)
  else depthstencil_desc.BackFace.StencilPassOp := D3D11_STENCIL_OP_KEEP;

  CheckDX11Error(Device.CreateDepthStencilState(depthstencil_desc, dstate), 'TDirectX11Device.DrawPrimitive create depthstencil state failed!');
  DeviceContext.OMSetDepthStencilState(dstate, stencil_ref);

  ZeroMemory(@blend_desc, SizeOf(blend_desc));
  blend_desc.AlphaToCoverageEnable := False;
  blend_desc.IndependentBlendEnable := False;

  ZeroMemory(@render_blend, SizeOf(render_blend));
  if assigned(FRenderStates[rsALPHABLENDENABLE]) then render_blend.BlendEnable := Boolean(FRenderStates[rsALPHABLENDENABLE].Value)
  else render_blend.BlendEnable := False;
  if assigned(FRenderStates[rsSRCBLEND]) then render_blend.SrcBlend := EnumBlendToD3D11Blend(EnumBlend(FRenderStates[rsSRCBLEND].Value))
  else render_blend.SrcBlend := D3D11_BLEND_ONE;
  if assigned(FRenderStates[rsDESTBLEND]) then render_blend.DestBlend := EnumBlendToD3D11Blend(EnumBlend(FRenderStates[rsDESTBLEND].Value))
  else render_blend.DestBlend := D3D11_BLEND_ZERO;
  if assigned(FRenderStates[rsBLENDOP]) then render_blend.BlendOp := EnumBlendOpToD3D11BlendOp(EnumBlendOp(FRenderStates[rsBLENDOP].Value))
  else render_blend.BlendOp := D3D11_BLEND_OP_ADD;
  if assigned(FRenderStates[rsSRCBLENDALPHA]) then render_blend.SrcBlendAlpha := EnumBlendToD3D11Blend(EnumBlend(FRenderStates[rsSRCBLENDALPHA].Value))
  else render_blend.SrcBlendAlpha := D3D11_BLEND_ONE;
  if assigned(FRenderStates[rsDESTBLENDALPHA]) then render_blend.DestBlendAlpha := EnumBlendToD3D11Blend(EnumBlend(FRenderStates[rsDESTBLENDALPHA].Value))
  else render_blend.DestBlendAlpha := D3D11_BLEND_ONE;
  if assigned(FRenderStates[rsBLENDOPALPHA]) then render_blend.BlendOpAlpha := EnumBlendOpToD3D11BlendOp(EnumBlendOp(FRenderStates[rsBLENDOPALPHA].Value))
  else render_blend.BlendOpAlpha := D3D11_BLEND_OP_ADD;
  render_blend.RenderTargetWriteMask := ord(D3D11_COLOR_WRITE_ENABLE_ALL);

  for i := 0 to Length(blend_desc.Rendertarget) - 1 do
  begin
    blend_desc.Rendertarget[i] := render_blend;
  end;

  CheckDX11Error(Device.CreateBlendState(blend_desc, bstate), 'TDirectX11Device.DrawPrimitive create blendstate failed!');
  DeviceContext.OMSetBlendState(bstate, TFourSingleArray(RVector4(1)), $FFFFFFFF);
end;

procedure TDirectX11Device.ApplySamplerstates;
var
  i : EnumTextureSlot;
  Samplerstates : array [EnumTextureSlot] of ID3D11SamplerState;
begin
  for i := low(EnumTextureSlot) to high(EnumTextureSlot) do
  begin
    Samplerstates[i] := GetRealSamplerState(i, GetSamplerState(i));
  end;
  DeviceContext.VSSetSamplers(0, Length(Samplerstates), Samplerstates[low(EnumTextureSlot)]);
  DeviceContext.PSSetSamplers(0, Length(Samplerstates), Samplerstates[low(EnumTextureSlot)]);
end;

procedure TDirectX11Device.BeginScene;
begin

end;

procedure TDirectX11Device.ChangeResolution(const NewResolution : RIntVector2);
begin
  FResolution.Size := NewResolution;
  UpdateSwapchain;
end;

procedure TDirectX11Device.Clear(Flags : SetClearFlags; Color : RColor; z : Single; Stencil : DWord);
var
  Rendertarget : TDirectX11Rendertarget;
  ClearFlags : Cardinal;
begin
  for Rendertarget in FRendertarget do
    if assigned(Rendertarget) then
    begin
      if (cfTarget in Flags) then DeviceContext.ClearRenderTargetView(Rendertarget.RawRTV, TFourSingleArray(Color.RGBA));
      if ([cfZBuffer, cfStencil] * Flags <> []) and assigned(Rendertarget.DepthStencilbuffer) then
      begin
        ClearFlags := 0;
        if cfZBuffer in Flags then ClearFlags := ClearFlags or D3D11_CLEAR_DEPTH;
        if cfStencil in Flags then ClearFlags := ClearFlags or D3D11_CLEAR_STENCIL;
        DeviceContext.ClearDepthStencilView(TDirectX11DepthStencilBuffer(Rendertarget.DepthStencilbuffer).RawDepthStencilView, ClearFlags, z, Stencil);
      end;
    end;
end;

function TDirectX11Device.CreateDepthStencilBuffer(Width, Height : Cardinal) : TDepthStencilBuffer;
begin
  Result := TDirectX11DepthStencilBuffer.CreateDepthStencilBuffer(self, Width, Height);
end;

destructor TDirectX11Device.Destroy;
begin
  FreeAndNil(ConstantBufferManagerManager);
  DeviceReference := nil;
  FBackbufferTexture.Free;
  // Freed by the TGFXD
  // FSettings.Free;
  inherited;
end;

function PrimitiveToVertexCount(PrimitiveType : EnumPrimitveType; PrimitiveCount : Cardinal) : Cardinal;
begin
  Result := 0;
  if PrimitiveCount <= 0 then exit;
  case PrimitiveType of
    ptPointlist : Result := PrimitiveCount;
    ptLinelist : Result := PrimitiveCount * 2;
    ptLinestrip : Result := PrimitiveCount + 1;
    ptTrianglelist : Result := PrimitiveCount * 3;
    ptTrianglestrip : Result := PrimitiveCount + 2;
  end;
end;

procedure TDirectX11Device.DrawPrimitive(PrimitiveType : EnumPrimitveType; StartIndex, PrimitiveCount : Cardinal);
begin
  ApplyRenderstates;
  ApplySamplerstates;
  SetTopology(PrimitiveType);
  DeviceContext.Draw(PrimitiveToVertexCount(PrimitiveType, PrimitiveCount), PrimitiveToVertexCount(PrimitiveType, StartIndex));
end;

procedure TDirectX11Device.DrawIndexedPrimitive(PrimitiveType : EnumPrimitveType; BaseVertexIndex : integer; MinVertexIndex, NumVertices, StartIndex, primCount : Cardinal);
begin
  ApplyRenderstates;
  ApplySamplerstates;
  SetTopology(PrimitiveType);
  DeviceContext.DrawIndexed(PrimitiveToVertexCount(PrimitiveType, primCount), StartIndex, BaseVertexIndex);
end;

procedure TDirectX11Device.SetTopology(Topo : EnumPrimitveType);
var
  D11Topo : D3D11_PRIMITIVE_TOPOLOGY;
begin
  case Topo of
    ptPointlist : D11Topo := D3D11_PRIMITIVE_TOPOLOGY_POINTLIST;
    ptLinelist : D11Topo := D3D11_PRIMITIVE_TOPOLOGY_LINELIST;
    ptLinestrip : D11Topo := D3D11_PRIMITIVE_TOPOLOGY_LINESTRIP;
    ptTrianglelist : D11Topo := D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
    ptTrianglestrip : D11Topo := D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;
  else
    begin
      assert(False);
      exit;
    end;
  end;
  DeviceContext.IASetPrimitiveTopology(D11Topo);
end;

procedure TDirectX11Device.Initialize(Handle : HWND; Settings : TDeviceSettings);
var
  swap_chain_desc : DXGI_SWAP_CHAIN_DESC;
  feature_level_supported : D3D_FEATURE_LEVEL;
  createDeviceFlags : Cardinal;
  hr : HRESULT;
  pBackbuffer : ID3D11Texture2D;
  factory : IDXGIFactory;
  dxgidevice : IDXGIDevice;
  isPerfHUD : Boolean;
  perfhudadaptername : string;
  nAdapter, i : integer;
  adapter, selectedAdapter : IDXGIAdapter;
  adapter_desc : DXGI_ADAPTER_DESC;
  driver_type : D3D_DRIVER_TYPE;
  requested_feature_levels : TArray<D3D_FEATURE_LEVEL>;
begin
  FSettings := Settings;
  // Initialize swap chain
  ZeroMemory(@swap_chain_desc, SizeOf(swap_chain_desc));
  swap_chain_desc.BufferCount := 1;
  swap_chain_desc.BufferDesc.Width := Settings.Resolution.Width;
  swap_chain_desc.BufferDesc.Height := Settings.Resolution.Height;
  swap_chain_desc.BufferDesc.Format := DXGI_FORMAT_R8G8B8A8_UNORM;
  swap_chain_desc.BufferDesc.RefreshRate.Numerator := 0;
  if Settings.Vsync then
      swap_chain_desc.BufferDesc.RefreshRate.Denominator := 0
  else
      swap_chain_desc.BufferDesc.RefreshRate.Denominator := 1;
  swap_chain_desc.BufferUsage := DXGI_USAGE_RENDER_TARGET_OUTPUT;
  swap_chain_desc.OutputWindow := Handle;
  case Settings.AntialiasingLevel of
    aaNone, aaEdge : swap_chain_desc.SampleDesc.Count := 1;
    aa2x : swap_chain_desc.SampleDesc.Count := 2;
    aa4x : swap_chain_desc.SampleDesc.Count := 3;
  end;
  swap_chain_desc.SampleDesc.Quality := 0;
  swap_chain_desc.Windowed := true;
  swap_chain_desc.SwapEffect := DXGI_SWAP_EFFECT_DISCARD;

  // initialize device and swapchain together
  assert(Settings.HAL, 'TDirectX11Device.Initialize: HAL is a must!');

  createDeviceFlags := 0;
  selectedAdapter := nil;
  driver_type := D3D_DRIVER_TYPE_HARDWARE;
  {$IFDEF DEBUG}
  if not FSettings.SuppressDebugLayer then createDeviceFlags := createDeviceFlags or D3D11_CREATE_DEVICE_DEBUG;

  // enable perfhud
  nAdapter := 0;
  adapter := nil;
  selectedAdapter := nil;
  CreateDXGIFactory(IDXGIFactory, factory);
  while (factory.EnumAdapters(nAdapter, adapter) <> DXGI_ERROR_NOT_FOUND) do
  begin
    if assigned(adapter) then
    begin
      ZeroMemory(@adapter_desc, SizeOf(adapter_desc));
      adapter.GetDesc(adapter_desc);
    end;
    isPerfHUD := true;
    perfhudadaptername := 'NVIDIA PerfHUD';
    for i := 0 to Length(perfhudadaptername) do
        isPerfHUD := isPerfHUD and (perfhudadaptername[i + 1] = adapter_desc.Description[i]);
    if (nAdapter = 0) and isPerfHUD then
    begin
      selectedAdapter := adapter;
      driver_type := D3D_DRIVER_TYPE_REFERENCE;
    end;
    nAdapter := nAdapter + 1;
  end;
  {$ENDIF}
  requested_feature_levels := TArray<D3D_FEATURE_LEVEL>.Create(
    D3D_FEATURE_LEVEL_11_0,
    D3D_FEATURE_LEVEL_10_1,
    D3D_FEATURE_LEVEL_10_0);

  hr := D3D11CreateDeviceAndSwapChain(
    selectedAdapter,                  // default graphic adapter
    driver_type,                      // driver type, hal
    0,                                // dll for software rasterizer, not needed
    createDeviceFlags,                // flags, debugflag set in debug
    @requested_feature_levels[0],     // requested feature level
    Length(requested_feature_levels), // number of elements in feature_level_requested array
    D3D11_SDK_VERSION,                // SDK version, fix
    @swap_chain_desc,                 // swap chain description, resolution etc.
    FSwapChain,
    FDevice,
    feature_level_supported,
    FDeviceContext);

  CheckDX11Error(hr, 'TDirectX11Device.Initialize: Device couldn''t be initialized.');
  if hr <> S_OK then
    if hr = E_FAIL then
        raise EGraphicInitError.Create('Attempted to create a device with the debug layer enabled and the layer is not installed.')
    else
        raise EGraphicInitError.Create('Error while initializing the graphic device: DirectX 11 couldn''t be initialized!');

  DeviceReference := self;

  // DX11 always support deferred shading
  FSettings.CanDeferredShading := true;

  // get and set backbuffer
  CheckDX11Error(FSwapChain.GetBuffer(0, ID3D11Texture2D, pBackbuffer), 'TDirectX11Device.Initialize: Get backbuffer failed!');
  FBackbufferTexture := TDirectX11Texture.CreateRaw(pBackbuffer, Settings.Resolution.Size, self);
  FBackbuffer := TDirectX11Rendertarget.CreateRaw(FBackbufferTexture, TDirectX11DepthStencilBuffer.CreateDepthStencilBuffer(self, Settings.Resolution.Width, Settings.Resolution.Height), self);
  SetRendertargets([FBackbuffer]);

  ConstantBufferManagerManager := TConstantbufferManagerManager.Create;

  // prevent Alt-Enter handling by DXGI
  FDevice.QueryInterface(IDXGIDevice, dxgidevice);
  dxgidevice.GetParent(IDXGIAdapter, adapter);
  adapter.GetParent(IDXGIFactory, factory);
  factory.MakeWindowAssociation(Handle, DXGI_MWA_NO_WINDOW_CHANGES or DXGI_MWA_NO_ALT_ENTER);
end;

procedure TDirectX11Device.Present(SourceRect, DestRect : PRect; WindowOverride : HWND);
var
  RefreshFlag : integer;
begin
  if FSettings.Vsync then RefreshFlag := Max(1, Min(4, FSettings.VSyncLevel))
  else RefreshFlag := 0;
  CheckDX11Error(FSwapChain.Present(RefreshFlag, 0), 'TDirectX11Device.Present: Present failed!');
  FSetShader := nil;
  FSetConstantBuffers := [];
end;

procedure TDirectX11Device.EndScene;
begin

end;

function TDirectX11Device.GetDedicatedVideoMemory : Int64;
var
  factory : IDXGIFactory2;
  info : DXGI_ADAPTER_DESC2;
  adapter : IDXGIAdapter2;
  i : integer;
begin
  Result := inherited;
  try
    if not CheckDX11Error(CreateDXGIFactory1(IDXGIFactory2, factory), 'TDirectX11Device.GetDedicatedVideoMemory: CreateDXGIFactory1 failed.') then;
    begin
      for i := 0 to 10 do
      begin
        if CheckDX11Ok(factory.EnumAdapters(i, IDXGIAdapter(adapter))) then
        begin
          if not CheckDX11Error(adapter.GetDesc2(info), 'TDirectX11Device.GetDedicatedVideoMemory: GetDesc2 failed.') then
          begin
            Result := Max(Result, info.DedicatedVideoMemory);
          end;
        end
        else
            break;
      end;
    end;
  except
    // mute any errors
  end;
end;

function TDirectX11Device.GetMaxMRT : byte;
begin
  Result := D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT;
end;

function TDirectX11Device.GetRealRenderState(Renderstate : EnumRenderstate) : Cardinal;
begin
  Result := 0;
end;

function TDirectX11Device.GetRendertarget(index : integer) : TRendertarget;
begin
  assert(Length(FRendertarget) < index);
  Result := FRendertarget[index];
end;

function TDirectX11Device.GetUsedVideoMemory : Int64;
var
  factory : IDXGIFactory4;
  info : DXGI_QUERY_VIDEO_MEMORY_INFO;
  adapter : IDXGIAdapter3;
begin
  Result := inherited;
  try
    if not CheckDX11Error(CreateDXGIFactory1(IDXGIFactory4, factory), 'TDirectX11Device.GetDedicatedVideoMemory: CreateDXGIFactory1 failed.') then
    begin
      if not CheckDX11Error(factory.EnumAdapters(0, IDXGIAdapter(adapter)), 'TDirectX11Device.GetDedicatedVideoMemory: EnumAdapters failed.') then
      begin
        if not CheckDX11Error(adapter.QueryVideoMemoryInfo(0, DXGI_MEMORY_SEGMENT_GROUP_LOCAL, info), 'TDirectX11Device.GetDedicatedVideoMemory: QueryVideoMemoryInfo failed.') then
            Result := info.CurrentUsage;
      end;
    end;
  except
    // mute any errors
  end;
end;

function TDirectX11Device.GetVideoMemoryInfo : string;
var
  factory : IDXGIFactory2;
  info : DXGI_ADAPTER_DESC2;
  adapter : IDXGIAdapter2;
  i : integer;
begin
  Result := inherited;
  try
    if not CheckDX11Error(CreateDXGIFactory1(IDXGIFactory2, factory), 'TDirectX11Device.GetDedicatedVideoMemory: CreateDXGIFactory1 failed.') then;
    begin
      for i := 0 to 10 do
      begin
        if CheckDX11Ok(factory.EnumAdapters(i, IDXGIAdapter(adapter))) then
        begin
          if not CheckDX11Error(adapter.GetDesc2(info), 'TDirectX11Device.GetDedicatedVideoMemory: GetDesc2 failed.') then
          begin
            Result := Result + PChar(@info.Description[0]) + sLineBreak;
            Result := Result + 'DedicatedVideoMemory: ' + HString.IntToStrBandwidth(info.DedicatedVideoMemory, 0, 'MB') + sLineBreak;
            Result := Result + 'DedicatedSystemMemory: ' + HString.IntToStrBandwidth(info.DedicatedSystemMemory, 0, 'MB') + sLineBreak;
            Result := Result + 'SharedSystemMemory: ' + HString.IntToStrBandwidth(info.SharedSystemMemory, 0, 'MB') + sLineBreak;
          end;
        end
        else
            break;
      end;
    end;
  except
    // mute any errors
  end;
end;

procedure TDirectX11Device.SaveScreenshotToFile(Filename : string);
var
  texture_desc : D3D11_TEXTURE2D_DESC;
  Texture : ID3D11Texture2D;
begin
  ZeroMemory(@texture_desc, SizeOf(texture_desc));
  texture_desc.ArraySize := 1;
  texture_desc.BindFlags := 0;
  texture_desc.CPUAccessFlags := 0;
  texture_desc.Format := DXGI_FORMAT_R8G8B8A8_UNORM;
  texture_desc.Width := FSettings.Resolution.Width;
  texture_desc.Height := FSettings.Resolution.Height;
  texture_desc.MipLevels := 1;
  texture_desc.MiscFlags := 0;
  texture_desc.SampleDesc.Count := 1;
  texture_desc.SampleDesc.Quality := 0;
  texture_desc.Usage := D3D11_USAGE_DEFAULT;

  CheckDX11Error(Device.CreateTexture2D(texture_desc, nil, Texture), 'TDirectX11Device.SaveScreenshotToFile: Failed to create copy target.');
  DeviceContext.CopyResource(Texture, TDirectX11Texture(FBackbufferTexture).FTexture);

  CheckDX11Error(D3DX11SaveTextureToFile(DeviceContext, Texture, D3DX11_IFF_PNG, PChar(Filename)), 'TDirectX11Device.SaveScreenshotToFile: Failed to save screenshot to file.');
end;

procedure TDirectX11Device.SetShader(Shader : TShader);
begin
  if FSetShader <> Shader then
  begin
    DeviceContext.VSSetShader(TDirectX11Shader(Shader).FVertexShader, nil, 0);
    DeviceContext.PSSetShader(TDirectX11Shader(Shader).FPixelShader, nil, 0);
    FSetShader := Shader;
  end;
end;

procedure TDirectX11Device.SetConstantBuffers(Constantbuffers : AConstantBuffers);
var
  SetBuffers : AConstantBuffers;
  temp : AConstantBuffers;
  SetRange : RIntRange;
  i : integer;
begin
  if Length(Constantbuffers) <= 0 then exit;
  SetRange := RIntRange.CreateInvalid;
  for i := 0 to Length(Constantbuffers) - 1 do
    if (i >= Length(SetBuffers)) or (Constantbuffers[i] <> SetBuffers[i]) then SetRange.Extend(i);
  // all buffers are matching, we don't need to set any
  if SetRange.IsInvalid then exit;
  temp := nil;
  DeviceContext.VSSetConstantBuffers(SetRange.Minimum, SetRange.Size, Constantbuffers[SetRange.Minimum]);
  DeviceContext.PSSetConstantBuffers(SetRange.Minimum, SetRange.Size, Constantbuffers[SetRange.Minimum]);
  FSetConstantBuffers := Constantbuffers;
end;

procedure TDirectX11Device.SetIndices(Indices : TIndexBuffer);
begin
  DeviceContext.IASetIndexBuffer(TDirectX11IndexBuffer(Indices).RawIndexBuffer, DXGI_FORMAT_R32_UINT, 0);
end;

procedure TDirectX11Device.SetRealRenderState(Renderstate : EnumRenderstate; Value : Cardinal);
begin

end;

function TDirectX11Device.GetRealSamplerState(index : EnumTextureSlot; const SamplerState : RSamplerstate) : ID3D11SamplerState;
var
  D11SamplerState : ID3D11SamplerState;
  sampler_desc : D3D11_SAMPLER_DESC;
  function EnumTextureFilterToD3D11_FILTER(Texturefilter : EnumTextureFilter) : D3D11_FILTER;
  begin
    case Texturefilter of
      tfAuto : Result := EnumTextureFilterToD3D11_FILTER(GetAutoTextureFilter);
      tfPoint : Result := D3D11_FILTER_MIN_MAG_MIP_POINT;
      tfLinear : Result := D3D11_FILTER_MIN_MAG_MIP_LINEAR;
      tfAnisotropic : Result := D3D11_FILTER_ANISOTROPIC;
    else
      raise System.SysUtils.ENotImplemented.Create('EnumTextureFilterToD3D11_FILTER: Unknown filter type!');
    end;
  end;

begin
  if not assigned(FPreparedSamplers[SamplerState.MipMapLodBias = 0][SamplerState.Filter][SamplerState.AddressMode]) or (SamplerState.MipMapLodBias <> 0) then
  begin
    ZeroMemory(@sampler_desc, SizeOf(D3D11_SAMPLER_DESC));
    sampler_desc.Filter := EnumTextureFilterToD3D11_FILTER(SamplerState.Filter);
    sampler_desc.AddressU := D3D11_TEXTURE_ADDRESS_MODE(ord(SamplerState.AddressMode));
    sampler_desc.AddressV := sampler_desc.AddressU;
    sampler_desc.AddressW := sampler_desc.AddressU;
    sampler_desc.MipLODBias := SamplerState.MipMapLodBias;
    sampler_desc.MaxAnisotropy := 16;
    sampler_desc.ComparisonFunc := D3D11_COMPARISON_NEVER;
    sampler_desc.MinLOD := Single.MinValue;
    sampler_desc.MaxLOD := Single.MaxValue;
    CheckDX11Error(Device.CreateSamplerState(sampler_desc, D11SamplerState), 'TDirectX11Device.SetRealSamplerState: Error on creating the sampler state!');
    FPreparedSamplers[SamplerState.MipMapLodBias = 0][SamplerState.Filter][SamplerState.AddressMode] := D11SamplerState;
  end;
  Result := FPreparedSamplers[SamplerState.MipMapLodBias = 0][SamplerState.Filter][SamplerState.AddressMode];
end;

procedure TDirectX11Device.SetRendertargets(Targets : array of TRendertarget);
var
  rtvs : TArray<ID3D11RenderTargetView>;
begin
  FRendertarget := HArray.Map<TRendertarget, TDirectX11Rendertarget>(Targets,
    function(const rt : TRendertarget) : TDirectX11Rendertarget
    begin
      Result := TDirectX11Rendertarget(rt);
    end);
  assert(Length(FRendertarget) >= 1);
  assert(assigned(FRendertarget[0]));
  rtvs := HArray.Map<TDirectX11Rendertarget, ID3D11RenderTargetView>(FRendertarget,
    function(const rt : TDirectX11Rendertarget) : ID3D11RenderTargetView
    begin
      if assigned(rt) then Result := rt.RawRTV
      else Result := nil;
    end);
  if assigned(FRendertarget[0].DepthStencilbuffer) then
      FDeviceContext.OMSetRenderTargets(Length(rtvs), rtvs[0], TDirectX11DepthStencilBuffer(FRendertarget[0].DepthStencilbuffer).RawDepthStencilView)
  else
  begin
    // use default depthstencilbuffer if size matches
    if assigned(FDefaultDepthStencilBuffer) and (Targets[0].Size = FDefaultDepthStencilBuffer.Size) then
        FDeviceContext.OMSetRenderTargets(Length(rtvs), rtvs[0], TDirectX11DepthStencilBuffer(FDefaultDepthStencilBuffer.DepthStencilbuffer).RawDepthStencilView)
      // use backbuffer depthstencilbuffer if size matches
    else if (Targets[0].Size = FBackbuffer.Size) then
        FDeviceContext.OMSetRenderTargets(Length(rtvs), rtvs[0], TDirectX11DepthStencilBuffer(FBackbuffer.DepthStencilbuffer).RawDepthStencilView)
      // else unset depthstencilbuffer
    else
        FDeviceContext.OMSetRenderTargets(Length(rtvs), rtvs[0], nil);
  end;
  SetViewport(FRendertarget[0].Width, FRendertarget[0].Height);
end;

procedure TDirectX11Device.SetStreamSource(StreamNumber : longword; pStreamData : TVertexBuffer; OffsetInBytes, Stride : longword);
begin
  DeviceContext.IASetVertexBuffers(0, 1, TDirectX11VertexBuffer(pStreamData).RawVertexbuffer, @Stride, @OffsetInBytes);
end;

procedure TDirectX11Device.SetVertexDeclaration(vertexdeclaration : TVertexDeclaration);
begin
  DeviceContext.IASetInputLayout(TDirectX11VertexDeclaration(vertexdeclaration).InputLayout);
end;

procedure TDirectX11Device.SetViewport(Width, Height : Cardinal);
var
  Viewport : D3D11_VIEWPORT;
begin
  Viewport.TopLeftX := 0;
  Viewport.TopLeftY := 0;
  Viewport.Width := Width;
  Viewport.Height := Height;
  Viewport.MinDepth := 0.0;
  Viewport.MaxDepth := 1.0;
  FDeviceContext.RSSetViewports(1, @Viewport);
end;

procedure TDirectX11Device.UpdateSwapchain;
var
  pBackbuffer : ID3D11Texture2D;
begin
  FBackbufferTexture.Free;
  FBackbuffer.Free;
  CheckDX11Error(FSwapChain.ResizeBuffers(0, FSettings.Resolution.Width, FSettings.Resolution.Height, DXGI_FORMAT_UNKNOWN, 0), 'TDirectX11Device.ChangeResolution: ResizeBuffers failed!');
  CheckDX11Error(FSwapChain.GetBuffer(0, ID3D11Texture2D, pBackbuffer), 'TDirectX11Device.ChangeResolution: Get backbuffer failed!');
  FBackbufferTexture := TDirectX11Texture.CreateRaw(pBackbuffer, FSettings.Resolution.Size, self);
  FBackbuffer := TDirectX11Rendertarget.CreateRaw(FBackbufferTexture, TDirectX11DepthStencilBuffer.CreateDepthStencilBuffer(self, FSettings.Resolution.Width, FSettings.Resolution.Height), self);
  SetRendertargets([FBackbuffer]);
end;

{ TDirectX11Textur }

procedure TDirectX11Texture.BuildTexture;
var
  texture_desc : D3D11_TEXTURE2D_DESC;
  temp : ID3D11Texture2D;
begin
  ZeroMemory(@texture_desc, SizeOf(texture_desc));
  texture_desc.Width := FWidth;
  texture_desc.Height := FHeight;
  if FMipLevels <= 0 then
  begin
    FMipMapHandling := mhGenerate;
    texture_desc.MipLevels := 1;
    texture_desc.ArraySize := 1;
  end
  else
  begin
    texture_desc.MipLevels := FMipLevels;
    texture_desc.ArraySize := FMipLevels;
  end;
  texture_desc.SampleDesc.Count := 1;
  if usFrequentlyWriteable in FUsage then
  begin
    texture_desc.Usage := D3D11_USAGE_DYNAMIC;
    FDynamic := true;
  end
  else texture_desc.Usage := D3D11_USAGE_DEFAULT;
  texture_desc.Format := FormatToDXGI_FORMAT(FFormat);
  CheckChannelOrder(texture_desc.Format);
  if usRenderTarget in FUsage then texture_desc.BindFlags := D3D11_BIND_RENDER_TARGET or D3D11_BIND_SHADER_RESOURCE
  else texture_desc.BindFlags := D3D11_BIND_SHADER_RESOURCE;
  if [usFrequentlyWriteable] * FUsage <> [] then texture_desc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;
  CheckDX11Error(TDirectX11Device(FDevice).Device.CreateTexture2D(texture_desc, nil, temp),
    'TDirectX11Textur.iCreateTexture failed! (Width: %d, Height: %d, MipLevels: %d, Usage: %d, Format: %d)',
    [
    texture_desc.Width,
    texture_desc.Height,
    texture_desc.MipLevels,
    ord(texture_desc.Usage),
    ord(texture_desc.Format)
    ]);
  FTexture := temp;
  FSRV := nil; // renew shader resource view
  if [usWriteable, usReadable] * FUsage <> [] then
      CreateStaging;
end;

procedure TDirectX11Texture.CheckChannelOrder(Format : DXGI_FORMAT);
begin
  FChannelOrderInverted := Format in [DXGI_FORMAT_R8G8B8A8_UNORM];
end;

constructor TDirectX11Texture.CreateRaw(Texture : ID3D11Texture2D; Size : RIntVector2; Device : TDevice);
begin
  Create(Device);
  FWidth := Size.x;
  FHeight := Size.y;
  FTexture := Texture;
end;

destructor TDirectX11Texture.Destroy;
begin
  if CanDestroyed then
  begin
    inherited;
    FTexture := nil;
  end;
end;

procedure TDirectX11Texture.DisableMipLevels;
var
  texture_desc : D3D11_TEXTURE2D_DESC;
  temp : ID3D11Texture2D;
begin
  if FMipLevels <> 1 then
  begin
    FMipLevels := 1;
    ZeroMemory(@texture_desc, SizeOf(texture_desc));
    texture_desc.Width := Width;
    texture_desc.Height := Height;
    texture_desc.MipLevels := FMipLevels;
    texture_desc.ArraySize := FMipLevels;
    texture_desc.SampleDesc.Count := 1;
    if usFrequentlyWriteable in FUsage then
    begin
      texture_desc.Usage := D3D11_USAGE_DYNAMIC;
      FDynamic := true;
    end
    else texture_desc.Usage := D3D11_USAGE_DEFAULT;
    texture_desc.Format := FormatToDXGI_FORMAT(FFormat);
    if usRenderTarget in FUsage then texture_desc.BindFlags := D3D11_BIND_RENDER_TARGET or D3D11_BIND_SHADER_RESOURCE
    else texture_desc.BindFlags := D3D11_BIND_SHADER_RESOURCE;
    if [usFrequentlyWriteable] * FUsage <> [] then texture_desc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;
    CheckDX11Error(
      TDirectX11Device(FDevice).Device.CreateTexture2D(texture_desc, nil, temp), 'TDirectX11Texture.DisableMipLevels failed!');
    TDirectX11Device(FDevice).DeviceContext.CopySubresourceRegion(temp, 0, 0, 0, 0, FTexture, 0, nil);

    FTexture := temp;
  end;
end;

procedure TDirectX11Texture.FastCopy(Target : TTexture);
begin
  if (Width = Target.Width) and (Height = Target.Height) and (FFormat = TDirectX11Texture(Target).FFormat) and (FUsage = TDirectX11Texture(Target).FUsage) then
      FDevice.DeviceContext.CopyResource(TDirectX11Texture(Target).FTexture, FTexture)
  else assert(False, 'TDirectX11Texture.FastCopy: You can only fast copy equal created textures!');
end;

function TDirectX11Texture.FastCopyAvailable : Boolean;
begin
  Result := true;
end;

function TDirectX11Texture.getSRV : ID3D11ShaderResourceView;
begin
  if not assigned(FSRV) and assigned(RawTexture) then
  begin
    CheckDX11Error(TDirectX11Device(FDevice).Device.CreateShaderResourceView(RawTexture, nil, FSRV), 'TDirectX11Texture.getSRV failed!')
  end;
  Result := FSRV
end;

class function TDirectX11Texture.iCreateTexture(const Width, Height, MipLevels : Cardinal; Usage : SetUsage; Format : EnumTextureFormat; Device : TDevice) : TTexture;
var
  res : TDirectX11Texture;
begin
  res := TDirectX11Texture.Create(Device);
  res.FDevice := TDirectX11Device(Device);
  res.FWidth := Width;
  res.FHeight := Height;
  res.FFormat := Format;
  res.FUsage := Usage;
  res.FMipLevels := MipLevels;
  res.BuildTexture;
  Result := res;
end;

procedure TDirectX11Texture.CreateStaging;
var
  texture_desc : D3D11_TEXTURE2D_DESC;
  temp : ID3D11Texture2D;
begin
  assert(not FDynamic, 'TDirectX11Texture.CreateStaging: Create Staging buffer for dynamic texture is not intended!');
  ZeroMemory(@texture_desc, SizeOf(texture_desc));
  texture_desc.Width := Width;
  texture_desc.Height := Height;
  texture_desc.MipLevels := 1;
  texture_desc.ArraySize := 1;
  texture_desc.SampleDesc.Count := 1;
  texture_desc.Format := FormatToDXGI_FORMAT(FFormat);
  texture_desc.Usage := D3D11_USAGE_STAGING;
  texture_desc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE or D3D11_CPU_ACCESS_READ;
  texture_desc.BindFlags := 0;
  CheckDX11Error(TDirectX11Device(FDevice).Device.CreateTexture2D(texture_desc, nil, temp), 'TDirectX11Textur.iCreateTexture staging failed!');
  FStaging := temp;
  // fetch texture data for read, after that the staging is always equal to the texture
  if usReadable in FUsage then
  begin
    if FMipLevels = 1 then
        TDirectX11Device(FDevice).DeviceContext.CopyResource(FStaging, FTexture)
    else
        TDirectX11Device(FDevice).DeviceContext.CopySubresourceRegion(FStaging, 0, 0, 0, 0, FTexture, 0, nil);
  end;
end;

class function TDirectX11Texture.iCreateTextureFromFile(Filename : string; Device : TDevice; FailSilently : Boolean; MipmapHandling : EnumMipMapHandling; ResizeToPow2 : Boolean) : TTexture;
var
  TypedResult : TDirectX11Texture;
begin
  TypedResult := TDirectX11Texture.Create(Device);
  Result := TypedResult;
  TypedResult.FDevice := TDirectX11Device(Device);
  TypedResult.FMipMapHandling := MipmapHandling;
  TypedResult.FResizeToPow2 := ResizeToPow2;
  // TypedResult.FFileName := EngineTextureFilename;
  // ContentManager.SubscribeToFile(TypedResult.Filename, TypedResult.LoadRawTextureFromMemoryStream);
  if FileExists(Filename) then
  begin
    TypedResult.FFileName := Filename;
    if SameText(ENGINETEXTURE_FORMAT_EXTENSION, ExtractFileExt(Filename)) then
        ContentManager.SubscribeToFile(TypedResult.Filename, TypedResult.LoadRawTextureFromMemoryStream)
    else
        ContentManager.SubscribeToFile(TypedResult.Filename, TypedResult.LoadTextureFromMemoryStream);
  end;
end;

function ImagingFormatToEnumTextureFormat(Format : TImageFormat) : EnumTextureFormat;
begin
  case Format of
    ifUnknown : Result := tfUNKNOWN;
    ifR8G8B8 : Result := tfR8G8B8;
    ifA8R8G8B8 : Result := tfA8R8G8B8;
  else
    begin
      Result := tfUNKNOWN;
      assert(False, 'ImagingFormatToEnumTextureFormat: TImageFormat ID' + Inttostr(ord(Format)) + ' not present in conversion list!');
    end;
  end;
end;

procedure TDirectX11Texture.LoadRawTextureFromMemoryStream(const FilePath : string; const Filecontent : TMemoryStream);
var
  EngineRawTexture : TEngineRawTexture;
  texture_desc : D3D11_TEXTURE2D_DESC;
  initial_data : TArray<D3D11_SUBRESOURCE_DATA>;
  pinitial_data : PD3D11_SUBRESOURCE_DATA;
  temp : ID3D11Texture2D;
  i, MipMapIndex, QualityOffset : integer;
  MipLevels : UInt32;
begin
  // clear SRV so it will be updated
  FSRV := nil;
  if Filecontent.Size = 0 then
      raise Exception.Create('TDirectX11Texture.LoadTextureFromMemoryStream: Texture ''' + FilePath + ''' is corrupt and can''t be loaded!');
  Filecontent.Position := 0;
  EngineRawTexture := TEngineRawTexture.CreateFromMemoryStream(Filecontent);

  try
    QualityOffset := TextureQualityManager.GetOffset(FilePath);
    if FMipMapHandling = mhSkip then
        MipLevels := 1
    else
        MipLevels := EngineRawTexture.MipLevels;
    ZeroMemory(@texture_desc, SizeOf(texture_desc));
    texture_desc.Width := EngineRawTexture.Width;
    texture_desc.Height := EngineRawTexture.Height;
    texture_desc.ArraySize := 1;
    texture_desc.SampleDesc.Count := 1;
    texture_desc.Usage := D3D11_USAGE_IMMUTABLE;
    texture_desc.Format := FormatToDXGI_FORMAT(EngineRawTexture.Format);
    CheckChannelOrder(texture_desc.Format);
    texture_desc.BindFlags := D3D11_BIND_SHADER_RESOURCE;

    FWidth := texture_desc.Width;
    FHeight := texture_desc.Height;
    // fill intial data with mipmap data
    texture_desc.MipLevels := Max(1, integer(MipLevels) - QualityOffset);
    texture_desc.Width := EngineRawTexture.Width div (1 shl Min(texture_desc.MipLevels - 1, QualityOffset));
    texture_desc.Height := EngineRawTexture.Height div (1 shl Min(texture_desc.MipLevels - 1, QualityOffset));
    setlength(initial_data, texture_desc.MipLevels);
    assert(Length(EngineRawTexture.Data) >= integer(MipLevels));

    for i := 0 to texture_desc.MipLevels - 1 do
    begin
      MipMapIndex := Min(texture_desc.MipLevels - 1, i + QualityOffset);
      initial_data[i].pSysMem := EngineRawTexture.Data[MipMapIndex];
      initial_data[i].SysMemPitch := EngineRawTexture.Data[MipMapIndex].Width * SizeOf(Cardinal);
      initial_data[i].SysMemSlicePitch := 0; // unused for 2D-Textures
    end;

    pinitial_data := @initial_data[0];

    CheckDX11Error(TDirectX11Device(FDevice).Device.CreateTexture2D(texture_desc, pinitial_data, temp), Format('TDirectX11Texture.LoadTextureFromMemoryStream: Error creating TGA-texture (%s) from data!', [FilePath]));
    FTexture := temp;
    FFormat := DXGI_FORMATToFormat(texture_desc.Format);
    FMipLevels := texture_desc.MipLevels;
  finally
    EngineRawTexture.Free;
  end;
  FUsage := [];
end;

procedure TDirectX11Texture.LoadTextureFromMemoryStream(const FilePath : string; const Filecontent : TMemoryStream);
const
  MIPMAP_COLORS : array [0 .. 4] of Cardinal = ($FF00FF00, $FF00FFFF, $FF0000FF, $FFFFFF00, $FFFF0000);
var
  ImageInfo : D3DX11_IMAGE_LOAD_INFO;
  MetaImageInfo : D3DX11_IMAGE_INFO;
  ImageData : TImageData;
  texture_desc : D3D11_TEXTURE2D_DESC;
  initial_data : TArray<D3D11_SUBRESOURCE_DATA>;
  temp : ID3D11Texture2D;
  MipMaps : TArray<RSuperPointer<Cardinal>>;
  Original, FormerMipMap : RSuperPointer<Cardinal>;
  LeftTop : RIntVector2;
  x, y, QualityOffset, MipMapIndex : integer;
  i : integer;
  EngineRawTexture : TEngineRawTexture;
  EngineRawTextureFilename : string;

  function GetNumMipMapLevels(Width, Height : LongInt) : LongInt;
  begin
    Result := Min(HMath.Log2Floor(Width), HMath.Log2Floor(Height));
  end;

  function Filter(x, y : integer; Original : RSuperPointer<Cardinal>) : Cardinal;
  var
    c1, c2, c3, c4 : RColor;
  begin
    c1 := MipMaps[i - 1].ReadValue2D(x * 2, y * 2);
    c2 := MipMaps[i - 1].ReadValue2D(x * 2 + 1, y * 2);
    c3 := MipMaps[i - 1].ReadValue2D(x * 2, y * 2 + 1);
    c4 := MipMaps[i - 1].ReadValue2D(x * 2 + 1, y * 2 + 1);
    Result := RColor.Average([c1, c2, c3, c4]).AsCardinal;
  end;

begin
  // clear SRV so it will be updated
  FSRV := nil;
  if Filecontent.Size = 0 then
      raise Exception.Create('TDirectX11Texture.LoadTextureFromMemoryStream: Texture ''' + FilePath + ''' is corrupt and can''t be loaded!');
  Filecontent.Position := 0;
  if DebugShowMipmapping or HArray.Contains(['tga', 'psd', 'png', 'jpg'], DetermineMemoryFormat(Filecontent.Memory, Filecontent.Size)) then
  begin
    if LoadImageFromMemory(Filecontent.Memory, Filecontent.Size, ImageData) then
    begin
      QualityOffset := TextureQualityManager.GetOffset(FilePath);

      // directx 11 doesn't support textures without alpha channel
      if ImageData.Format = ifR8G8B8 then
          ConvertImage(ImageData, ifA8R8G8B8);
      ZeroMemory(@texture_desc, SizeOf(texture_desc));
      texture_desc.Width := ImageData.Width;
      texture_desc.Height := ImageData.Height;
      texture_desc.ArraySize := 1;
      texture_desc.SampleDesc.Count := 1;
      texture_desc.Usage := D3D11_USAGE_IMMUTABLE;
      texture_desc.Format := FormatToDXGI_FORMAT(ImagingFormatToEnumTextureFormat(ImageData.Format));
      CheckChannelOrder(texture_desc.Format);
      texture_desc.BindFlags := D3D11_BIND_SHADER_RESOURCE;

      MipMaps := nil;
      if FMipMapHandling = mhSkip then
      begin
        // load flat (no mipmaps) image data
        setlength(MipMaps, 1);
        // assume that loaded image data using 4 bytes per texel
        assert(ImageData.Size div (ImageData.Height * ImageData.Width) = SizeOf(Cardinal));
        MipMaps[0] := RSuperPointer<Cardinal>.Create2D(ImageData.Bits, ImageData.Width, ImageData.Height);
      end
      else if FMipMapHandling = mhLoad then
      begin
        texture_desc.Width := ImageData.Width div 2;
        setlength(MipMaps, GetNumMipMapLevels(texture_desc.Width, texture_desc.Height));
        Original := RSuperPointer<Cardinal>.Create2D(ImageData.Bits, ImageData.Width, ImageData.Height);
        LeftTop := RIntVector2.ZERO;

        for i := 0 to Length(MipMaps) - 1 do
        begin
          if i = 0 then MipMaps[i] := RSuperPointer<Cardinal>.CreateMem2D(Original.Width div 2, Original.Height)
          else MipMaps[i] := RSuperPointer<Cardinal>.CreateMem2D(FormerMipMap.Size div 2);
          for y := 0 to MipMaps[i].Height - 1 do
            for x := 0 to MipMaps[i].Width - 1 do
            begin
              if not DebugShowMipmapping then
              begin
                MipMaps[i].WriteValue2D(x, y, Original.ReadValue2D(LeftTop.x + x, LeftTop.y + y));
              end
              else MipMaps[i].WriteValue2D(x, y, MIPMAP_COLORS[HMath.Clamp(i - 1, 0, Length(MIPMAP_COLORS) - 1)]);
            end;
          FormerMipMap := MipMaps[i];
          LeftTop := LeftTop + RIntVector2.Create(FormerMipMap.Width, FormerMipMap.Height div 2);
        end;
      end
      else
      begin
        setlength(MipMaps, Max(1, GetNumMipMapLevels(texture_desc.Width, texture_desc.Height)));
        MipMaps[0] := RSuperPointer<Cardinal>.Create2D(ImageData.Bits, ImageData.Width, ImageData.Height);

        for i := 1 to Length(MipMaps) - 1 do
        begin
          MipMaps[i] := RSuperPointer<Cardinal>.CreateMem2D(MipMaps[i - 1].Size div 2);
          for y := 0 to MipMaps[i].Height - 1 do
            for x := 0 to MipMaps[i].Width - 1 do
            begin
              if not DebugShowMipmapping then
              begin
                MipMaps[i].WriteValue2D(x, y, Filter(x, y, MipMaps[i - 1]));
              end
              else MipMaps[i].WriteValue2D(x, y, MIPMAP_COLORS[HMath.Clamp(i - 1, 0, Length(MIPMAP_COLORS) - 1)]);
            end;
        end;
      end;
      FWidth := texture_desc.Width;
      FHeight := texture_desc.Height;
      // fill intial data with mipmap data
      texture_desc.MipLevels := Max(1, Length(MipMaps) - QualityOffset);
      texture_desc.Width := FWidth div (1 shl Min(texture_desc.MipLevels - 1, QualityOffset));
      texture_desc.Height := FHeight div (1 shl Min(texture_desc.MipLevels - 1, QualityOffset));
      setlength(initial_data, texture_desc.MipLevels);

      for i := 0 to texture_desc.MipLevels - 1 do
      begin
        MipMapIndex := Min(texture_desc.MipLevels - 1, i + QualityOffset);
        initial_data[i].pSysMem := MipMaps[MipMapIndex];
        initial_data[i].SysMemPitch := MipMaps[MipMapIndex].Width * SizeOf(Cardinal);
        initial_data[i].SysMemSlicePitch := 0; // unused for 2D-Textures
      end;

      if assigned(FDevice) then
          CheckDX11Error(TDirectX11Device(FDevice).Device.CreateTexture2D(texture_desc, @initial_data[0], temp), Format('TDirectX11Texture.LoadTextureFromMemoryStream: Error creating TGA-texture (%s) from data!', [FilePath]));
      FTexture := temp;
      FFormat := DXGI_FORMATToFormat(texture_desc.Format);
      FMipLevels := texture_desc.MipLevels;

      if CREATE_RAW_TEXTURE then
      begin
        assert(QualityOffset = 0, 'TDirectX11Texture.LoadTextureFromMemoryStream: Raw textures must not created with lower quality!');
        EngineRawTextureFilename := TEngineRawTexture.ConvertFileNameToRaw(FilePath);
        EngineRawTexture := TEngineRawTexture.CreateFromData(MipMaps, FFormat, FilePath);
        EngineRawTexture.SaveToFile(EngineRawTextureFilename);
        EngineRawTexture.Free;
      end;

      FreeImage(ImageData);
      if FMipMapHandling = mhLoad then MipMaps[0].Free;
      for i := 1 to Length(MipMaps) - 1 do
          MipMaps[i].Free;
    end
    else
        raise Exception.CreateFmt('TDirectX11Textur.iCreateTextureFromStream: Error occurs on create texture (%s) from stream.', [FilePath]);
  end
  else
  begin
    raise ENotSupportedException.CreateFmt('Loading %s is currently disabled!', [DetermineMemoryFormat(Filecontent.Memory, Filecontent.Size)]);
    CheckDX11Error(D3DX11GetImageInfoFromMemory(Filecontent.Memory, Filecontent.Size, nil, @MetaImageInfo, nil), Format('TDirectX11Texture.LoadTextureFromMemoryStream: Error obtaining meta info of texture (%s)!', [FilePath]));
    FWidth := MetaImageInfo.Width;
    FHeight := MetaImageInfo.Height;
    FFormat := DXGI_FORMATToFormat(MetaImageInfo.Format);
    CheckChannelOrder(MetaImageInfo.Format);
    FMipLevels := MetaImageInfo.MipLevels;

    ImageInfo.Width := D3DX11_DEFAULT;
    ImageInfo.Height := D3DX11_DEFAULT;
    ImageInfo.Depth := D3DX11_DEFAULT;
    ImageInfo.FirstMipLevel := D3DX11_DEFAULT;
    if FMipMapHandling = mhSkip then ImageInfo.MipLevels := 1
    else
    begin
      // take miplevels from file if they are present
      if FMipLevels = 1 then
      begin
        ImageInfo.MipLevels := D3DX11_DEFAULT;
        FMipLevels := HMath.Log2Ceil(Min(FWidth, FHeight)) + 1;
      end
      else ImageInfo.MipLevels := FMipLevels;
    end;
    ImageInfo.Usage := D3D11_USAGE(D3DX11_DEFAULT);
    ImageInfo.BindFlags := D3DX11_DEFAULT;
    ImageInfo.CPUAccessFlags := D3DX11_DEFAULT;
    ImageInfo.MiscFlags := D3DX11_DEFAULT;
    ImageInfo.Format := DXGI_FORMAT_FROM_FILE;
    ImageInfo.Filter := D3DX11_DEFAULT;
    ImageInfo.MipFilter := D3DX11_DEFAULT;;
    ImageInfo.pSrcInfo := nil;

    CheckDX11Error(D3DX11CreateTextureFromMemory(TDirectX11Device(FDevice).FDevice, Filecontent.Memory, Filecontent.Size, @ImageInfo, nil, FTexture, nil), Format('TDirectX11Texture.LoadTextureFromMemoryStream: Error at loading of texture (%s)!', [FilePath]));
  end;
  FUsage := [];
end;

procedure TDirectX11Texture.Lock;
begin
  LowLock();
  inherited;
end;

function TDirectX11Texture.LowLock(Lockrect : PRect) : Pointer;
var
  mapped_resource : D3D11_MAPPED_SUBRESOURCE;
begin
  assert((Width = Naechste2erPotenz(Width)) and (Height = Naechste2erPotenz(Height)), 'TDirectX11Texture.LowLock: Ensure locked texture to be power of 2 otherweise refactoring locking code!');
  assert(Lockrect = nil, 'TDirectX11Texture.LowLock: Only full locks currently supported!');
  ZeroMemory(@mapped_resource, SizeOf(D3D11_MAPPED_SUBRESOURCE));
  if FDynamic then
  begin
    assert(assigned(FTexture));
    CheckDX11Error(TDirectX11Device(FDevice).DeviceContext.Map(FTexture, 0, D3D11_MAP_WRITE_DISCARD, 0, mapped_resource), 'TDirectX11VertexBuffer.LowLock dynamic failed!');
  end
  else
  begin
    assert(assigned(FStaging));
    CheckDX11Error(TDirectX11Device(FDevice).DeviceContext.Map(FStaging, 0, D3D11_MAP_READ_WRITE, 0, mapped_resource), 'TDirectX11VertexBuffer.LowLock static failed!');
  end;
  FLocked := mapped_resource.pData;
  FRowSize := mapped_resource.RowPitch;
  Result := FLocked;
  FIsLocked := true;
end;

procedure TDirectX11Texture.MakeLockable;
begin
  if FDynamic then exit;
  if FUsage * [usReadable, usWriteable] = [usReadable, usWriteable] then exit;
  FUsage := FUsage + [usReadable, usWriteable];
  CreateStaging;
end;

procedure TDirectX11Texture.Resize(newWidth, newHeight : integer);
begin
  if (newWidth <= 0) or (newHeight <= 0) or ((newWidth = self.Width) and (newHeight = self.Height)) then exit;
  if FIsLocked then
      raise EInvalidOperation.Create('TDirectX11Texture.Resize: Cannot resize locked texture!');
  // only resize dynamically created textures
  if self.Filename = '' then
  begin
    FWidth := newWidth;
    FHeight := newHeight;
    BuildTexture;
    if assigned(FRendertarget) then TDirectX11Rendertarget(FRendertarget).InitializeTarget(self);
  end
  else
      raise ENotImplemented.Create('TDirectX11Texture.Resize: Trying to resize a texture loaded from file!');
end;

procedure TDirectX11Texture.Unlock;
begin
  inherited;
  if FIsLocked then
  begin
    if FDynamic then
    begin
      FDevice.DeviceContext.Unmap(FTexture, 0);
    end
    else
    begin
      FDevice.DeviceContext.Unmap(FStaging, 0);
      if FMipLevels = 1 then
          FDevice.DeviceContext.CopyResource(FTexture, FStaging)
      else
          FDevice.DeviceContext.CopySubresourceRegion(FTexture, 0, 0, 0, 0, FStaging, 0, nil);
    end;
    FLocked := nil;
    FIsLocked := False;
  end;
end;

{ TDirectX11Rendertarget }

constructor TDirectX11Rendertarget.CreateRaw(Texture : TTexture; DepthStencilbuffer : TDepthStencilBuffer; Device : TDirectX11Device);
begin
  FDevice := Device;
  FDepthStencilBuffer := DepthStencilbuffer;
  InitializeTarget(Texture);
end;

procedure TDirectX11Rendertarget.InitializeTarget(Target : TTexture);
begin
  FWidth := Target.Width;
  FHeight := Target.Height;
  CheckDX11Error(TDirectX11Device(FDevice).Device.CreateRenderTargetView(TDirectX11Texture(Target).RawTexture, nil, FRenderTargetView), 'TDirectX11Rendertarget.InitializeTarget failed!');
  // reinitialize depth buffer with new sizes
  if HasOwnDepthBuffer then
      NeedsOwnDepthBuffer;
end;

{ TDirectX11Shader }

procedure TDirectX11Shader.BuildConstantbuffers(Shaderstr : string);
begin
  FConstantbufferManager.Free;
  FConstantbufferManager := ConstantBufferManagerManager.CreateBuffers(Shaderstr, FDevice);
end;

procedure TDirectX11Shader.CommitChanges;
begin
  // there is no such a limitation in DX11 with Shader-Begin and End so omit this
end;

procedure TDirectX11Shader.CompileShader(Shaderstr : AnsiString);
var
  blob, errors : ID3DBlob;
  Flags1 : Cardinal;
  Hash : string;
  Path : string;
  IsCompiled : Boolean;
  SaveStream : TFileStream;
  LoadStream : TMemoryStream;

  procedure SanitizeShader;
  var
    regex : TRegex;
    temp : string;
  begin
    temp := string(Shaderstr);
    temp := '#define DX11' + sLineBreak + temp;
    // remove techniques, assume they are at the end of the file
    temp := HString.TrimAfter('technique', temp);
    // pixelshader output must be SV_TARGET
    temp := TRegex.SubstituteDirect(temp, '(#define COLOR_\d) COLOR(\d)', '\1 SV_TARGET\2', nil, [roMultiLine, roIgnoreCase]);
    regex := TRegex.Create('(struct PSOutput.*?\})', [roSingleLine, roIgnoreCase]);
    temp := regex.Substitute(temp,
      function(const input : string) : string
      begin
        Result := TRegex.SubstituteDirect(input, ': ?COLOR(\d);', ': SV_TARGET\1;', nil, [roSingleLine, roIgnoreCase]);
      end);
    // textures must be fully specified
    temp := TRegex.SubstituteDirect(temp, 'texture (\w*?(?: : register\(t\d\)));', 'Texture2D \1;', nil, [roMultiLine, roIgnoreCase]);
    // samplers are not bound to textures
    temp := TRegex.Replace(temp, 'texture = \<.*?\>;', '', [roMultiLine, roIgnoreCase]);
    temp := TRegex.SubstituteDirect(temp, 'sampler (.*?) = sampler_state', 'SamplerState \1', nil, [roSingleLine, roIgnoreCase]);
    // tex2D intrinsic is outdated
    temp := TRegex.SubstituteDirect(temp, 'tex2D\((.*?),(.*?)\)', '\1.Sample(\1Sampler, \2)',
      function(index : integer; const item : string) : string
      begin
        if index = 1 then Result := item.Replace('Sampler', '', [rfIgnoreCase])
        else Result := item;
      end, [roSingleLine, roIgnoreCase]);
    // tex2Dlod intrinsic is outdated                                                                   //'\1.Load(float3((\2) * viewport_size, 0))'
    temp := TRegex.SubstituteDirect(temp, 'tex2Dlod\((.*?), ?float4\((.*?), ?0\.?0?, ?(\d)\.?\d?\)\)', '\1.SampleLevel(\1Sampler, \2, \3)',
      function(index : integer; const item : string) : string// \1.SampleLevel(\1Sampler, \2, \3)
      begin
        if index = 1 then Result := item.Replace('Sampler', '', [rfIgnoreCase])
        else Result := item;
      end, [roSingleLine, roIgnoreCase]);
    // position between stages is now passed by SV_POSITION
    temp := TRegex.SubstituteDirect(temp, 'struct (.*?)\}', 'struct \1}',
      function(index : integer; const item : string) : string
      begin
        if item.StartsWith('VSInput', true) then Result := item
        else Result := TRegex.SubstituteDirect(item, 'POSITION(\d)', 'SV_POSITION\1');
      end, [roSingleLine, roIgnoreCase]);
    // VPOS is now SV_POSITION
    temp := TRegex.SubstituteDirect(temp, 'float\d ([\w\d_]+?) : VPOS;', 'float4 \1 : SV_POSITION;', nil, [roIgnoreCase, roMultiLine]);
    Shaderstr := AnsiString(temp);
  end;

begin
  SanitizeShader;
  Hash := MD5(string(Shaderstr));

  Flags1 := D3DCOMPILE_ENABLE_STRICTNESS or D3DCOMPILE_PACK_MATRIX_COLUMN_MAJOR or D3DCOMPILE_WARNINGS_ARE_ERRORS;
  {$IFDEF DEBUG}
  Flags1 := Flags1 or D3DCOMPILE_DEBUG or D3DCOMPILE_PREFER_FLOW_CONTROL or D3DCOMPILE_SKIP_OPTIMIZATION;
  {$ELSE}
  Flags1 := Flags1 or D3DCOMPILE_OPTIMIZATION_LEVEL3;
  {$ENDIF}
  Path := AbsolutePath('\PrecompiledDX11ShadersCached\' + Hash + '.cvs');
  IsCompiled := FileExists(Path);
  if not IsCompiled then
  begin
    Path := AbsolutePath('\PrecompiledDX11Shaders\' + Hash + '.cvs');
    IsCompiled := FileExists(Path);
  end;

  blob := nil;
  if IsCompiled then
  begin
    LoadStream := ContentManager.FileToMemory(Path);
    // loaded file seems to be corrupted
    if LoadStream.Size > 0 then
    begin
      try
        CheckDX11Error(D3DCreateBlob(LoadStream.Size, blob), 'TDirectX11Shader.CompileShader: Load precompiled cvs shader failed!');
        LoadStream.ReadBuffer(blob.GetBufferPointer^, LoadStream.Size);
      except
        blob := nil;
      end;
    end;
  end;
  if not assigned(blob) then
  begin
    // Vertexshader
    errors := nil;
    CheckDX11Error(D3DCompile(
      @Shaderstr[1],
      Length(Shaderstr) * SizeOf(AnsiChar),
      'vertexshader',
      nil,
      nil,
      'MegaVertexShader',
      'vs_4_0',
      Flags1,
      0,
      blob,
      errors), 'TDirectX11Shader.CompileShader failed!');
    ProcessShaderErrors(Shaderstr, errors);
    if assigned(blob) then
    begin
      ForceDirectories(AbsolutePath('\PrecompiledDX11Shaders\'));
      SaveStream := TFileStream.Create(AbsolutePath('\PrecompiledDX11Shaders\' + Hash + '.cvs'), fmCreate);
      SaveStream.WriteBuffer(blob.GetBufferPointer^, blob.GetBufferSize);
      SaveStream.Free;
    end
    else
        raise Exception.Create('Vertexshader compilation returned empty blob and no errors!');
  end;
  CheckDX11Error(TDirectX11Device(FDevice).Device.CreateVertexShader(blob.GetBufferPointer, blob.GetBufferSize, nil, @FVertexShader), 'TDirectX11Shader.CompileShader: CreateVertexShader failed.');

  // Pixelshader
  Path := AbsolutePath('\PrecompiledDX11ShadersCached\' + Hash + '.cps');
  IsCompiled := FileExists(Path);
  if not IsCompiled then
  begin
    Path := AbsolutePath('\PrecompiledDX11Shaders\' + Hash + '.cps');
    IsCompiled := FileExists(Path);
  end;

  blob := nil;
  if IsCompiled then
  begin
    LoadStream := ContentManager.FileToMemory(Path);
    // loaded file seems to be corrupted
    if LoadStream.Size > 0 then
    begin
      try
        CheckDX11Error(D3DCreateBlob(LoadStream.Size, blob), 'TDirectX11Shader.CompileShader: Load precompiled cps shader failed!');
        LoadStream.ReadBuffer(blob.GetBufferPointer^, LoadStream.Size);
      except
        blob := nil;
      end;
    end;
  end;
  if not assigned(blob) then
  begin
    errors := nil;
    CheckDX11Error(D3DCompile(
      @Shaderstr[1],
      Length(Shaderstr) * SizeOf(AnsiChar),
      'pixelshader',
      nil,
      nil,
      'MegaPixelShader',
      'ps_4_0',
      Flags1,
      0,
      blob,
      errors), 'TDirectX11Shader.CompileShader failed!');
    ProcessShaderErrors(Shaderstr, errors);
    if assigned(blob) then
    begin
      ForceDirectories(AbsolutePath('\PrecompiledDX11Shaders\'));
      SaveStream := TFileStream.Create(AbsolutePath('\PrecompiledDX11Shaders\' + Hash + '.cps'), fmCreate);
      SaveStream.WriteBuffer(blob.GetBufferPointer^, blob.GetBufferSize);
      SaveStream.Free;
    end
    else
        raise Exception.Create('Pixelxshader compilation returned empty blob and no errors!');
  end;
  CheckDX11Error(TDirectX11Device(FDevice).Device.CreatePixelShader(blob.GetBufferPointer, blob.GetBufferSize, nil, FPixelShader), 'TDirectX11Shader.CompileShader: CreateVertexShader failed.');

  // build up constant buffers
  BuildConstantbuffers(string(Shaderstr));
end;

constructor TDirectX11Shader.Create(Device : TDevice);
begin
  inherited Create(Device);
end;

destructor TDirectX11Shader.Destroy;
begin
  if CanDestroyed then
  begin
    inherited;
    FConstantbufferManager.Free;
  end;
end;

class function TDirectX11Shader.iCreateShader(Device : TDevice) : TShader;
begin
  Result := TDirectX11Shader.Create(Device);
end;

procedure TDirectX11Shader.SetRealBoolean(const ConstantName : string; bool : Boolean);
begin
  SetRealShaderConstant(ConstantName, @bool, SizeOf(Boolean));
end;

procedure TDirectX11Shader.SetRealShaderConstant(const ConstantName : string; Value : Pointer; Size : integer);
begin
  FConstantbufferManager.SetShaderConstant(ConstantName, Value, Size);
end;

procedure TDirectX11Shader.SetRealTexture(const Slot : EnumTextureSlot; Texture : TTexture; ShaderTarget : EnumShaderType);
var
  slotindex : integer;
begin
  slotindex := ord(Slot);
  if assigned(Texture) then
  begin
    if ShaderTarget = stVertexShader then TDirectX11Device(FDevice).DeviceContext.VSSetShaderResources(slotindex, 1, TDirectX11Texture(Texture).ShaderResourceView);
    if ShaderTarget = stGeometryShader then TDirectX11Device(FDevice).DeviceContext.GSSetShaderResources(slotindex, 1, TDirectX11Texture(Texture).ShaderResourceView);
    if ShaderTarget = stPixelShader then TDirectX11Device(FDevice).DeviceContext.PSSetShaderResources(slotindex, 1, TDirectX11Texture(Texture).ShaderResourceView);
  end
  else
  begin
    if ShaderTarget = stVertexShader then TDirectX11Device(FDevice).DeviceContext.VSSetShaderResources(slotindex, 1, nil);
    if ShaderTarget = stGeometryShader then TDirectX11Device(FDevice).DeviceContext.GSSetShaderResources(slotindex, 1, nil);
    if ShaderTarget = stPixelShader then TDirectX11Device(FDevice).DeviceContext.PSSetShaderResources(slotindex, 1, nil);
  end;
end;

procedure TDirectX11Shader.ShaderBegin;
begin
  // set shaders and constantbuffers
  TDirectX11Device(FDevice).SetShader(self);

  FConstantbufferManager.SetConstantBuffers(TDirectX11Device(FDevice));
end;

procedure TDirectX11Shader.ShaderEnd;
begin
  // no cleanup steps needed
end;

procedure TDirectX11Shader.SetRealBoolean(const ConstantName : EnumDefaultShaderConstant; bool : Boolean);
begin
  SetRealShaderConstant(ConstantName, @bool, SizeOf(Boolean));
end;

procedure TDirectX11Shader.SetRealShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : integer);
begin
  FConstantbufferManager.SetShaderConstant(ConstantName, Value, Size);
end;

{ TDirectX11VertexDeclaration }

procedure TDirectX11VertexDeclaration.AddVertexElement(elemtype : EnumVertexElementType; Usage : EnumVertexElementUsage; Method : EnumVertexElementMethod; StreamID, UsageIndex : word);
var
  i : integer;
begin
  inherited;
  setlength(FElements, Length(FElements) + 1);
  i := high(FElements);
  ZeroMemory(@FElements[i], SizeOf(D3D11_INPUT_ELEMENT_DESC));
  // FElements[i].InputSlot := StreamID; SteamID not supported atm
  FElements[i].InputSlotClass := D3D11_INPUT_PER_VERTEX_DATA;
  case elemtype of
    etFloat1 : FElements[i].Format := DXGI_FORMAT_R32_FLOAT;
    etFloat2 : FElements[i].Format := DXGI_FORMAT_R32G32_FLOAT;
    etFloat3 : FElements[i].Format := DXGI_FORMAT_R32G32B32_FLOAT;
    etFloat4 : FElements[i].Format := DXGI_FORMAT_R32G32B32A32_FLOAT;
  else
    assert(False, 'TDirectX11VertexDeclaration.AddVertexElement: Mapping is missing!');
  end;
  FElements[i].SemanticIndex := UsageIndex;
  case Usage of
    euPosition : FElements[i].SemanticName := 'POSITION';
    euNormal : FElements[i].SemanticName := 'NORMAL';
    euColor : FElements[i].SemanticName := 'COLOR';
    euTexturecoordinate : FElements[i].SemanticName := 'TEXCOORD';
    euTangent : FElements[i].SemanticName := 'TANGENT';
    euBinormal : FElements[i].SemanticName := 'BINORMAL';
    euBlendWeight : FElements[i].SemanticName := 'BLENDWEIGHT';
    euBlendIndices : FElements[i].SemanticName := 'BLENDINDICES';
  end;
  if Length(FElements) = 1 then FElements[i].AlignedByteOffset := 0
  else FElements[i].AlignedByteOffset := D3D11_APPEND_ALIGNED_ELEMENT;
  FValidationBreaker := FValidationBreaker + 'float' + AnsiString(Inttostr((ord(elemtype) mod 4) + 1)) + ' varia' + AnsiString(Inttostr(i)) + ' : ' + FElements[i].SemanticName + AnsiString(Inttostr(FElements[i].SemanticIndex)) + ';';
end;

constructor TDirectX11VertexDeclaration.Create(Device : TDevice);
begin
  inherited Create(Device);
end;

destructor TDirectX11VertexDeclaration.Destroy;
begin
  if CanDestroyed then
  begin
    inherited;
  end;
end;

procedure TDirectX11VertexDeclaration.EndDeclaration;
var
  Shaderstr : AnsiString;
  blob, errors : ID3DBlob;
begin
  // bypass validation check
  Shaderstr := 'struct VSInput{' + FValidationBreaker + '};';
  Shaderstr := Shaderstr + 'struct VSOutput{float4 Position : POSITION0;};';
  Shaderstr := Shaderstr + 'VSOutput MegaVertexShader(VSInput vsin){VSOutput vsout;vsout.Position = 1;return vsout;}';
  blob := nil;
  errors := nil;
  CheckDX11Error(D3DCompile(
    @Shaderstr[1],
    Length(Shaderstr) * SizeOf(AnsiChar),
    'vertexshader',
    nil,
    nil,
    'MegaVertexShader',
    'vs_4_0',
    D3DCOMPILE_ENABLE_STRICTNESS or D3DCOMPILE_OPTIMIZATION_LEVEL3 or D3DCOMPILE_PACK_MATRIX_COLUMN_MAJOR or D3DCOMPILE_WARNINGS_ARE_ERRORS,
    0,
    blob,
    errors), 'TDirectX11VertexDeclaration.EndDeclaration compile fake shader failed!');
  ProcessShaderErrors(Shaderstr, errors);
  if not assigned(blob) then
      raise Exception.Create('TDirectX11VertexDeclaration.EndDeclaration compile fake shader failed!');
  // create vertexdeclaration
  CheckDX11Error(TDirectX11Device(FDevice).Device.CreateInputLayout(@FElements[0], Length(FElements), blob.GetBufferPointer, blob.GetBufferSize, FInputLayout), 'TDirectX11VertexDeclaration.EndDeclaration: VertexDeclaration couldn''t be created');
end;

class
  function TDirectX11VertexDeclaration.iCreateVertexDeclaration(Device : TDevice) : TVertexDeclaration;
begin
  Result := TDirectX11VertexDeclaration.Create(Device);
end;

{ TDirectX11VertexBuffer }

destructor TDirectX11VertexBuffer.Destroy;
begin
  if CanDestroyed then
  begin
    inherited;
  end
end;

class function TDirectX11VertexBuffer.iCreateVertexBuffer(Length : Cardinal; Usage : SetUsage; Device : TDevice; InitialData : Pointer) : TVertexBuffer;
var
  res : TDirectX11VertexBuffer;
  vb_desc : D3D11_BUFFER_DESC;
  initial_data : D3D11_SUBRESOURCE_DATA;
  pinitial_data : PD3D11_SUBRESOURCE_DATA;
begin
  assert(not(usReadable in Usage), 'TDirectX11VertexBuffer.iCreateVertexBuffer: Readable vertexbuffers are not implemented for DX11!');
  assert([usWriteable, usFrequentlyWriteable] * Usage <> [usWriteable, usFrequentlyWriteable], 'TDirectX11VertexBuffer.iCreateVertexBuffer: Don''t use usWriteable and usFrequentlyWriteable together!');
  res := TDirectX11VertexBuffer.Create(Device);
  // create real buffer used for rendering
  ZeroMemory(@vb_desc, SizeOf(vb_desc));
  res.FSize := Length;
  vb_desc.ByteWidth := Length;
  if usFrequentlyWriteable in Usage then
  begin
    res.FDynamic := true;
    vb_desc.Usage := D3D11_USAGE_DYNAMIC
  end
  else vb_desc.Usage := D3D11_USAGE_DEFAULT;
  vb_desc.BindFlags := D3D11_BIND_VERTEX_BUFFER or D3D11_BIND_SHADER_RESOURCE;
  if res.FDynamic then vb_desc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;
  // we ignore the possibility of structured buffers, because our buffers are accesses via helper function which do the same
  vb_desc.StructureByteStride := 0;

  // if there is initial data use it
  if assigned(InitialData) then
  begin
    // if there is no read/write and initial data, the buffer is static
    if Usage = [] then vb_desc.Usage := D3D11_USAGE_IMMUTABLE;
    initial_data.pSysMem := InitialData;
    initial_data.SysMemPitch := 0;
    initial_data.SysMemSlicePitch := 0;
    pinitial_data := @initial_data;
  end
  else pinitial_data := nil;

  CheckDX11Error(TDirectX11Device(Device).Device.CreateBuffer(vb_desc, pinitial_data, res.FVertexbuffer), 'TDirectX11VertexBuffer.iCreateVertexBuffer failed!');

  // create staging buffer for writing to the render buffer
  if usWriteable in Usage then
  begin
    ZeroMemory(@vb_desc, SizeOf(vb_desc));
    vb_desc.ByteWidth := Length;
    vb_desc.Usage := D3D11_USAGE_STAGING;
    vb_desc.BindFlags := 0;
    vb_desc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;

    CheckDX11Error(TDirectX11Device(Device).Device.CreateBuffer(vb_desc, nil, res.FStagingBuffer), 'TDirectX11VertexBuffer.iCreateVertexBuffer failed for staging buffer!');
  end;

  Result := res;
end;

procedure TDirectX11VertexBuffer.Lock();
begin
  LowLock([lfDiscard]);
  inherited;
end;

function TDirectX11VertexBuffer.LowLock(LockFlags : SetLockFlags) : Pointer;
var
  mapped_resource : D3D11_MAPPED_SUBRESOURCE;
begin
  assert([lfDiscard] = LockFlags, 'TDirectX11VertexBuffer.LowLock: Currently only lfDiscard supported for Lockflags!');
  if FDynamic then
  begin
    assert(assigned(FVertexbuffer));
    CheckDX11Error(TDirectX11Device(FDevice).DeviceContext.Map(FVertexbuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, mapped_resource), 'TDirectX11VertexBuffer.LowLock dynamic failed!');
  end
  else
  begin
    assert(assigned(FStagingBuffer));
    CheckDX11Error(TDirectX11Device(FDevice).DeviceContext.Map(FStagingBuffer, 0, D3D11_MAP_WRITE, 0, mapped_resource), 'TDirectX11VertexBuffer.LowLock static failed!');
  end;
  FLocked := mapped_resource.pData;
  Result := FLocked;
end;

procedure TDirectX11VertexBuffer.Unlock;
begin
  inherited;
  if FDynamic then
  begin
    TDirectX11Device(FDevice).DeviceContext.Unmap(FVertexbuffer, 0);
  end
  else
  begin
    TDirectX11Device(FDevice).DeviceContext.Unmap(FStagingBuffer, 0);
    TDirectX11Device(FDevice).DeviceContext.CopyResource(FVertexbuffer, FStagingBuffer);
  end;
end;

{ TDirectX11IndexBuffer }

destructor TDirectX11IndexBuffer.Destroy;
begin
  if CanDestroyed then
  begin
    inherited;
  end
end;

class function TDirectX11IndexBuffer.iCreateIndexBuffer(Length : longword; Usage : SetUsage; Format : EnumIndexBufferFormat; Device : TDevice; InitialData : Pointer) : TIndexBuffer;
var
  res : TDirectX11IndexBuffer;
  ib_desc : D3D11_BUFFER_DESC;
  initial_data : D3D11_SUBRESOURCE_DATA;
  pinitial_data : PD3D11_SUBRESOURCE_DATA;
begin
  assert(not(usReadable in Usage), 'TDirectX11IndexBuffer.iCreateVertexBuffer: Readable indebuffers are not implemented for DX11!');
  assert([usWriteable, usFrequentlyWriteable] * Usage <> [usWriteable, usFrequentlyWriteable], 'TDirectX11IndexBuffer.iCreateVertexBuffer: Don''t use usWriteable and usFrequentlyWriteable together!');
  res := TDirectX11IndexBuffer.Create(Device);
  // create real buffer used for rendering
  ZeroMemory(@ib_desc, SizeOf(ib_desc));
  res.FSize := Length;
  ib_desc.ByteWidth := Length;
  if usFrequentlyWriteable in Usage then
  begin
    res.FDynamic := true;
    ib_desc.Usage := D3D11_USAGE_DYNAMIC
  end
  else ib_desc.Usage := D3D11_USAGE_DEFAULT;
  ib_desc.BindFlags := D3D11_BIND_INDEX_BUFFER or D3D11_BIND_SHADER_RESOURCE;
  if res.FDynamic then ib_desc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;
  // we ignore the possibility of structured buffers, because our buffers are accesses via helper function which do the same
  ib_desc.StructureByteStride := 0;

  // if there is initial data use it
  if assigned(InitialData) then
  begin
    // if there is no read/write and initial data, the buffer is static
    if Usage = [] then ib_desc.Usage := D3D11_USAGE_IMMUTABLE;
    initial_data.pSysMem := InitialData;
    initial_data.SysMemPitch := 0;
    initial_data.SysMemSlicePitch := 0;
    pinitial_data := @initial_data;
  end
  else pinitial_data := nil;

  CheckDX11Error(TDirectX11Device(Device).Device.CreateBuffer(ib_desc, pinitial_data, res.FIndexbuffer), 'TDirectX11VertexBuffer.iCreateVertexBuffer failed!');

  // create staging buffer for writing to the render buffer
  if usWriteable in Usage then
  begin
    ZeroMemory(@ib_desc, SizeOf(ib_desc));
    ib_desc.ByteWidth := Length;
    ib_desc.Usage := D3D11_USAGE_STAGING;
    ib_desc.BindFlags := 0;
    ib_desc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;

    CheckDX11Error(TDirectX11Device(Device).Device.CreateBuffer(ib_desc, nil, res.FStagingBuffer), 'TDirectX11VertexBuffer.iCreateVertexBuffer failed for staging buffer!');
  end;

  Result := res;
end;

procedure TDirectX11IndexBuffer.Lock;
begin
  LowLock([lfDiscard]);
  inherited;
end;

function TDirectX11IndexBuffer.LowLock(LockFlags : SetLockFlags) : Pointer;
var
  mapped_resource : D3D11_MAPPED_SUBRESOURCE;
begin
  assert([lfDiscard] = LockFlags, 'TDirectX11IndexBuffer.LowLock: Currently only lfDiscard supported for Lockflags!');
  if FDynamic then
  begin
    assert(assigned(FIndexbuffer));
    CheckDX11Error(TDirectX11Device(FDevice).DeviceContext.Map(FIndexbuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, mapped_resource), 'TDirectX11IndexBuffer.LowLock dynamic failed!');
  end
  else
  begin
    assert(assigned(FStagingBuffer));
    CheckDX11Error(TDirectX11Device(FDevice).DeviceContext.Map(FStagingBuffer, 0, D3D11_MAP_WRITE, 0, mapped_resource), 'TDirectX11IndexBuffer.LowLock static failed!');
  end;
  FLocked := mapped_resource.pData;
  Result := FLocked;
end;

procedure TDirectX11IndexBuffer.Unlock;
begin
  inherited;
  if FDynamic then
  begin
    TDirectX11Device(FDevice).DeviceContext.Unmap(FIndexbuffer, 0);
  end
  else
  begin
    TDirectX11Device(FDevice).DeviceContext.Unmap(FStagingBuffer, 0);
    TDirectX11Device(FDevice).DeviceContext.CopyResource(FIndexbuffer, FStagingBuffer);
  end;
end;

{ TConstantbufferManagerManager }

function TConstantbufferManagerManager.Analyze(Shaderstr : string; Device : TDevice) : TConstantbufferManager;
var
  regex : TRegex;
  matches : TMatchCollection;
  i : integer;
  cbuffer : TConstantBuffer;
  defaultVariableName : EnumDefaultShaderConstant;
  variableName, bufferName, bufferDefinition : string;
begin
  Result := TConstantbufferManager.Create;
  Shaderstr := ResolveSimpleDefines(Shaderstr);
  // extract cbuffers
  regex := TRegex.Create('cbuffer ([\d\w]+).*?register\(b(\d)\).*?{(.*?)};', [roIgnoreCase, roSingleLine]);
  matches := regex.matches(Shaderstr);
  assert(matches.Count = HString.Count('cbuffer', Shaderstr), 'TConstantbufferManagerManager.Analyze: Wrong cbuffer-Syntax!');
  for i := 0 to matches.Count - 1 do
  begin
    assert(matches[i].Groups.Count = 4, 'TConstantbufferManagerManager.Analyze: Wrong cbuffer-Syntax!');
    if matches[i].Groups.Count = 4 then
    begin
      bufferName := matches[i].Groups[1].Value;
      bufferDefinition := matches[i].Groups[3].Value;
      if not FConstantBuffers.TryGetValue(bufferDefinition.ToLowerInvariant, cbuffer) then
      begin
        FLock.Acquire;
        if not FConstantBuffers.TryGetValue(bufferDefinition.ToLowerInvariant, cbuffer) then
        begin
          cbuffer := TConstantBuffer.Create(bufferDefinition, StrToInt(matches[i].Groups[2].Value), Device);
          FConstantBuffers.Add(bufferDefinition.ToLowerInvariant, cbuffer);
        end;
        FLock.Release;
      end;
      Result.FConstantBuffers.Add(bufferName, cbuffer);
    end;
  end;
  // build variable table
  for cbuffer in Result.FConstantBuffers.Values do
  begin
    for variableName in cbuffer.Variables.Keys do
    begin
      if not Result.FVariables.ContainsKey(variableName) then
          Result.FVariables.Add(variableName, cbuffer)
      else
          assert(False, 'TConstantbufferManagerManager.Analyze: Double declaration of cbuffer-variable ' + variableName + '!');
      for defaultVariableName := low(EnumDefaultShaderConstant) to high(EnumDefaultShaderConstant) do
        if DEFAULT_SHADER_CONSTANT_MAPPING[defaultVariableName] = variableName then
        begin
          if not assigned(Result.FDefaultVariables[defaultVariableName]) then
              Result.FDefaultVariables[defaultVariableName] := cbuffer;
          break;
        end;
    end;
  end;
end;

constructor TConstantbufferManagerManager.Create();
begin
  FConstantBuffers := TObjectDictionary<string, TConstantBuffer>.Create([doOwnsValues]);
  FLock := TCriticalSection.Create;
end;

function TConstantbufferManagerManager.CreateBuffers(Shaderstr : string; Device : TDevice) : TConstantbufferManager;
begin
  Result := Analyze(Shaderstr, Device);
end;

destructor TConstantbufferManagerManager.Destroy;
begin
  FConstantBuffers.Free;
  FLock.Free;
  inherited;
end;

function TConstantbufferManagerManager.ResolveSimpleDefines(Shaderstr : string) : string;
var
  IfDefines, Defines : TDictionary<string, string>;
  Lines : TArray<string>;
  DefineStack : TList<RTuple<string, string>>;
  Stackitem, temp : RTuple<string, string>;
  define : string;
  i : integer;
  function ResolveReplacements(str : string) : string;
  var
    replacement_key : string;
  begin
    Result := str;
    for replacement_key in Defines.Keys do
      if Result.Contains(replacement_key) then
      begin
        Result := Result.Replace(replacement_key, Defines[replacement_key], [rfReplaceAll]);
      end;
  end;

begin
  Defines := TDictionary<string, string>.Create;
  TRegex.MatchesForEach(Shaderstr, '\#define ([\w\d_]+) ([\d\.\w]+)',
    procedure(matchindex : integer; matches : TArray<string>)
    begin
      Defines.AddOrSetValue(matches[0], matches[1]);
    end, [roMultiLine]);
  IfDefines := TDictionary<string, string>.Create;
  TRegex.MatchesForEach(Shaderstr, '\#define ([\w\d_]+)',
    procedure(matchindex : integer; matches : TArray<string>)
    begin
      IfDefines.AddOrSetValue(matches[0], '');
    end, [roMultiLine]);
  Lines := Shaderstr.Split([sLineBreak], TStringSplitOptions.None);
  Result := '';
  DefineStack := TList < RTuple < string, string >>.Create;
  for i := 0 to Length(Lines) - 1 do
  begin
    if Lines[i].Replace(' ', '').Replace(#9, '').StartsWith('#if', true) then
    begin
      // open section
      // simple case #ifdef
      if TRegex.IsMatchOne(Lines[i], '\#ifdef ([\w\d_]+)', define, [roIgnoreCase, roSingleLine]) then
      begin
        Stackitem.a := define;
        Stackitem.b := '';
        DefineStack.Add(Stackitem);
      end
      else
      begin
        // not supported atm, simply pass
        Stackitem.a := '';
        Stackitem.b := '';
        DefineStack.Add(Stackitem);
      end
    end
    else if Lines[i].Replace(' ', '').Replace(#9, '').StartsWith('#endif', true) then
    begin
      // close section
      assert(DefineStack.Count > 0, 'TConstantbufferManagerManager.ResolveSimpleDefines: Found closing #endif without opening!');
      Stackitem := DefineStack.Last;
      DefineStack.Delete(DefineStack.Count - 1);
      if (Stackitem.a = '') or IfDefines.ContainsKey(Stackitem.a) then
      begin
        if DefineStack.Count > 0 then
        begin
          temp := DefineStack.Last;
          temp.b := temp.b + Stackitem.b;
          DefineStack[DefineStack.Count - 1] := temp;
        end
        else Result := Result + Stackitem.b;
      end;
    end
    else
    begin
      // write section content
      // if we are in at least one ifdef, push content to this item
      if DefineStack.Count > 0 then
      begin
        Stackitem := DefineStack.Last;
        Stackitem.b := Stackitem.b + ResolveReplacements(Lines[i]) + sLineBreak;
        DefineStack[DefineStack.Count - 1] := Stackitem;
      end
      // otherwise write directly to result
      else Result := Result + ResolveReplacements(Lines[i]) + sLineBreak;
    end;
  end;
  IfDefines.Free;
  DefineStack.Free;
  Defines.Free;
end;

{ TConstantbufferManager }

constructor TConstantbufferManager.Create;
begin
  FConstantBuffers := TDictionary<string, TConstantBuffer>.Create();
  FVariables := TDictionary<string, TConstantBuffer>.Create();
end;

destructor TConstantbufferManager.Destroy;
begin
  FConstantBuffers.Free;
  FVariables.Free;
  inherited;
end;

procedure TConstantbufferManager.SetConstantBuffers(Device : TDirectX11Device);
var
  cbuffer : TConstantBuffer;
  bufferarray : AConstantBuffers;
begin
  bufferarray := nil;
  for cbuffer in FConstantBuffers.Values do
      cbuffer.SetConstantbuffer(Device, bufferarray);
  Device.SetConstantBuffers(bufferarray);
end;

procedure TConstantbufferManager.SetShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : integer);
var
  cbuffer : TConstantBuffer;
begin
  cbuffer := FDefaultVariables[ConstantName];
  if assigned(cbuffer) then
      cbuffer.SetShaderConstant(ConstantName, Value, Size);
end;

procedure TConstantbufferManager.SetShaderConstant(const ConstantName : string; Value : Pointer; Size : integer);
var
  cbuffer : TConstantBuffer;
begin
  if FVariables.TryGetValue(ConstantName, cbuffer) then
  begin
    cbuffer.SetShaderConstant(ConstantName, Value, Size);
  end;
end;

{ TConstantBuffer }

procedure TConstantBuffer.Analyze(Definition : string);
const
  PACK_SIZE = SizeOf(Single) * 4;
var
  regex : TRegex;
  matches : TMatchCollection;
  i, j : integer;
  defaultShaderConstant : EnumDefaultShaderConstant;
  cbufferVariable : RConstantVariable;
  variableNames : TArray<string>;
  variableType : string;
  currentOffset, arraylength, datatypesize, e : integer;
begin
  // remove comments
  Definition := TRegex.Replace(Definition, '\/\/.*?\n', '', [roIgnoreCase, roSingleLine]);
  // extract variables
  regex := TRegex.Create('([\d\w]+) (.+?);', [roIgnoreCase, roSingleLine]);
  matches := regex.matches(Definition);
  currentOffset := 0;
  for i := 0 to matches.Count - 1 do
  begin
    assert(matches[i].Groups.Count = 3, 'TConstantBuffer.Analyze: Wrong cbuffer-variable-Syntax: ' + matches[i].Value);
    variableType := matches[i].Groups[1].Value;
    cbufferVariable.IsBool := False;
    if variableType = 'float4x4' then cbufferVariable.Size := SizeOf(RMatrix)
    else if variableType = 'float4x3' then cbufferVariable.Size := SizeOf(RMatrix4x3)
    else if variableType = 'float4' then cbufferVariable.Size := SizeOf(Single) * 4
    else if variableType = 'float3' then cbufferVariable.Size := SizeOf(Single) * 3
    else if variableType = 'float2' then cbufferVariable.Size := SizeOf(Single) * 2
    else if variableType = 'float' then cbufferVariable.Size := SizeOf(Single) * 1
    else if variableType = 'int4' then cbufferVariable.Size := SizeOf(integer) * 4
    else if variableType = 'int3' then cbufferVariable.Size := SizeOf(integer) * 3
    else if variableType = 'int2' then cbufferVariable.Size := SizeOf(integer) * 2
    else if variableType = 'int' then cbufferVariable.Size := SizeOf(integer) * 1
    else if variableType = 'bool' then
    begin
      cbufferVariable.Size := SizeOf(Single) * 1;
      cbufferVariable.IsBool := true;
    end
    else raise EInvalidArgument.Create('TConstantBuffer.Analyze: Unknown variable type ''' + variableType + '''!');
    datatypesize := cbufferVariable.Size;

    variableNames := matches[i].Groups[2].Value.Replace(' ', '').Split([',']);
    for j := 0 to Length(variableNames) - 1 do
    begin
      // check for array
      if variableNames[j].Contains('[') then
      begin
        Val(HString.TrimAfter(']', HString.TrimBefore('[', variableNames[j])), arraylength, e);
        if e <> 0 then
            raise EInvalidArgument.Create('TConstantBuffer.Analyze: Wrong cbuffer-array-variable-Syntax :' + variableNames[j]);
        variableNames[j] := HString.TrimAfter('[', variableNames[j]);
        cbufferVariable.Size := datatypesize * arraylength;
        cbufferVariable.IsArray := true;
      end
      else
      begin
        cbufferVariable.Size := datatypesize;
        cbufferVariable.IsArray := False;
      end;
      // apply annoying packing padding
      if ((currentOffset div PACK_SIZE) <> ((currentOffset + cbufferVariable.Size) div PACK_SIZE)) and not((currentOffset + cbufferVariable.Size) mod PACK_SIZE = 0) then
          currentOffset := currentOffset + (PACK_SIZE - (currentOffset mod PACK_SIZE));
      cbufferVariable.Offset := currentOffset;
      cbufferVariable.IsValid := true;

      // add slow access by string
      FVariables.Add(variableNames[j], cbufferVariable);
      // add fast access by enum
      for defaultShaderConstant := low(EnumDefaultShaderConstant) to high(EnumDefaultShaderConstant) do
        if variableNames[j] = DEFAULT_SHADER_CONSTANT_MAPPING[defaultShaderConstant] then
        begin
          FDefaultVariables[defaultShaderConstant] := cbufferVariable;
          break;
        end;

      // increase offset for next variable
      currentOffset := currentOffset + cbufferVariable.Size;
    end;
  end;
  // create buffer
  setlength(FDataBlob, currentOffset + (PACK_SIZE - (currentOffset mod PACK_SIZE)));
  ZeroMemory(@FDataBlob[0], Length(FDataBlob) * SizeOf(byte));
end;

procedure TConstantBuffer.BuildConstantbuffer(Device : TDevice);
var
  cb_desc : D3D11_BUFFER_DESC;
begin
  ZeroMemory(@cb_desc, SizeOf(D3D11_BUFFER_DESC));
  cb_desc.ByteWidth := Length(FDataBlob) * SizeOf(byte);
  cb_desc.Usage := D3D11_USAGE_DYNAMIC;
  cb_desc.BindFlags := D3D11_BIND_CONSTANT_BUFFER;
  cb_desc.CPUAccessFlags := D3D11_CPU_ACCESS_WRITE;

  CheckDX11Error(TDirectX11Device(Device).Device.CreateBuffer(cb_desc, nil, FConstantBuffer), 'TConstantBuffer.BuildConstantbuffer failed!');
end;

constructor TConstantBuffer.Create(Definition : string; Slot : integer; Device : TDevice);
begin
  FVariables := TDictionary<string, RConstantVariable>.Create;
  FDirty := true;
  FSlot := Slot;
  Analyze(Definition);
  // create real buffer
  BuildConstantbuffer(Device);
end;

destructor TConstantBuffer.Destroy;
begin
  FVariables.Free;
  inherited;
end;

procedure TConstantBuffer.SetConstantbuffer(Device : TDirectX11Device; var bufferarray : AConstantBuffers);
var
  mappedResource : D3D11_MAPPED_SUBRESOURCE;
begin
  if FDirty then
  begin
    ZeroMemory(@mappedResource, SizeOf(D3D11_MAPPED_SUBRESOURCE));
    // copy data to constantbuffer
    CheckDX11Error(Device.DeviceContext.Map(FConstantBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &mappedResource), 'TConstantBuffer.SetConstantbuffer mapping failed!');
    if assigned(mappedResource.pData) then
    begin
      CopyMemory(mappedResource.pData, @FDataBlob[0], Length(FDataBlob) * SizeOf(byte));
      // Unlock the constant buffer
      Device.DeviceContext.Unmap(FConstantBuffer, 0);
    end;
    FDirty := False;
  end;
  if Length(bufferarray) <= FSlot then
      setlength(bufferarray, FSlot + 1);
  bufferarray[FSlot] := FConstantBuffer;
end;

procedure TConstantBuffer.SetShaderConstant(const Constant : RConstantVariable; Value : Pointer; Size : integer);
var
  bool : longbool;
begin
  assert((Size = Constant.Size) or (Constant.IsBool or Constant.IsArray), 'TConstantBuffer.SetShaderConstant: Size of defined variable matches not the set variable!');
  if Constant.IsBool then
  begin
    assert(Size = SizeOf(Boolean));
    Size := SizeOf(longbool);
    bool := PBoolean(Value)^;
    Value := @bool;
  end;
  Size := Min(Size, Constant.Size);
  if not CompareMem(Value, @FDataBlob[Constant.Offset], Size) then
  begin
    FDirty := true;
    CopyMemory(@FDataBlob[Constant.Offset], Value, Size);
  end;
end;

procedure TConstantBuffer.SetShaderConstant(const ConstantName : EnumDefaultShaderConstant; Value : Pointer; Size : integer);
var
  cVariable : RConstantVariable;
begin
  cVariable := FDefaultVariables[ConstantName];
  if cVariable.IsValid then SetShaderConstant(cVariable, Value, Size)
  else assert(False, 'TConstantBuffer.SetShaderConstant: Tried to set variable, which is not contained in variable list!');
end;

procedure TConstantBuffer.SetShaderConstant(const ConstantName : string; Value : Pointer; Size : integer);
var
  cVariable : RConstantVariable;
begin
  if FVariables.TryGetValue(ConstantName, cVariable) then
  begin
    SetShaderConstant(cVariable, Value, Size);
  end
  else assert(False, 'TConstantBuffer.SetShaderConstant: Tried to set variable, which is not contained in variable list!');
end;

{ TDirectX11DepthStencilBuffer }

class function TDirectX11DepthStencilBuffer.CreateDepthStencilBuffer(Device : TDevice; Width, Height : Cardinal) : TDepthStencilBuffer;
var
  depthStencilDesc : D3D11_TEXTURE2D_DESC;
  res : TDirectX11DepthStencilBuffer;
begin
  res := TDirectX11DepthStencilBuffer.Create();
  ZeroMemory(@depthStencilDesc, SizeOf(D3D11_TEXTURE2D_DESC));
  depthStencilDesc.Width := Width;
  depthStencilDesc.Height := Height;
  depthStencilDesc.MipLevels := 1;
  depthStencilDesc.ArraySize := 1;
  depthStencilDesc.Format := DXGI_FORMAT_D24_UNORM_S8_UINT;
  depthStencilDesc.SampleDesc.Count := 1;
  depthStencilDesc.SampleDesc.Quality := 0;
  depthStencilDesc.Usage := D3D11_USAGE_DEFAULT;
  depthStencilDesc.BindFlags := D3D11_BIND_DEPTH_STENCIL;
  depthStencilDesc.CPUAccessFlags := 0;
  depthStencilDesc.MiscFlags := 0;

  CheckDX11Error(TDirectX11Device(Device).Device.CreateTexture2D(depthStencilDesc, nil, res.FDepthStencilBuffer), 'TDirectX11DepthStencilBuffer.CreateDepthStencilBuffer: Create buffer failed!');
  TDirectX11Device(Device).Device.CreateDepthStencilView(res.FDepthStencilBuffer, nil, res.FDepthStencilView);
  Result := res;
end;

end.

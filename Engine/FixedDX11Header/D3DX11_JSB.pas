unit D3DX11_JSB;

/// ////////////////////////////////////////////////////////////////////////////
// Title: Translation of DirectX C++ header files for use with Delphi 2009 and later
//
// File name: D3DX11_JSB.pas
//
// Originator: J S Bladen, Sheffield, UK.
//
// Copyright: J S Bladen, Sheffield, UK.
//
// Translation date and time (UTC): 11/10/2010 19:05:48
//
// Email: DirectXForDelphi@jsbmedical.co.uk
/// ////////////////////////////////////////////////////////////////////////////

/// ////////////////////////////////////////////////////////////////////////////
// Original file(s):
// D3DX11Core.h
// D3DX11Tex.h
// D3DX11Async.h
// D3DX11.h
// D3DX11Effect.h
//
// Copyright (C) Microsoft Corporation.
/// ////////////////////////////////////////////////////////////////////////////

/// ////////////////////////////////////////////////////////////////////////////
// Software licence:
//
// Use of this "software" is subject to the following software licence:
//
// ***** BEGIN LICENCE BLOCK *****
//
// 1) This software is distributed in the hope that it will be useful, but without warranty of any kind.
// 2) The copyright and/or originator notice(s) may not be altered or removed.
// 3) This software may be used for commercial or non-commercial use.
// 4) This software may be redistributed, provided no charge is made.
// 5) There is no obligation to make source code available to end users even if the software is modified.
// 6) Modified versions of this software will be subject to this software licence.
// 7) If the software is modified, the changes must be marked in the source code with the contributors ID (e.g. name)
// before redistribution.
//
// ***** END LICENCE BLOCK *****
//
// In addition, users of this software are strongly encouraged to contact the originator with feedback, corrections and
// suggestions for improvement.
/// ////////////////////////////////////////////////////////////////////////////

/// ////////////////////////////////////////////////////////////////////////////
// Translation notes:
//
// 1) This software is preliminary. For the latest version please see "http://DirectXForDelphi.blogspot.com/".
//
// 2) The header filename suffix "_JSB" is to distinguish the files from the equivalent JEDI/Clootie files
// and must be left in place". Interface units from different sources may not work correctly together.
//
// 3) By default, optional interface output method and function parameters are translated as "out InterfaceName:IInterfaceName",
// not "pInterfaceName:PIInterfaceName". This is because with the pointer version, Delphi does not appear to call the
// COM Release method on the supplied interface before assigning a new value. To pass a nil parameter, use
// "IInterfaceName(nil^)".
//
// PLEASE NOTE: This is different to the equivalent JEDI/Clootie files, though only minimal source code changes
// should be required.
//
// If you want to use pointers instead, define the conditional define "UsePointersForOptionalOutputInterfaces" but ensure
// that the interface variable is set to nil before calling the method.
//
// 4) Please contact me if you are interested in versions for FPC or C++ etc.
//
// JSB
/// ////////////////////////////////////////////////////////////////////////////

interface

{$Z4}

uses
  Windows,
  SysUtils,
  WinApi.d3d11,
  WinApi.dxgi,
  WinApi.dxgiType,
  WinApi.d3dcommon,
  WinApi.DxgiFormat;

type
  E_Effects11 = class(Exception);

const
  DLL_D3DX11 = 'd3dx11_43.dll';

type
  PHResult = ^HResult;

  ID3DX11DataLoader = class// Cannot use 'interface' as the QueryInterface, AddRef and Release methods are missing.
    function Load : HResult; virtual; stdcall; abstract;
    function Decompress(var pData : Pointer; pNumBytes : PSIZE_T) : HResult; virtual; stdcall; abstract;
    function Destroy : HResult; reintroduce; virtual; stdcall; abstract;
  end;

  ID3DX11DataProcessor = class// Cannot use 'interface' as the QueryInterface, AddRef and Release methods are missing.
    function Process(pData : Pointer; NumBytes : SIZE_T) : HResult; virtual; stdcall; abstract;
    function CreateDeviceObject(var pDataObject : Pointer) : HResult; virtual; stdcall; abstract;
    function Destroy : HResult; reintroduce; virtual; stdcall; abstract;
  end;

  ID3DX11ThreadPump = interface(IUnknown)
    ['{C93FECFA-6967-478A-ABBC-402D90621FCB}']
    function GetWorkItemCount : UINT; stdcall;
    function WaitForAllItems : HResult; stdcall;
    function ProcessDeviceWorkItems(WorkItemCount : UINT) : HResult; stdcall;
    function PurgeAllItems : HResult; stdcall;
    function GetQueueStatus(pIoQueue : PUINT; pProcessQueue : PUINT; pDeviceQueue : PUINT) : HResult; stdcall;
  end;

function D3DX11CreateThreadPump(NumIOThreads : UINT; NumProcThreads : UINT; out ThreadPump : ID3DX11ThreadPump) : HResult; stdcall; external DLL_D3DX11;
// JSB: Not in DLL_D3DX11. Might be implemented in C++ D3DX11.lib library: function D3DX11UnsetAllDeviceObjects(Context:ID3D11DeviceContext):HResult; stdcall;  external DLL_D3DX11;

/// ////////////////////////////////////////////////////////////////////////////
// End "D3DX11Core.h"
/// ////////////////////////////////////////////////////////////////////////////

/// ////////////////////////////////////////////////////////////////////////////
// Begin "D3DX11Tex.h"
/// ////////////////////////////////////////////////////////////////////////////

type
  D3DX11_FILTER_FLAG =
    (
    D3DX11_FILTER_NONE = (1 shl 0),
    D3DX11_FILTER_POINT = (2 shl 0),
    D3DX11_FILTER_LINEAR = (3 shl 0),
    D3DX11_FILTER_TRIANGLE = (4 shl 0),
    D3DX11_FILTER_BOX = (5 shl 0),
    D3DX11_FILTER_MIRROR_U = (1 shl 16),
    D3DX11_FILTER_MIRROR_V = (2 shl 16),
    D3DX11_FILTER_MIRROR_W = (4 shl 16),
    D3DX11_FILTER_MIRROR = (7 shl 16),
    D3DX11_FILTER_DITHER = (1 shl 19),
    D3DX11_FILTER_DITHER_DIFFUSION = (2 shl 19),
    D3DX11_FILTER_SRGB_IN = (1 shl 21),
    D3DX11_FILTER_SRGB_OUT = (2 shl 21),
    D3DX11_FILTER_SRGB = (3 shl 21)
    );
  PD3DX11_FILTER_FLAG = ^D3DX11_FILTER_FLAG;

  D3DX11_NORMALMAP_FLAG =
    (
    D3DX11_NORMALMAP_MIRROR_U = (1 shl 16),
    D3DX11_NORMALMAP_MIRROR_V = (2 shl 16),
    D3DX11_NORMALMAP_MIRROR = (3 shl 16),
    D3DX11_NORMALMAP_INVERTSIGN = (8 shl 16),
    D3DX11_NORMALMAP_COMPUTE_OCCLUSION = (16 shl 16)
    );
  PD3DX11_NORMALMAP_FLAG = ^D3DX11_NORMALMAP_FLAG;

  D3DX11_CHANNEL_FLAG =
    (
    D3DX11_CHANNEL_RED = (1 shl 0),
    D3DX11_CHANNEL_BLUE = (1 shl 1),
    D3DX11_CHANNEL_GREEN = (1 shl 2),
    D3DX11_CHANNEL_ALPHA = (1 shl 3),
    D3DX11_CHANNEL_LUMINANCE = (1 shl 4)
    );
  PD3DX11_CHANNEL_FLAG = ^D3DX11_CHANNEL_FLAG;

  D3DX11_IMAGE_FILE_FORMAT =
    (
    D3DX11_IFF_BMP = 0,
    D3DX11_IFF_JPG = 1,
    D3DX11_IFF_PNG = 3,
    D3DX11_IFF_DDS = 4,
    D3DX11_IFF_TIFF = 10,
    D3DX11_IFF_GIF = 11,
    D3DX11_IFF_WMP = 12
    );
  PD3DX11_IMAGE_FILE_FORMAT = ^D3DX11_IMAGE_FILE_FORMAT;

  D3DX11_SAVE_TEXTURE_FLAG =
    (
    D3DX11_STF_USEINPUTBLOB = $0001
    );
  PD3DX11_SAVE_TEXTURE_FLAG = ^D3DX11_SAVE_TEXTURE_FLAG;

  D3DX11_IMAGE_INFO = record
    Width : UINT;
    Height : UINT;
    Depth : UINT;
    ArraySize : UINT;
    MipLevels : UINT;
    MiscFlags : UINT;
    Format : DXGI_FORMAT;
    ResourceDimension : D3D11_Resource_Dimension;
    ImageFileFormat : D3DX11_IMAGE_FILE_FORMAT;
  end;

  PD3DX11_IMAGE_INFO = ^D3DX11_IMAGE_INFO;

  D3DX11_IMAGE_LOAD_INFO = record
    Width : UINT;
    Height : UINT;
    Depth : UINT;
    FirstMipLevel : UINT;
    MipLevels : UINT;
    Usage : D3D11_USAGE;
    BindFlags : UINT;
    CPUAccessFlags : UINT;
    MiscFlags : UINT;
    Format : DXGI_FORMAT;
    Filter : UINT;
    MipFilter : UINT;
    pSrcInfo : PD3DX11_IMAGE_INFO;
  end;

  PD3DX11_IMAGE_LOAD_INFO = ^D3DX11_IMAGE_LOAD_INFO;

function D3DX11GetImageInfoFromFileA(pSrcFile : PAnsiChar; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;
function D3DX11GetImageInfoFromFileW(pSrcFile : PWideChar; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;

{$IFDEF UNICODE}

function D3DX11GetImageInfoFromFile(pSrcFile : PWideChar; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11GetImageInfoFromFileW';

{$ELSE}

function D3DX11GetImageInfoFromFile(pSrcFile : PAnsiChar; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11GetImageInfoFromFileA';

{$ENDIF}

function D3DX11GetImageInfoFromResourceA(hSrcModule : HMODULE; pSrcResource : PAnsiChar; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;
function D3DX11GetImageInfoFromResourceW(hSrcModule : HMODULE; pSrcResource : PWideChar; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;

{$IFDEF UNICODE}

function D3DX11GetImageInfoFromResource(hSrcModule : HMODULE; pSrcResource : PWideChar; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11GetImageInfoFromResourceW';

{$ELSE}

function D3DX11GetImageInfoFromResource(hSrcModule : HMODULE; pSrcResource : PAnsiChar; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11GetImageInfoFromResourceA';

{$ENDIF}

function D3DX11GetImageInfoFromMemory(pSrcData : Pointer; SrcDataSize : SIZE_T; Pump : ID3DX11ThreadPump; pSrcInfo : PD3DX11_IMAGE_INFO; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;
function D3DX11CreateShaderResourceViewFromFileA(Device : ID3D11Device; pSrcFile : PAnsiChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;
function D3DX11CreateShaderResourceViewFromFileW(Device : ID3D11Device; pSrcFile : PWideChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;

{$IFDEF UNICODE}

function D3DX11CreateShaderResourceViewFromFile(Device : ID3D11Device; pSrcFile : PWideChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11CreateShaderResourceViewFromFileW';

{$ELSE}

function D3DX11CreateShaderResourceViewFromFile(Device : ID3D11Device; pSrcFile : PAnsiChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11CreateShaderResourceViewFromFileA';

{$ENDIF}

function D3DX11CreateTextureFromFileA(Device : ID3D11Device; pSrcFile : PAnsiChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;
function D3DX11CreateTextureFromFileW(Device : ID3D11Device; pSrcFile : PWideChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;

{$IFDEF UNICODE}

function D3DX11CreateTextureFromFile(Device : ID3D11Device; pSrcFile : PWideChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11CreateTextureFromFileW';

{$ELSE}

function D3DX11CreateTextureFromFile(Device : ID3D11Device; pSrcFile : PAnsiChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11CreateTextureFromFileA';

{$ENDIF}

function D3DX11CreateShaderResourceViewFromResourceA(Device : ID3D11Device; hSrcModule : HMODULE; pSrcResource : PAnsiChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;
function D3DX11CreateShaderResourceViewFromResourceW(Device : ID3D11Device; hSrcModule : HMODULE; pSrcResource : PWideChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;

{$IFDEF UNICODE}

function D3DX11CreateShaderResourceViewFromResource(Device : ID3D11Device; hSrcModule : HMODULE; pSrcResource : PWideChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11CreateShaderResourceViewFromResourceW';

{$ELSE}

function D3DX11CreateShaderResourceViewFromResource(Device : ID3D11Device; hSrcModule : HMODULE; pSrcResource : PAnsiChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11CreateShaderResourceViewFromResourceA';

{$ENDIF}

function D3DX11CreateTextureFromResourceA(Device : ID3D11Device; hSrcModule : HMODULE; pSrcResource : PAnsiChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;
function D3DX11CreateTextureFromResourceW(Device : ID3D11Device; hSrcModule : HMODULE; pSrcResource : PWideChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;

{$IFDEF UNICODE}

function D3DX11CreateTextureFromResource(Device : ID3D11Device; hSrcModule : HMODULE; pSrcResource : PWideChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11CreateTextureFromResourceW';

{$ELSE}

function D3DX11CreateTextureFromResource(Device : ID3D11Device; hSrcModule : HMODULE; pSrcResource : PAnsiChar; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11CreateTextureFromResourceA';

{$ENDIF}

function D3DX11CreateShaderResourceViewFromMemory(Device : ID3D11Device; pSrcData : Pointer; SrcDataSize : SIZE_T; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out ShaderResourceView : ID3D11ShaderResourceView; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;
function D3DX11CreateTextureFromMemory(Device : ID3D11Device; pSrcData : Pointer; SrcDataSize : SIZE_T; pLoadInfo : PD3DX11_IMAGE_LOAD_INFO; Pump : ID3DX11ThreadPump; out Texture : ID3D11Resource; PHResult : PHResult) : HResult; stdcall; external DLL_D3DX11;

type
  TD3DX11_TextureLoadInfo = record
    pSrcBox : PD3D11_Box;
    pDstBox : PD3D11_Box;
    SrcFirstMip : UINT;
    DstFirstMip : UINT;
    NumMips : UINT;
    SrcFirstElement : UINT;
    DstFirstElement : UINT;
    NumElements : UINT;
    Filter : UINT;
    MipFilter : UINT;
  end;

  PTD3DX11_TextureLoadInfo = ^TD3DX11_TextureLoadInfo;
  D3DX11_TEXTURE_LOAD_INFO = TD3DX11_TextureLoadInfo;
  PD3DX11_TEXTURE_LOAD_INFO = ^TD3DX11_TextureLoadInfo;

function D3DX11LoadTextureFromTexture(Context : ID3D11DeviceContext; SrcTexture : ID3D11Resource; pLoadInfo : PTD3DX11_TextureLoadInfo; DstTexture : ID3D11Resource) : HResult; stdcall; external DLL_D3DX11;
function D3DX11FilterTexture(Context : ID3D11DeviceContext; Texture : ID3D11Resource; SrcLevel : UINT; MipFilter : UINT) : HResult; stdcall; external DLL_D3DX11;
function D3DX11SaveTextureToFileA(Context : ID3D11DeviceContext; SrcTexture : ID3D11Resource; DestFormat : D3DX11_IMAGE_FILE_FORMAT; pDestFile : PAnsiChar) : HResult; stdcall; external DLL_D3DX11;
function D3DX11SaveTextureToFileW(Context : ID3D11DeviceContext; SrcTexture : ID3D11Resource; DestFormat : D3DX11_IMAGE_FILE_FORMAT; pDestFile : PWideChar) : HResult; stdcall; external DLL_D3DX11;

{$IFDEF UNICODE}

function D3DX11SaveTextureToFile(Context : ID3D11DeviceContext; SrcTexture : ID3D11Resource; DestFormat : D3DX11_IMAGE_FILE_FORMAT; pDestFile : PWideChar) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11SaveTextureToFileW';

{$ELSE}

function D3DX11SaveTextureToFile(Context : ID3D11DeviceContext; SrcTexture : ID3D11Resource; DestFormat : TD3DX11_ImageFileFormat; pDestFile : PAnsiChar) : HResult; stdcall; external DLL_D3DX11 name 'D3DX11SaveTextureToFileA';

{$ENDIF}

function D3DX11SaveTextureToMemory(Context : ID3D11DeviceContext; SrcTexture : ID3D11Resource; DestFormat : D3DX11_IMAGE_FILE_FORMAT; out DestBuf : ID3D10Blob; Flags : UINT) : HResult; stdcall; external DLL_D3DX11;
function D3DX11ComputeNormalMap(Context : ID3D11DeviceContext; SrcTexture : ID3D11Texture2D; Flags : UINT; Channel : UINT; Amplitude : Single; DestTexture : ID3D11Texture2D) : HResult; stdcall; external DLL_D3DX11;
function D3DX11SHProjectCubeMap(Context : ID3D11DeviceContext; Order : UINT; CubeMap : ID3D11Texture2D; pROut : PSingle; pGOut : PSingle; pBOut : PSingle) : HResult; stdcall; external DLL_D3DX11;

/// ////////////////////////////////////////////////////////////////////////////
// End "D3DX11Tex.h"
/// ////////////////////////////////////////////////////////////////////////////

/// ////////////////////////////////////////////////////////////////////////////
// Begin "D3DX11.h"
/// ////////////////////////////////////////////////////////////////////////////

const
  D3DX11_DEFAULT : UINT = UINT(-1);
  D3DX11_FROM_FILE      = -3;
  DXGI_FORMAT_FROM_FILE = DXGI_FORMAT(-3);
  _FACDD                = $876;
  DDSTATUS_Base         = UINT(_FACDD shl 16);
  DDHResult_Base        = DDSTATUS_Base or UINT(1 shl 31);

const
  D3DX11_ERROR_CANNOT_MODIFY_INDEX_BUFFER = HResult(DDHResult_Base or 2900);
  D3DX11_ERROR_INVALID_MESH               = HResult(DDHResult_Base or 2901);
  D3DX11_ERROR_CANNOT_ATTR_SORT           = HResult(DDHResult_Base or 2902);
  D3DX11_ERROR_SKINNING_NOT_SUPPORTED     = HResult(DDHResult_Base or 2903);
  D3DX11_ERROR_TOO_MANY_INFLUENCES        = HResult(DDHResult_Base or 2904);
  D3DX11_ERROR_INVALID_DATA               = HResult(DDHResult_Base or 2905);
  D3DX11_ERROR_LOADED_MESH_HAS_NO_DATA    = HResult(DDHResult_Base or 2906);
  D3DX11_ERROR_DUPLICATE_NAMED_FRAGMENT   = HResult(DDHResult_Base or 2907);
  D3DX11_ERROR_CANNOT_REMOVE_LAST_ITEM    = HResult(DDHResult_Base or 2908);

  /// ////////////////////////////////////////////////////////////////////////////
  // End "D3DX11.h"
  /// ////////////////////////////////////////////////////////////////////////////

implementation

end.

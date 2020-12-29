unit D3DCompiler_JSB;

/// ////////////////////////////////////////////////////////////////////////////
// Title: Translation of DirectX C++ header files for use with Delphi 2009 and later
//
// File name: D3DCompiler_JSB.pas
//
// Originator: J S Bladen, Sheffield, UK.
//
// Copyright: J S Bladen, Sheffield, UK.
//
// Translation date and time (UTC): 11/10/2010 09:47:30
//
// Email: DirectXForDelphi@jsbmedical.co.uk
/// ////////////////////////////////////////////////////////////////////////////

/// ////////////////////////////////////////////////////////////////////////////
// Original file(s):
// D3Dcompiler.h
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
  WinApi.dxgiType,
  WinApi.d3dcommon;

/// ////////////////////////////////////////////////////////////////////////////
// Begin "D3Dcompiler.h"
/// ////////////////////////////////////////////////////////////////////////////

const
  D3DCOMPILER_DLL = 'd3dcompiler_43.dll';

const
  D3DCOMPILE_DEBUG                          = (1 shl 0);
  D3DCOMPILE_SKIP_VALIDATION                = (1 shl 1);
  D3DCOMPILE_SKIP_OPTIMIZATION              = (1 shl 2);
  D3DCOMPILE_PACK_MATRIX_ROW_MAJOR          = (1 shl 3);
  D3DCOMPILE_PACK_MATRIX_COLUMN_MAJOR       = (1 shl 4);
  D3DCOMPILE_PARTIAL_PRECISION              = (1 shl 5);
  D3DCOMPILE_FORCE_VS_SOFTWARE_NO_OPT       = (1 shl 6);
  D3DCOMPILE_FORCE_PS_SOFTWARE_NO_OPT       = (1 shl 7);
  D3DCOMPILE_NO_PRESHADER                   = (1 shl 8);
  D3DCOMPILE_AVOID_FLOW_CONTROL             = (1 shl 9);
  D3DCOMPILE_PREFER_FLOW_CONTROL            = (1 shl 10);
  D3DCOMPILE_ENABLE_STRICTNESS              = (1 shl 11);
  D3DCOMPILE_ENABLE_BACKWARDS_COMPATIBILITY = (1 shl 12);
  D3DCOMPILE_IEEE_STRICTNESS                = (1 shl 13);
  D3DCOMPILE_OPTIMIZATION_LEVEL0            = (1 shl 14);
  D3DCOMPILE_OPTIMIZATION_LEVEL1            = 0;
  D3DCOMPILE_OPTIMIZATION_LEVEL2            = ((1 shl 14) or (1 shl 15));
  D3DCOMPILE_OPTIMIZATION_LEVEL3            = (1 shl 15);
  D3DCOMPILE_RESERVED16                     = (1 shl 16);
  D3DCOMPILE_RESERVED17                     = (1 shl 17);
  D3DCOMPILE_WARNINGS_ARE_ERRORS            = (1 shl 18);
  D3DCOMPILE_EFFECT_CHILD_EFFECT            = (1 shl 0);
  D3DCOMPILE_EFFECT_ALLOW_SLOW_OPS          = (1 shl 1);
  D3D_DISASM_ENABLE_COLOR_CODE              = $00000001;
  D3D_DISASM_ENABLE_DEFAULT_VALUE_PRINTS    = $00000002;
  D3D_DISASM_ENABLE_INSTRUCTION_NUMBERING   = $00000004;
  D3D_DISASM_ENABLE_INSTRUCTION_CYCLE       = $00000008;
  D3D_DISASM_DISABLE_DEBUG_INFO             = $00000010;
  D3D_COMPRESS_SHADER_KEEP_ALL_PARTS        = $00000001;

function D3DCompile(
  pSrcData : Pointer;                (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;              (* __in *)
  pSourceName : LPCSTR;              (* __in_opt *)
  const pDefines : LPD3D_SHADER_MACRO; (* __in_xcount_opt(pDefines->Name != NULL) *)
  Include : ID3DInclude;             (* __in_opt *)
  pEntrypoint : LPCSTR;              (* __in *)
  pTarget : LPCSTR;                  (* __in *)
  Flags1 : UINT;                     (* __in *)
  Flags2 : UINT;                     (* __in *)
  out Code : ID3DBlob;               (* __out *)
  out pErrorMsgs : ID3DBlob          (* __out_opt *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DPreprocess
  (
  pSrcData : Pointer;          (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;        (* __in *)
  pSourceName : PAnsiChar;     (* __in_opt *)
  pDefines : D3D_SHADER_MACRO; (* __in_opt *)
  Include : ID3DInclude;       (* __in_opt *)
  out CodeText : ID3DBlob;     (* __out *)
  pErrorMsgs : PID3DBlob       (* __out_opt *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DGetDebugInfo
  (
  pSrcData : Pointer;     (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;   (* __in *)
  out DebugInfo : ID3DBlob(* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DReflect
  (
  pSrcData : Pointer;              (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;            (* __in *)
  const pInterface : TGUID;        (* __in *)
  out pReflector(* JSB :Pointer *) (* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DDisassemble
  (
  pSrcData : Pointer;       (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;     (* __in *)
  Flags : LongWord;         (* __in *)
  Comments : PAnsiChar;     (* __in_opt *)
  out Disassembly : ID3DBlob(* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DGetInputSignatureBlob
  (
  pSrcData : Pointer;         (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;       (* __in *)
  out SignatureBlob : ID3DBlob(* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DGetOutputSignatureBlob
  (
  pSrcData : Pointer;         (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;       (* __in *)
  out SignatureBlob : ID3DBlob(* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DGetInputAndOutputSignatureBlob
  (
  pSrcData : Pointer;         (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;       (* __in *)
  out SignatureBlob : ID3DBlob(* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

type
  TD3DCOMPILER_STRIP_FLAGS =
    (
    D3DCOMPILER_STRIP_REFLECTION_DATA = 1,
    D3DCOMPILER_STRIP_DEBUG_INFO = 2,
    D3DCOMPILER_STRIP_TEST_BLOBS = 4
    );
  PTD3DCOMPILER_STRIP_FLAGS = ^TD3DCOMPILER_STRIP_FLAGS;
  D3DCOMPILER_STRIP_FLAGS = TD3DCOMPILER_STRIP_FLAGS;
  PD3DCOMPILER_STRIP_FLAGS = ^TD3DCOMPILER_STRIP_FLAGS;

function D3DStripShader
  (
  pShaderBytecode : Pointer; (* __in_bcount(BytecodeLength) *)
  BytecodeLength : SIZE_T;   (* __in *)
  StripFlags : LongWord;     (* __in *)
  out StrippedBlob : ID3DBlob(* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

type
  TD3D_BlobPart =
    (
    D3D_BLOB_INPUT_SIGNATURE_BLOB,
    D3D_BLOB_OUTPUT_SIGNATURE_BLOB,
    D3D_BLOB_INPUT_AND_OUTPUT_SIGNATURE_BLOB,
    D3D_BLOB_PATCH_CONSTANT_SIGNATURE_BLOB,
    D3D_BLOB_ALL_SIGNATURE_BLOB,
    D3D_BLOB_DEBUG_INFO,
    D3D_BLOB_LEGACY_SHADER,
    D3D_BLOB_XNA_PREPASS_SHADER,
    D3D_BLOB_XNA_SHADER,
    D3D_BLOB_TEST_ALTERNATE_SHADER = $8000,
    D3D_BLOB_TEST_COMPILE_DETAILS,
    D3D_BLOB_TEST_COMPILE_PERF
    );
  PTD3D_BlobPart = ^TD3D_BlobPart;
  D3D_BLOB_PART = TD3D_BlobPart;
  PD3D_BLOB_PART = ^TD3D_BlobPart;

function D3DGetBlobPart
  (
  pSrcData : Pointer;   (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T; (* __in *)
  Part : TD3D_BlobPart; (* __in *)
  Flags : LongWord;     (* __in *)
  out o_Part : ID3DBlob (* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

type
  TD3D_ShaderData = record
    pBytecode : Pointer;
    BytecodeLength : SIZE_T;
  end;

  PTD3D_ShaderData = ^TD3D_ShaderData;
  D3D_SHADER_DATA = TD3D_ShaderData;
  PD3D_SHADER_DATA = ^TD3D_ShaderData;

function D3DCompressShaders
  (
  NumShaders : LongWord;          (* __in *)
  pShaderData : PTD3D_ShaderData; (* __in_ecount(uNumShaders) *)
  Flags : LongWord;               (* __in *)
  out CompressedData : ID3DBlob   (* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DDecompressShaders
  (
  pSrcData : Pointer;      (* __in_bcount(SrcDataSize) *)
  SrcDataSize : SIZE_T;    (* __in *)
  NumShaders : LongWord;   (* __in *)
  StartIndex : LongWord;   (* __in *)
  pIndices : PLongWord;    (* __in_ecount_opt(uNumShaders) *)
  Flags : LongWord;        (* __in *)
  pShaders : PID3DBlob;    (* __out_ecount(uNumShaders) *)
  pTotalShaders : PLongWord(* __out_opt *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

function D3DCreateBlob
  (
  Size : SIZE_T;     (* __in *)
  out Blob : ID3DBlob(* __out *)
  ) : HResult; stdcall; external D3DCOMPILER_DLL delayed;

/// ////////////////////////////////////////////////////////////////////////////
// End "D3Dcompiler.h"
/// ////////////////////////////////////////////////////////////////////////////

implementation

end.

(*
  This file is a part of New Audio Components package v 1.9
  Copyright (c) 2002-2008, Andrei Borovsky. All rights reserved.
  See the LICENSE file for more details.
  You can contact me at anb@symmetrica.net
*)

(* $Id: ACS_Types.pas 1065 2009-12-17 05:41:25Z andrei.borovsky $ *)

unit ACS_Types;

(* Title: ACS_Types 
    Utility types used by the various ACS Classes. *)

interface

uses MMSystem;

type

  TBuffer16 = array[0..0] of SmallInt;
  PBuffer16 = ^TBuffer16;

  TBuffer8 = array[0..0] of Byte;
  PBuffer8 = ^TBuffer8;

  TBuffer32 = array[0..0] of Integer;
  PBuffer32 = ^TBuffer32;

  TStereoSample32 = packed record
    Left, Right : Integer;
  end;

  TStereoBuffer32 = array[0..0] of TStereoSample32;
  PStereoBuffer32 = ^TStereoBuffer32;

  TStereoSample16 = packed record
    Left, Right : SmallInt;
  end;

  TStereoBuffer16 = array[0..0] of TStereoSample16;
  PStereoBuffer16 = ^TStereoBuffer16;

  TStereoSample8 = packed record
    Left, Right : Byte;
  end;

  TStereoBuffer8 = array[0..0] of TStereoSample8;
  PStereoBuffer8 = ^TStereoBuffer8;


  TComplex = packed record
    Re, Im : Double;
  end;

  PComplex = ^TComplex;

  TComplexArray = array[0..0] of TComplex;
  PComplexArray = ^TComplexArray;

  TComplexSingle = packed record
    Re, Im : Single;
  end;

  PComplexSingle = ^TComplexSingle;

  TComplexArraySingle = array[0..0] of TComplexSingle;
  PComplexArraySingle = ^TComplexArraySingle;



  TDoubleArray = array[0..0] of Double;
  PDoubleArray = ^TDoubleArray;

  TStereoSampleD = record
    Left : Double;
    Right : Double;
  end;

  TStereoBufferD = array[0..0] of TStereoSampleD;
  PStereoBufferD = ^TStereoBufferD;

  TSmallIntArray = array[0..0] of SmallInt;
  PSmallIntArray = ^TSmallIntArray;

  Sample24 = packed record
    Lo : Byte;
    Hi : SmallInt;
  end;
  PSample24 = ^Sample24;

  TBuffer24 = packed array[0..0] of Sample24;
  PBuffer24 = ^TBuffer24;

  TBufferSingle = array[0..0] of Single;
  PBufferSingle = ^TBufferSingle;

  TSample8 = array[0..0] of Byte;
  PSample8 = ^TSample8;

  TAudioBuffer8 = array[0..0] of TSample8;
  PAudioBuffer8 = ^TAudioBuffer8;

  TSample16 = array[0..0] of SmallInt;
  PSample16 = ^TSample16;

  TAudioBuffer16 = array[0..0] of TSample16;
  PAudioBuffer16 = ^TAudioBuffer16;

  TAudioBuffer24 = array[0..0] of Sample24;
  PAudioBuffer24 = ^TAudioBuffer24;

  TSingleArray = array[0..0] of Single;
  PSingleArray = ^TSingleArray;

  TMSConverterMode = (msmMonoToBoth, msmMonoToLeft, msmMonoToRight);

  TWaveFormatExtensible = packed record
    Format : TWaveFormatEx;
    wValidBitsPerSample : WORD;
    dwChannelMask : LongWord;
    SubFormat : TGUID;
  end;
  PWaveFormatExtensible = ^TWaveFormatExtensible;

  TApev2TagsHeader = record
    Preamble : array[0..7] of AnsiChar; //( 'A', 'P', 'E', 'T', 'A', 'G', 'E', 'X' )
    Version : LongWord;
    TagSize : LongWord;  //Tag size in bytes including footer and all tag items excluding the header
    ItemsCount : LongWord; //Number of items in the Tag (n)
    Flags : LongWord;
    Reserved : array[0..7] of Byte;
  end;

const

  Pi = 3.14159265359;
  TwoPi = 6.28318530718;
  HalfPi = 1.57079632679;

  WAVE_FORMAT_EXTENSIBLE = $FFFE;
  KSDATAFORMAT_SUBTYPE_PCM : TGuid = '{00000001-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_IEEE_FLOAT : TGuid = '{00000003-0000-0010-8000-00aa00389b71}';

implementation

end.

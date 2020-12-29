{ ********************************************************************** }
{ }
{ "The contents of this file are subject to the Mozilla Public }
{ License Version 1.1 (the "License"); you may not use this }
{ file except in compliance with the License. You may obtain }
{ a copy of the License at http://www.mozilla.org/MPL/ }
{ }
{ Software distributed under the License is distributed on an }
{ "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express }
{ or implied. See the License for the specific language }
{ governing rights and limitations under the License. }
{ }
{ The Initial Developer of the Original Code is Matthias }
{ Ackermann. For other initial contributors, see contributors.txt }
{ Subsequent portions Copyright Creative IT. }
{ }
{ Current maintainer: Eric Grange }
{ }
{ ********************************************************************** }
unit dwsXPlatform;

{$I dws.inc}

//
// This unit should concentrate all non-UI cross-platform aspects,
// cross-Delphi versions, ifdefs and other conditionals
//
// no ifdefs in the main code.

{$WARN SYMBOL_PLATFORM OFF}

{$IFDEF FPC}
{$DEFINE VER200}  // FPC compatibility = D2009
{$ENDIF}

interface

uses
  Classes,
  SysUtils,
  Types,
  Masks,
  System.Win.Registry,
  SyncObjs,
  Variants,
  StrUtils,
  {$IFDEF FPC}
  {$IFDEF Windows}
  Windows
  {$ELSE}
  LCLIntf
  {$ENDIF}
  {$ELSE}
    Winapi.Windows
  {$IFNDEF VER200},
  IOUtils{$ENDIF}
  {$ENDIF}
    ;

const
  {$IFDEF UNIX}
  cLineTerminator = #10;
  {$ELSE}
  cLineTerminator = #13#10;
  {$ENDIF}
  // following is missing from D2010
  INVALID_HANDLE_VALUE = DWORD(-1);

  {$IFDEF FPC}
  // FreePascal RTL declares this constant, but does not support it,
  // so it just leads to runtime crashes, this attempts to trigger compile-time crashes instead
  varUString = 'varUString is not supported by FreePascal';
  {$ENDIF}


type

  // see http://delphitools.info/2011/11/30/fixing-tcriticalsection/
  {$HINTS OFF}
  {$IFDEF UNIX}
  TdwsCriticalSection = class(TCriticalSection);
  {$ELSE}

  TdwsCriticalSection = class
    private
      FDummy : array [0 .. 95 - SizeOf(TRTLCRiticalSection) - 2 * SizeOf(Pointer)] of Byte;
      FCS : TRTLCRiticalSection;

    public
      constructor Create;
      destructor Destroy; override;

      procedure Enter;
      procedure Leave;

      function TryEnter : Boolean;
  end;
  {$ENDIF}

  IMultiReadSingleWrite = interface
    procedure BeginRead;
    function TryBeginRead : Boolean;
    procedure EndRead;

    procedure BeginWrite;
    function TryBeginWrite : Boolean;
    procedure EndWrite;
  end;

  TMultiReadSingleWriteState = (mrswUnlocked, mrswReadLock, mrswWriteLock);

  {$IFDEF UNIX}{$DEFINE SRW_FALLBACK}{$ENDIF}

  TMultiReadSingleWrite = class(TInterfacedObject, IMultiReadSingleWrite)
    private
      {$IFNDEF SRW_FALLBACK}
      FSRWLock : Pointer;
      FDummy : array [0 .. 95 - 4 * SizeOf(Pointer)] of Byte; // padding
      {$ELSE}
      FLock : TdwsCriticalSection;
      {$ENDIF}
    public
      {$IFDEF SRW_FALLBACK}
      constructor Create;
      destructor Destroy; override;
      {$ENDIF}
      procedure BeginRead; inline;
      function TryBeginRead : Boolean; inline;
      procedure EndRead; inline;

      procedure BeginWrite; inline;
      function TryBeginWrite : Boolean; inline;
      procedure EndWrite; inline;

      // use for diagnostic only
      function State : TMultiReadSingleWriteState;
  end;

  {$HINTS ON}


procedure SetDecimalSeparator(c : Char);
function GetDecimalSeparator : Char;

type
  TCollectFileProgressEvent = procedure(const directory : TFileName; var skipScan : Boolean) of object;

procedure CollectFiles(const directory, fileMask : TFileName;
  list : TStrings; recurseSubdirectories : Boolean = False;
  onProgress : TCollectFileProgressEvent = nil);
procedure CollectSubDirs(const directory : TFileName; list : TStrings);

type
  {$IFNDEF FPC}
  {$IF CompilerVersion<22.0}
  // NativeUInt broken in D2009, and PNativeInt is missing in D2010
  // http://qc.embarcadero.com/wc/qcmain.aspx?d=71292
  NativeInt = Integer;
  PNativeInt = ^NativeInt;
  NativeUInt = Cardinal;
  PNativeUInt = ^NativeUInt;
  {$IFEND}
  {$ENDIF}
  {$IFDEF FPC}
  TBytes = array of Byte;

  RawByteString = string;

  PNativeInt = ^NativeInt;
  PUInt64 = ^UInt64;
  {$ENDIF}

  TPath = class
    class function GetTempPath : string; static;
    class function GetTempFileName : string; static;
  end;

  TFile = class
    class function ReadAllBytes(const filename : string) : TBytes; static;
  end;

  TdwsThread = class(TThread)
    {$IFNDEF FPC}
    {$IFDEF VER200}
    procedure Start;
    {$ENDIF}
    {$ENDIF}
  end;

  // 64bit system clock reference in milliseconds since boot
function GetSystemMilliseconds : Int64;
function UTCDateTime : TDateTime;
function UnixTime : Int64;

function LocalDateTimeToUTCDateTime(t : TDateTime) : TDateTime;
function UTCDateTimeToLocalDateTime(t : TDateTime) : TDateTime;

function SystemMillisecondsToUnixTime(t : Int64) : Int64;
function UnixTimeToSystemMilliseconds(ut : Int64) : Int64;

procedure SystemSleep(msec : Integer);

function FirstWideCharOfString(const s : string; const default : WideChar = #0) : WideChar; inline;
procedure CodePointToUnicodeString(c : Integer; var result : UnicodeString);
procedure CodePointToString(const c : Integer; var result : string); inline;

{$IFNDEF FPC}
function UnicodeCompareStr(const S1, S2 : string) : Integer; inline;
function UnicodeStringReplace(const s, oldPattern, newPattern : string; flags : TReplaceFlags) : string; inline;
{$ENDIF}

function UnicodeCompareP(p1 : PWideChar; n1 : Integer; p2 : PWideChar; n2 : Integer) : Integer; overload;
function UnicodeCompareP(p1, p2 : PWideChar; n : Integer) : Integer; overload;

function UnicodeLowerCase(const s : UnicodeString) : UnicodeString; overload;
function UnicodeUpperCase(const s : UnicodeString) : UnicodeString; overload;

{$IFDEF FPC}
function UnicodeLowerCase(const s : string) : string; overload;
function UnicodeUpperCase(const s : string) : string; overload;
{$ENDIF}

function ASCIICompareText(const S1, S2 : string) : Integer; inline;
function ASCIISameText(const S1, S2 : string) : Boolean; inline;

function NormalizeString(const s, form : string) : string;
function StripAccents(const s : string) : string;

function InterlockedIncrement(var val : Integer) : Integer; overload; {$IFDEF PUREPASCAL} inline; {$ENDIF}
function InterlockedDecrement(var val : Integer) : Integer; {$IFDEF PUREPASCAL} inline; {$ENDIF}

procedure FastInterlockedIncrement(var val : Integer); {$IFDEF PUREPASCAL} inline; {$ENDIF}
procedure FastInterlockedDecrement(var val : Integer); {$IFDEF PUREPASCAL} inline; {$ENDIF}

function InterlockedExchangePointer(var target : Pointer; val : Pointer) : Pointer; {$IFDEF PUREPASCAL} inline; {$ENDIF}

function InterlockedCompareExchangePointer(var destination : Pointer; exchange, comparand : Pointer) : Pointer; {$IFDEF PUREPASCAL} inline; {$ENDIF}

procedure SetThreadName(const threadName : PAnsiChar; threadID : Cardinal = Cardinal(-1));

procedure OutputDebugString(const msg : string);

procedure WriteToOSEventLog(const logName, logCaption, logDetails : string;
  const logRawData : RawByteString = ''); overload;

function TryTextToFloat(const s : PChar; var value : Extended;
  const formatSettings : TFormatSettings) : Boolean; {$IFNDEF FPC} inline; {$ENDIF}
function TryTextToFloatW(const s : PWideChar; var value : Extended;
  const formatSettings : TFormatSettings) : Boolean; {$IFNDEF FPC} inline; {$ENDIF}

{$IFDEF FPC}
procedure VarCopy(out dest : Variant; const src : Variant); inline;
{$ELSE}
function VarToUnicodeStr(const v : Variant) : string; inline;
{$ENDIF}

{$IFDEF FPC}
function Utf8ToUnicodeString(const buf : RawByteString) : UnicodeString; inline;
{$ENDIF}

function RawByteStringToBytes(const buf : RawByteString) : TBytes;
function BytesToRawByteString(const buf : TBytes; startIndex : Integer = 0) : RawByteString; overload;
function BytesToRawByteString(p : Pointer; size : Integer) : RawByteString; overload;

function LoadDataFromFile(const filename : TFileName) : TBytes;
procedure SaveDataToFile(const filename : TFileName; const data : TBytes);

function LoadRawBytesFromFile(const filename : TFileName) : RawByteString;
function SaveRawBytesToFile(const filename : TFileName; const data : RawByteString) : Integer;

procedure LoadRawBytesAsScriptStringFromFile(const filename : TFileName; var result : string);

function LoadTextFromBuffer(const buf : TBytes) : UnicodeString;
function LoadTextFromRawBytes(const buf : RawByteString) : UnicodeString;
function LoadTextFromStream(aStream : TStream) : UnicodeString;
function LoadTextFromFile(const filename : TFileName) : UnicodeString;
procedure SaveTextToUTF8File(const filename : TFileName; const text : UTF8String);
procedure AppendTextToUTF8File(const filename : TFileName; const text : UTF8String);
function OpenFileForSequentialReadOnly(const filename : TFileName) : THandle;
function OpenFileForSequentialWriteOnly(const filename : TFileName) : THandle;
procedure CloseFileHandle(hFile : THandle);
function FileWrite(hFile : THandle; buffer : Pointer; byteCount : Integer) : Cardinal;
function FileFlushBuffers(hFile : THandle) : Boolean;
function FileCopy(const existing, new : TFileName; failIfExists : Boolean) : Boolean;
function FileMove(const existing, new : TFileName) : Boolean;
function FileDelete(const filename : TFileName) : Boolean;
function FileRename(const oldName, newName : TFileName) : Boolean;
function FileSize(const name : TFileName) : Int64;
function FileDateTime(const name : TFileName) : TDateTime;
procedure FileSetDateTime(hFile : THandle; aDateTime : TDateTime);
function DeleteDirectory(const path : string) : Boolean;

function DirectSet8087CW(newValue : Word) : Word; register;
function DirectSetMXCSR(newValue : Word) : Word; register;

function SwapBytes(v : Cardinal) : Cardinal;
procedure SwapInt64(src, dest : PInt64);

function RDTSC : UInt64;

function GetCurrentUserName : string;

{$IFNDEF FPC}
// Generics helper functions to handle Delphi 2009 issues - HV
function TtoObject(const t) : TObject; inline;
function TtoPointer(const t) : Pointer; inline;
procedure GetMemForT(var t; size : Integer); inline;
{$ENDIF}

procedure InitializeWithDefaultFormatSettings(var fmt : TFormatSettings);

type
  TTimerEvent = procedure of object;

  ITimer = interface
    procedure Cancel;
  end;

  TTimerTimeout = class(TInterfacedObject, ITimer)
    private
      FTimer : THandle;
      FOnTimer : TTimerEvent;

    public
      class function Create(delayMSec : Cardinal; onTimer : TTimerEvent) : ITimer;
      destructor Destroy; override;

      procedure Cancel;
  end;

  {$IFNDEF SRW_FALLBACK}

type
  SRWLOCK = Pointer;

procedure AcquireSRWLockExclusive(var SRWLOCK : SRWLOCK); stdcall; external 'kernel32.dll';
function TryAcquireSRWLockExclusive(var SRWLOCK : SRWLOCK) : BOOL; stdcall; external 'kernel32.dll';
procedure ReleaseSRWLockExclusive(var SRWLOCK : SRWLOCK); stdcall; external 'kernel32.dll';

procedure AcquireSRWLockShared(var SRWLOCK : SRWLOCK); stdcall; external 'kernel32.dll';
function TryAcquireSRWLockShared(var SRWLOCK : SRWLOCK) : BOOL; stdcall; external 'kernel32.dll';
procedure ReleaseSRWLockShared(var SRWLOCK : SRWLOCK); stdcall; external 'kernel32.dll';
{$ENDIF}


type
  TModuleVersion = record
    Major, Minor : Word;
    Release, Build : Word;
    function AsString : string;
  end;

function GetModuleVersion(instance : THandle; var version : TModuleVersion) : Boolean;
function GetApplicationVersion(var version : TModuleVersion) : Boolean;
function ApplicationVersion : string;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

{$IFDEF FPC}

type
  TFindExInfoLevels = FINDEX_INFO_LEVELS;
  {$ENDIF}


  // GetSystemTimeMilliseconds
  //
function GetSystemTimeMilliseconds : Int64; stdcall;
var
  fileTime : TFileTime;
begin
  {$IFDEF WINDOWS}
  GetSystemTimeAsFileTime(fileTime);
  result := Round(PInt64(@fileTime)^ * 1E-4); // 181
  {$ELSE}
  not yet implemented !
  {$ENDIF}
end;

// GetSystemMilliseconds
//
var
  vGetSystemMilliseconds : function : Int64; stdcall;

function GetSystemMilliseconds : Int64;
{$IFDEF WIN32_ASM}
asm
  jmp [vGetSystemMilliseconds]
  {$ELSE}
begin
  result := vGetSystemMilliseconds;
  {$ENDIF}
end;

// InitializeGetSystemMilliseconds
//
procedure InitializeGetSystemMilliseconds;
var
  h : THandle;
begin
  {$IFDEF WINDOWS}
  h := LoadLibrary('kernel32.dll');
  vGetSystemMilliseconds := GetProcAddress(h, 'GetTickCount64');
  {$ENDIF}
  if not Assigned(vGetSystemMilliseconds) then
      vGetSystemMilliseconds := @GetSystemTimeMilliseconds;
end;

// UTCDateTime
//
function UTCDateTime : TDateTime;
var
  systemTime : TSystemTime;
begin
  {$IFDEF Windows}
  FillChar(systemTime, SizeOf(systemTime), 0);
  GetSystemTime(systemTime);
  with systemTime do
      result := EncodeDate(wYear, wMonth, wDay)
      + EncodeTime(wHour, wMinute, wSecond, wMilliseconds);
  {$ELSE}
  not yet implemented !
  {$ENDIF}
end;

// UnixTime
//
function UnixTime : Int64;
begin
  result := Trunc(UTCDateTime * 86400) - Int64(25569) * 86400;
end;

type
  TDynamicTimeZoneInformation = record
    Bias : Longint;
    StandardName : array [0 .. 31] of WCHAR;
    StandardDate : TSystemTime;
    StandardBias : Longint;
    DaylightName : array [0 .. 31] of WCHAR;
    DaylightDate : TSystemTime;
    DaylightBias : Longint;
    TimeZoneKeyName : array [0 .. 127] of WCHAR;
    DynamicDaylightTimeDisabled : Boolean;
  end;

  PDynamicTimeZoneInformation = ^TDynamicTimeZoneInformation;

function GetDynamicTimeZoneInformation(
  var pTimeZoneInformation : TDynamicTimeZoneInformation) : DWORD; stdcall; external 'kernel32' {$IFNDEF FPC}delayed{$ENDIF};
function GetTimeZoneInformationForYear(wYear : USHORT; lpDynamicTimeZoneInformation : PDynamicTimeZoneInformation;
  var lpTimeZoneInformation : TTimeZoneInformation) : BOOL; stdcall; external 'kernel32' {$IFNDEF FPC}delayed{$ENDIF};
function TzSpecificLocalTimeToSystemTime(lpTimeZoneInformation : pTimeZoneInformation;
  var lpLocalTime, lpUniversalTime : TSystemTime) : BOOL; stdcall; external 'kernel32' {$IFNDEF FPC}delayed{$ENDIF};

// LocalDateTimeToUTCDateTime
//
function LocalDateTimeToUTCDateTime(t : TDateTime) : TDateTime;
var
  localSystemTime, universalSystemTime : TSystemTime;
  tzDynInfo : TDynamicTimeZoneInformation;
  tzInfo : TTimeZoneInformation;
begin
  DateTimeToSystemTime(t, localSystemTime);
  if GetDynamicTimeZoneInformation(tzDynInfo) = TIME_ZONE_ID_INVALID then
      RaiseLastOSError;
  if not GetTimeZoneInformationForYear(localSystemTime.wYear, @tzDynInfo, tzInfo) then
      RaiseLastOSError;
  if not TzSpecificLocalTimeToSystemTime(@tzInfo, localSystemTime, universalSystemTime) then
      RaiseLastOSError;
  result := SystemTimeToDateTime(universalSystemTime);
end;

// UTCDateTimeToLocalDateTime
//
function UTCDateTimeToLocalDateTime(t : TDateTime) : TDateTime;
var
  tzDynInfo : TDynamicTimeZoneInformation;
  tzInfo : TTimeZoneInformation;
  localSystemTime, universalSystemTime : TSystemTime;
begin
  DateTimeToSystemTime(t, universalSystemTime);
  if GetDynamicTimeZoneInformation(tzDynInfo) = TIME_ZONE_ID_INVALID then
      RaiseLastOSError;
  if not GetTimeZoneInformationForYear(localSystemTime.wYear, @tzDynInfo, tzInfo) then
      RaiseLastOSError;
  if not SystemTimeToTzSpecificLocalTime(@tzInfo, universalSystemTime, localSystemTime) then
      RaiseLastOSError;
  result := SystemTimeToDateTime(localSystemTime);
end;

// SystemMillisecondsToUnixTime
//
function SystemMillisecondsToUnixTime(t : Int64) : Int64;
begin
  result := UnixTime - (GetSystemTimeMilliseconds - t) div 1000;
end;

// UnixTimeToSystemMilliseconds
//
function UnixTimeToSystemMilliseconds(ut : Int64) : Int64;
begin
  result := GetSystemTimeMilliseconds - (UnixTime - ut) * 1000;
end;

// SystemSleep
//
procedure SystemSleep(msec : Integer);
begin
  if msec >= 0 then
      Winapi.Windows.Sleep(msec);
end;

// FirstWideCharOfString
//
function FirstWideCharOfString(const s : string; const default : WideChar = #0) : WideChar;
begin
  {$IFDEF FPC}
  if s <> '' then
      result := PWideChar(string(s))^
  else result := default;
  {$ELSE}
  if s <> '' then
      result := PWideChar(Pointer(s))^
  else result := default;
  {$ENDIF}
end;

// CodePointToUnicodeString
//
procedure CodePointToUnicodeString(c : Integer; var result : UnicodeString);
begin
  case c of
    0 .. $FFFF :
      result := WideChar(c);
    $10000 .. $10FFFF :
      begin
        c := c - $10000;
        result := WideChar($D800 + (c shr 10)) + WideChar($DC00 + (c and $3FF));
      end;
  else
    raise EConvertError.CreateFmt('Invalid codepoint: %d', [c]);
  end;
end;

// CodePointToString
//
procedure CodePointToString(const c : Integer; var result : string); inline;
{$IFDEF FPC}
var
  buf : UnicodeString;
begin
  CodePointToUnicodeString(c, buf);
  result := string(buf);
{$ELSE}
begin
  CodePointToUnicodeString(c, result);
  {$ENDIF}
end;

// UnicodeCompareStr
//
{$IFNDEF FPC}

function UnicodeCompareStr(const S1, S2 : string) : Integer;
begin
  result := CompareStr(S1, S2);
end;
{$ENDIF}


// UnicodeStringReplace
//
function UnicodeStringReplace(const s, oldPattern, newPattern : string; flags : TReplaceFlags) : string;
begin
  result := SysUtils.StringReplace(s, oldPattern, newPattern, flags);
end;

function CompareStringEx(
  lpLocaleName : LPCWSTR; dwCmpFlags : DWORD;
  lpString1 : LPCWSTR; cchCount1 : Integer;
  lpString2 : LPCWSTR; cchCount2 : Integer;
  lpVersionInformation : Pointer; lpReserved : LPVOID;
  lParam : lParam) : Integer; stdcall; external 'kernel32.dll';

// UnicodeCompareP
//
function UnicodeCompareP(p1 : PWideChar; n1 : Integer; p2 : PWideChar; n2 : Integer) : Integer;
const
  CSTR_EQUAL = 2;
begin
  result := CompareStringEx(nil, NORM_IGNORECASE, p1, n1, p2, n2, nil, nil, 0) - CSTR_EQUAL;
end;

// UnicodeCompareP
//
function UnicodeCompareP(p1, p2 : PWideChar; n : Integer) : Integer; overload;
const
  CSTR_EQUAL = 2;
begin
  result := CompareStringEx(nil, NORM_IGNORECASE, p1, n, p2, n, nil, nil, 0) - CSTR_EQUAL;
end;

// UnicodeLowerCase
//
function UnicodeLowerCase(const s : UnicodeString) : UnicodeString;
begin
  if s <> '' then
  begin
    result := s;
    UniqueString(result);
    Winapi.Windows.CharLowerBuffW(PWideChar(Pointer(result)), Length(result));
  end
  else result := s;
end;

// UnicodeUpperCase
//
function UnicodeUpperCase(const s : UnicodeString) : UnicodeString;
begin
  if s <> '' then
  begin
    result := s;
    UniqueString(result);
    Winapi.Windows.CharUpperBuffW(PWideChar(Pointer(result)), Length(result));
  end
  else result := s;
end;

{$IFDEF FPC}

// UnicodeLowerCase
//
function UnicodeLowerCase(const s : string) : string;
begin
  result := string(UnicodeLowerCase(UnicodeString(s)));
end;

// UnicodeUpperCase
//
function UnicodeUpperCase(const s : string) : string;
begin
  result := string(UnicodeUpperCase(UnicodeString(s)));
end;
{$ENDIF}


// ASCIICompareText
//
function ASCIICompareText(const S1, S2 : string) : Integer; inline;
begin
  {$IFDEF FPC}
  result := CompareText(UTF8Encode(S1), UTF8Encode(S2));
  {$ELSE}
  result := CompareText(S1, S2);
  {$ENDIF}
end;

// ASCIISameText
//
function ASCIISameText(const S1, S2 : string) : Boolean; inline;
begin
  {$IFDEF FPC}
  result := (ASCIICompareText(S1, S2) = 0);
  {$ELSE}
  result := SameText(S1, S2);
  {$ENDIF}
end;

// NormalizeString
//
function APINormalizeString(normForm : Integer; lpSrcString : LPCWSTR; cwSrcLength : Integer;
  lpDstString : LPWSTR; cwDstLength : Integer) : Integer;
  stdcall; external 'Normaliz.dll' name 'NormalizeString' {$IFNDEF FPC}delayed{$ENDIF};

function NormalizeString(const s, form : string) : string;
var
  nf, len : Integer;
begin
  if s = '' then Exit('');
  if (form = '') or (form = 'NFC') then
      nf := 1
  else if form = 'NFD' then
      nf := 2
  else if form = 'NFKC' then
      nf := 5
  else if form = 'NFKD' then
      nf := 6
  else raise Exception.CreateFmt('Unsupported normalization form "%s"', [form]);
  len := APINormalizeString(nf, Pointer(s), Length(s), nil, 0);
  SetLength(result, len);
  len := APINormalizeString(nf, PWideChar(s), Length(s), Pointer(result), len);
  if len <= 0 then
      RaiseLastOSError;
  SetLength(result, len);
end;

// StripAccents
//
function StripAccents(const s : string) : string;
var
  i : Integer;
  pSrc, pDest : PWideChar;
begin
  result := NormalizeString(s, 'NFD');
  pSrc := Pointer(result);
  pDest := pSrc;
  for i := 1 to Length(result) do
  begin
    case Ord(pSrc^) of
      $300 .. $36F :; // diacritic range
    else
      pDest^ := pSrc^;
      Inc(pDest);
    end;
    Inc(pSrc);
  end;
  SetLength(result, (NativeUInt(pDest) - NativeUInt(Pointer(result))) div 2);
end;

// InterlockedIncrement
//
function InterlockedIncrement(var val : Integer) : Integer;
{$IFNDEF WIN32_ASM}
begin
  result := Winapi.Windows.InterlockedIncrement(val);
{$ELSE}
asm
  mov   ecx,  eax
  mov   eax,  1
  lock  xadd [ecx], eax
  inc   eax
  {$ENDIF}
end;

// InterlockedDecrement
//
function InterlockedDecrement(var val : Integer) : Integer;
{$IFNDEF WIN32_ASM}
begin
  result := Winapi.Windows.InterlockedDecrement(val);
{$ELSE}
asm
  mov   ecx,  eax
  mov   eax,  -1
  lock  xadd [ecx], eax
  dec   eax
  {$ENDIF}
end;

// FastInterlockedIncrement
//
procedure FastInterlockedIncrement(var val : Integer);
{$IFNDEF WIN32_ASM}
begin
  InterlockedIncrement(val);
{$ELSE}
asm
  lock  inc [eax]
  {$ENDIF}
end;

// FastInterlockedDecrement
//
procedure FastInterlockedDecrement(var val : Integer);
{$IFNDEF WIN32_ASM}
begin
  InterlockedDecrement(val);
{$ELSE}
asm
  lock  dec [eax]
  {$ENDIF}
end;

// InterlockedExchangePointer
//
function InterlockedExchangePointer(var target : Pointer; val : Pointer) : Pointer;
{$IFNDEF WIN32_ASM}
begin
  {$IFDEF FPC}
  result := System.InterLockedExchange(target, val);
  {$ELSE}
  result := Winapi.Windows.InterlockedExchangePointer(target, val);
  {$ENDIF}
{$ELSE}
asm
  lock  xchg dword ptr [eax], edx
  mov   eax, edx
  {$ENDIF}
end;

// InterlockedCompareExchangePointer
//
function InterlockedCompareExchangePointer(var destination : Pointer; exchange, comparand : Pointer) : Pointer; {$IFDEF PUREPASCAL} inline; {$ENDIF}
begin
  {$IFDEF FPC}
  {$IFDEF CPU64}
  result := Pointer(System.InterlockedCompareExchange64(QWord(destination), QWord(exchange), QWord(comparand)));
  {$ELSE}
  result := System.InterLockedCompareExchange(destination, exchange, comparand);
  {$ENDIF}
  {$ELSE}
  result := Winapi.Windows.InterlockedCompareExchangePointer(destination, exchange, comparand);
  {$ENDIF}
end;

// SetThreadName
//
function IsDebuggerPresent : BOOL; stdcall; external kernel32 name 'IsDebuggerPresent';

procedure SetThreadName(const threadName : PAnsiChar; threadID : Cardinal = Cardinal(-1));
// http://www.codeproject.com/Articles/8549/Name-your-threads-in-the-VC-debugger-thread-list
type
  TThreadNameInfo = record
    dwType : Cardinal;     // must be 0x1000
    szName : PAnsiChar;    // pointer to name (in user addr space)
    dwThreadID : Cardinal; // thread ID (-1=caller thread)
    dwFlags : Cardinal;    // reserved for future use, must be zero
  end;
var
  info : TThreadNameInfo;
begin
  if not IsDebuggerPresent then Exit;

  info.dwType := $1000;
  info.szName := threadName;
  info.dwThreadID := threadID;
  info.dwFlags := 0;
  {$IFNDEF FPC}
  try
    RaiseException($406D1388, 0, SizeOf(info) div SizeOf(Cardinal), @info);
  except
  end;
  {$ENDIF}
end;

// OutputDebugString
//
procedure OutputDebugString(const msg : string);
begin
  Winapi.Windows.OutputDebugStringW(PWideChar(msg));
end;

// WriteToOSEventLog
//
procedure WriteToOSEventLog(const logName, logCaption, logDetails : string;
  const logRawData : RawByteString = '');
var
  eventSource : THandle;
  detailsPtr : array [0 .. 1] of PWideChar;
begin
  if logName <> '' then
      eventSource := RegisterEventSourceW(nil, PWideChar(logName))
  else eventSource := RegisterEventSourceW(nil, PWideChar(ChangeFileExt(ExtractFileName(ParamStr(0)), '')));
  if eventSource > 0 then
  begin
    try
      detailsPtr[0] := PWideChar(logCaption);
      detailsPtr[1] := PWideChar(logDetails);
      ReportEventW(eventSource, EVENTLOG_INFORMATION_TYPE, 0, 0, nil,
        2, Length(logRawData),
        @detailsPtr, Pointer(logRawData));
    finally
      DeregisterEventSource(eventSource);
    end;
  end;
end;

// SetDecimalSeparator
//
procedure SetDecimalSeparator(c : Char);
begin
  {$IFDEF FPC}
  formatSettings.DecimalSeparator := c;
  {$ELSE}
  {$IF CompilerVersion >= 22.0}
  formatSettings.DecimalSeparator := c;
  {$ELSE}
  DecimalSeparator := c;
  {$IFEND}
  {$ENDIF}
end;

// GetDecimalSeparator
//
function GetDecimalSeparator : Char;
begin
  {$IFDEF FPC}
  result := formatSettings.DecimalSeparator;
  {$ELSE}
  {$IF CompilerVersion >= 22.0}
  result := formatSettings.DecimalSeparator;
  {$ELSE}
  result := DecimalSeparator;
  {$IFEND}
  {$ENDIF}
end;

// CollectFiles
//
type
  TFindDataRec = record
    Handle : THandle;
    data : TWin32FindDataW;
  end;

  TMasks = array of TMask;

  // CollectFilesMasked
  //
procedure CollectFilesMasked(const directory : TFileName;
  const Masks : TMasks; list : TStrings;
  recurseSubdirectories : Boolean = False;
  onProgress : TCollectFileProgressEvent = nil);
const
  // contant defined in Windows.pas is incorrect
  FindExInfoBasic = 1;
var
  searchRec : TFindDataRec;
  infoLevel : TFindExInfoLevels;
  filename : TFileName;
  skipScan, addToList : Boolean;
  i : Integer;
begin
  // 6.1 required for FindExInfoBasic (Win 2008 R2 or Win 7)
  if ((Win32MajorVersion shl 8) or Win32MinorVersion) >= $601 then
      infoLevel := TFindExInfoLevels(FindExInfoBasic)
  else infoLevel := FindExInfoStandard;

  if Assigned(onProgress) then
  begin
    skipScan := False;
    onProgress(directory, skipScan);
    if skipScan then Exit;
  end;

  filename := directory + '*';
  searchRec.Handle := FindFirstFileEx(PChar(filename), infoLevel,
    @searchRec.data, FINDEX_SEARCH_OPS.FindExSearchNameMatch,
    nil, 0);
  if searchRec.Handle <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if (searchRec.data.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
      begin
        // check file against mask
        filename := searchRec.data.cFileName;
        addToList := True;
        for i := 0 to high(Masks) do
        begin
          addToList := Masks[i].Matches(filename);
          if addToList then Break;
        end;
        if addToList then
        begin
          filename := directory + filename;
          list.Add(filename);
        end;
      end else if recurseSubdirectories then
      begin
        // dive in subdirectory
        if searchRec.data.cFileName[0] = '.' then
        begin
          if searchRec.data.cFileName[1] = '.' then
          begin
            if searchRec.data.cFileName[2] = #0 then continue;
          end else if searchRec.data.cFileName[1] = #0 then continue;
        end;
        // decomposed cast and concatenation to avoid implicit string variable
        filename := searchRec.data.cFileName;
        filename := directory + filename + PathDelim;
        CollectFilesMasked(filename, Masks, list, True, onProgress);
      end;
    until not FindNextFileW(searchRec.Handle, searchRec.data);
    Winapi.Windows.FindClose(searchRec.Handle);
  end;
end;

// CollectFiles
//
procedure CollectFiles(const directory, fileMask : TFileName; list : TStrings;
  recurseSubdirectories : Boolean = False;
  onProgress : TCollectFileProgressEvent = nil);
var
  Masks : TMasks;
  p, pNext : Integer;
begin
  if fileMask <> '' then
  begin
    p := 1;
    repeat
      pNext := PosEx(';', fileMask, p);
      if pNext < p then
      begin
        SetLength(Masks, Length(Masks) + 1);
        Masks[high(Masks)] := TMask.Create(Copy(fileMask, p));
        Break;
      end;
      if pNext > p then
      begin
        SetLength(Masks, Length(Masks) + 1);
        Masks[high(Masks)] := TMask.Create(Copy(fileMask, p, pNext - p));
      end;
      p := pNext + 1;
    until p > Length(fileMask);
  end;
  // Windows can match 3 character filters with old DOS filenames
  // Mask confirmation is necessary
  try
    CollectFilesMasked(IncludeTrailingPathDelimiter(directory), Masks,
      list, recurseSubdirectories, onProgress);
  finally
    for p := 0 to high(Masks) do
        Masks[p].Free;
  end;
end;

// CollectSubDirs
//
procedure CollectSubDirs(const directory : TFileName; list : TStrings);
const
  // contant defined in Windows.pas is incorrect
  FindExInfoBasic = 1;
var
  searchRec : TFindDataRec;
  infoLevel : TFindExInfoLevels;
  filename : TFileName;
begin
  // 6.1 required for FindExInfoBasic (Win 2008 R2 or Win 7)
  if ((Win32MajorVersion shl 8) or Win32MinorVersion) >= $601 then
      infoLevel := TFindExInfoLevels(FindExInfoBasic)
  else infoLevel := FindExInfoStandard;

  filename := directory + '*';
  searchRec.Handle := FindFirstFileEx(PChar(filename), infoLevel,
    @searchRec.data, FINDEX_SEARCH_OPS.FindExSearchLimitToDirectories,
    nil, 0);
  if searchRec.Handle <> INVALID_HANDLE_VALUE then
  begin
    repeat
      if (searchRec.data.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
      begin
        if searchRec.data.cFileName[0] = '.' then
        begin
          if searchRec.data.cFileName[1] = '.' then
          begin
            if searchRec.data.cFileName[2] = #0 then continue;
          end else if searchRec.data.cFileName[1] = #0 then continue;
        end;
        // decomposed cast and concatenation to avoid implicit string variable
        filename := searchRec.data.cFileName;
        list.Add(filename);
      end;
    until not FindNextFileW(searchRec.Handle, searchRec.data);
    Winapi.Windows.FindClose(searchRec.Handle);
  end;
end;

{$IFDEF FPC}

// VarCopy
//
procedure VarCopy(out dest : Variant; const src : Variant);
begin
  dest := src;
end;
{$ELSE}

// VarToUnicodeStr
//
function VarToUnicodeStr(const v : Variant) : string; inline;
begin
  result := VarToStr(v);
end;
{$ENDIF FPC}

{$IFDEF FPC}

// Utf8ToUnicodeString
//
function Utf8ToUnicodeString(const buf : RawByteString) : UnicodeString; inline;
begin
  result := UTF8Decode(buf);
end;
{$ENDIF}


// RawByteStringToBytes
//
function RawByteStringToBytes(const buf : RawByteString) : TBytes;
var
  n : Integer;
begin
  n := Length(buf);
  SetLength(result, n);
  if n > 0 then
      System.Move(buf[1], result[0], n);
end;

// BytesToRawByteString
//
function BytesToRawByteString(const buf : TBytes; startIndex : Integer = 0) : RawByteString;
var
  n : Integer;
begin
  n := Length(buf) - startIndex;
  if n <= 0 then
      result := ''
  else
  begin
    SetLength(result, n);
    System.Move(buf[startIndex], Pointer(result)^, n);
  end;
end;

// BytesToRawByteString
//
function BytesToRawByteString(p : Pointer; size : Integer) : RawByteString;
begin
  SetLength(result, size);
  System.Move(p^, Pointer(result)^, size);
end;

// TryTextToFloat
//
function TryTextToFloat(const s : PChar; var value : Extended; const formatSettings : TFormatSettings) : Boolean;
{$IFDEF FPC}
var
  cw : Word;
begin
  cw := Get8087CW;
  Set8087CW($133F);
  if TryStrToFloat(s, value, formatSettings) then
      result := (value > -1.7E308) and (value < 1.7E308);
  if not result then
      value := 0;
  asm fclex
  end;
  Set8087CW(cw);
{$ELSE}
begin
  result := TextToFloat(s, value, fvExtended, formatSettings)
  {$ENDIF}
end;

// TryTextToFloatW
//
function TryTextToFloatW(const s : PWideChar; var value : Extended;
  const formatSettings : TFormatSettings) : Boolean;
{$IFDEF FPC}
var
  bufU : UnicodeString;
  buf : string;
begin
  bufU := s;
  buf := string(bufU);
  result := TryTextToFloat(PChar(buf), value, formatSettings);
{$ELSE}
begin
  result := TextToFloat(s, value, fvExtended, formatSettings)
  {$ENDIF}
end;

// LoadTextFromBuffer
//
function LoadTextFromBuffer(const buf : TBytes) : UnicodeString;
var
  n, sourceLen, len : Integer;
  encoding : TEncoding;
begin
  if buf = nil then
      result := ''
  else
  begin
    encoding := nil;
    n := TEncoding.GetBufferEncoding(buf, encoding);
    if n = 0 then
        encoding := TEncoding.UTF8;
    if encoding = TEncoding.UTF8 then
    begin
      // handle UTF-8 directly, encoding.GetString returns an empty string
      // whenever a non-utf-8 character is detected, the implementation below
      // will return a '?' for non-utf8 characters instead
      sourceLen := Length(buf) - n;
      SetLength(result, sourceLen);
      len := Utf8ToUnicode(Pointer(result), sourceLen + 1, PAnsiChar(buf) + n, sourceLen) - 1;
      if len > 0 then
      begin
        if len <> sourceLen then
            SetLength(result, len);
      end
      else result := ''
    end
    else
    begin
      result := encoding.GetString(buf, n, Length(buf) - n);
    end;
  end;
end;

// LoadTextFromRawBytes
//
function LoadTextFromRawBytes(const buf : RawByteString) : UnicodeString;
var
  b : TBytes;
begin
  if buf = '' then Exit('');
  SetLength(b, Length(buf));
  System.Move(buf[1], b[0], Length(buf));
  result := LoadTextFromBuffer(b);
end;

// LoadTextFromStream
//
function LoadTextFromStream(aStream : TStream) : UnicodeString;
var
  n : Integer;
  buf : TBytes;
begin
  n := aStream.size - aStream.Position;
  SetLength(buf, n);
  aStream.Read(buf[0], n);
  result := LoadTextFromBuffer(buf);
end;

// LoadTextFromFile
//
function LoadTextFromFile(const filename : TFileName) : UnicodeString;
var
  buf : TBytes;
begin
  buf := LoadDataFromFile(filename);
  result := LoadTextFromBuffer(buf);
end;

// ReadFileChunked
//
function ReadFileChunked(hFile : THandle; const buffer; size : Integer) : Integer;
const
  CHUNK_SIZE = 16384;
var
  p : PByte;
  nRemaining : Integer;
  nRead : Cardinal;
begin
  p := @buffer;
  nRemaining := size;
  repeat
    if nRemaining > CHUNK_SIZE then
        nRead := CHUNK_SIZE
    else nRead := nRemaining;
    if not ReadFile(hFile, p^, nRead, nRead, nil) then
        RaiseLastOSError
    else if nRead = 0 then
    begin
      // file got trimmed while we were reading
      Exit(size - nRemaining);
    end;
    dec(nRemaining, nRead);
    Inc(p, nRead);
  until nRemaining <= 0;
  result := size;
end;

// LoadDataFromFile
//
function LoadDataFromFile(const filename : TFileName) : TBytes;
const
  INVALID_FILE_SIZE = DWORD($FFFFFFFF);
var
  hFile : THandle;
  n, nRead : Cardinal;
begin
  if filename = '' then Exit(nil);
  hFile := OpenFileForSequentialReadOnly(filename);
  if hFile = INVALID_HANDLE_VALUE then Exit(nil);
  try
    n := GetFileSize(hFile, nil);
    if n = INVALID_FILE_SIZE then
        RaiseLastOSError;
    if n > 0 then
    begin
      SetLength(result, n);
      nRead := ReadFileChunked(hFile, result[0], n);
      if nRead < n then
          SetLength(result, nRead);
    end
    else result := nil;
  finally
    CloseHandle(hFile);
  end;
end;

// SaveDataToFile
//
procedure SaveDataToFile(const filename : TFileName; const data : TBytes);
var
  hFile : THandle;
  n, nWrite : DWORD;
begin
  hFile := OpenFileForSequentialWriteOnly(filename);
  try
    n := Length(data);
    if n > 0 then
      if not WriteFile(hFile, data[0], n, nWrite, nil) then
          RaiseLastOSError;
  finally
    CloseHandle(hFile);
  end;
end;

// LoadRawBytesFromFile
//
function LoadRawBytesFromFile(const filename : TFileName) : RawByteString;
const
  INVALID_FILE_SIZE = DWORD($FFFFFFFF);
var
  hFile : THandle;
  n, nRead : Cardinal;
begin
  if filename = '' then Exit;
  hFile := OpenFileForSequentialReadOnly(filename);
  if hFile = INVALID_HANDLE_VALUE then Exit;
  try
    n := GetFileSize(hFile, nil);
    if n = INVALID_FILE_SIZE then
        RaiseLastOSError;
    if n > 0 then
    begin
      SetLength(result, n);
      nRead := ReadFileChunked(hFile, Pointer(result)^, n);
      if nRead < n then
          SetLength(result, nRead);
    end;
  finally
    CloseHandle(hFile);
  end;
end;

// SaveRawBytesToFile
//
function SaveRawBytesToFile(const filename : TFileName; const data : RawByteString) : Integer;
var
  hFile : THandle;
  nWrite : DWORD;
begin
  result := 0;
  hFile := OpenFileForSequentialWriteOnly(filename);
  try
    if data <> '' then
    begin
      result := Length(data);
      if not WriteFile(hFile, data[1], result, nWrite, nil) then
          RaiseLastOSError;
    end;
  finally
    CloseHandle(hFile);
  end;
end;

// LoadRawBytesAsScriptStringFromFile
//
procedure LoadRawBytesAsScriptStringFromFile(const filename : TFileName; var result : string);
const
  INVALID_FILE_SIZE = DWORD($FFFFFFFF);
var
  hFile : THandle;
  n, i, nRead : Cardinal;
  pDest : PWord;
  buffer : array [0 .. 16383] of Byte;
begin
  if filename = '' then Exit;
  hFile := OpenFileForSequentialReadOnly(filename);
  if hFile = INVALID_HANDLE_VALUE then Exit;
  try
    n := GetFileSize(hFile, nil);
    if n = INVALID_FILE_SIZE then
        RaiseLastOSError;
    if n > 0 then
    begin
      SetLength(result, n);
      pDest := Pointer(result);
      repeat
        if n > SizeOf(buffer) then
            nRead := SizeOf(buffer)
        else nRead := n;
        if not ReadFile(hFile, buffer, nRead, nRead, nil) then
            RaiseLastOSError
        else if nRead = 0 then
        begin
          // file got trimmed while we were reading
          SetLength(result, Length(result) - Integer(n));
          Break;
        end;
        for i := 1 to nRead do
        begin
          pDest^ := buffer[i - 1];
          Inc(pDest);
        end;
        dec(n, nRead);
      until n <= 0;
    end;
  finally
    CloseHandle(hFile);
  end;
end;

// SaveTextToUTF8File
//
procedure SaveTextToUTF8File(const filename : TFileName; const text : UTF8String);
begin
  SaveRawBytesToFile(filename, UTF8Encode(text));
end;

// AppendTextToUTF8File
//
procedure AppendTextToUTF8File(const filename : TFileName; const text : UTF8String);
var
  fs : TFileStream;
begin
  if text = '' then Exit;
  if FileExists(filename) then
      fs := TFileStream.Create(filename, fmOpenWrite or fmShareDenyNone)
  else fs := TFileStream.Create(filename, fmCreate);
  try
    fs.Seek(0, soFromEnd);
    fs.Write(text[1], Length(text));
  finally
    fs.Free;
  end;
end;

// OpenFileForSequentialReadOnly
//
function OpenFileForSequentialReadOnly(const filename : TFileName) : THandle;
begin
  result := CreateFile(PChar(filename), GENERIC_READ, FILE_SHARE_READ + FILE_SHARE_WRITE,
    nil, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if result = INVALID_HANDLE_VALUE then
  begin
    if GetLastError <> ERROR_FILE_NOT_FOUND then
        RaiseLastOSError;
  end;
end;

// OpenFileForSequentialWriteOnly
//
function OpenFileForSequentialWriteOnly(const filename : TFileName) : THandle;
begin
  result := CreateFile(PChar(filename), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL + FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if result = INVALID_HANDLE_VALUE then
      RaiseLastOSError;
end;

// CloseFileHandle
//
procedure CloseFileHandle(hFile : THandle);
begin
  CloseHandle(hFile);
end;

// FileWrite
//
function FileWrite(hFile : THandle; buffer : Pointer; byteCount : Integer) : Cardinal;
begin
  if not WriteFile(hFile, buffer^, byteCount, result, nil) then
      RaiseLastOSError;
end;

// FileFlushBuffers
//
function FlushFileBuffers(hFile : THandle) : BOOL; stdcall; external 'kernel32.dll';

function FileFlushBuffers(hFile : THandle) : Boolean;
begin
  result := FlushFileBuffers(hFile);
end;

// FileCopy
//
function FileCopy(const existing, new : TFileName; failIfExists : Boolean) : Boolean;
begin
  result := Winapi.Windows.CopyFileW(PWideChar(existing), PWideChar(new), failIfExists);
end;

// FileMove
//
function FileMove(const existing, new : TFileName) : Boolean;
begin
  result := Winapi.Windows.MoveFileW(PWideChar(existing), PWideChar(new));
end;

// FileDelete
//
function FileDelete(const filename : TFileName) : Boolean;
begin
  result := SysUtils.DeleteFile(filename);
end;

// FileRename
//
function FileRename(const oldName, newName : TFileName) : Boolean;
begin
  result := RenameFile(oldName, newName);
end;

// FileSize
//
function FileSize(const name : TFileName) : Int64;
var
  info : TWin32FileAttributeData;
begin
  if GetFileAttributesExW(PWideChar(Pointer(name)), GetFileExInfoStandard, @info) then
      result := info.nFileSizeLow or (Int64(info.nFileSizeHigh) shl 32)
  else result := -1;
end;

// FileDateTime
//
function FileDateTime(const name : TFileName) : TDateTime;
var
  info : TWin32FileAttributeData;
  localTime : TFileTime;
  systemTime : TSystemTime;
begin
  if GetFileAttributesExW(PWideChar(Pointer(name)), GetFileExInfoStandard, @info) then
  begin
    FileTimeToLocalFileTime(info.ftLastWriteTime, localTime);
    FileTimeToSystemTime(localTime, systemTime);
    result := SystemTimeToDateTime(systemTime);
  end
  else result := 0;
end;

// FileSetDateTime
//
procedure FileSetDateTime(hFile : THandle; aDateTime : TDateTime);
begin
  FileSetDate(hFile, DateTimeToFileDate(aDateTime));
end;

// DeleteDirectory
//
function DeleteDirectory(const path : string) : Boolean;
begin
  {$IFDEF FPC}
  result := RemoveDir(path);
  {$ELSE}
  try
    TDirectory.Delete(path, True);
  except
    Exit(False);
  end;
  result := not TDirectory.Exists(path);
  {$ENDIF}
end;

// DirectSet8087CW
//
function DirectSet8087CW(newValue : Word) : Word; register;
{$IFNDEF WIN32_ASM}
begin
  result := newValue;
{$ELSE}
asm
  push    eax
  push    eax
  fnstcw  [esp]
  fnclex
  pop     eax
  fldcw   [esp]
  pop     edx
  {$ENDIF}
end;

// DirectSetMXCSR
//
function DirectSetMXCSR(newValue : Word) : Word; register;
{$IFDEF WIN32_ASM}
asm
  and      eax, $FFC0
  push     eax
  push     eax
  stmxcsr  [esp+4]
  ldmxcsr  [esp]
  pop eax
  pop eax
  {$ELSE}
begin
  result := newValue;
  {$ENDIF}
end;

// SwapBytes
//
function SwapBytes(v : Cardinal) : Cardinal;
{$IFDEF WIN32_ASM}
asm
  bswap eax
  {$ELSE}
type
  TCardinalBytes = array [0 .. 3] of Byte;
begin
  TCardinalBytes(result)[0] := TCardinalBytes(v)[3];
  TCardinalBytes(result)[1] := TCardinalBytes(v)[2];
  TCardinalBytes(result)[2] := TCardinalBytes(v)[1];
  TCardinalBytes(result)[3] := TCardinalBytes(v)[0];
  {$ENDIF}
end;

// SwapInt64
//
procedure SwapInt64(src, dest : PInt64);
{$IFDEF WIN32_ASM}
asm
  mov   ecx, [eax]
  mov   eax, [eax+4]
  bswap ecx
  bswap eax
  mov   [edx+4], ecx
  mov   [edx], eax
  {$ELSE}
begin
  PByteArray(dest)[0] := PByteArray(src)[7];
  PByteArray(dest)[1] := PByteArray(src)[6];
  PByteArray(dest)[2] := PByteArray(src)[5];
  PByteArray(dest)[3] := PByteArray(src)[4];
  PByteArray(dest)[4] := PByteArray(src)[3];
  PByteArray(dest)[5] := PByteArray(src)[2];
  PByteArray(dest)[6] := PByteArray(src)[1];
  PByteArray(dest)[7] := PByteArray(src)[0];
  {$ENDIF}
end;

// RDTSC
//
function RDTSC : UInt64;
asm
  RDTSC
end;

// GetCurrentUserName
//
function GetCurrentUserName : string;
var
  len : Cardinal;
begin
  len := 255;
  SetLength(result, len);
  Winapi.Windows.GetUserNameW(PWideChar(result), len);
  SetLength(result, len - 1);
end;

{$IFNDEF FPC}

// Delphi 2009 is not able to cast a generic T instance to TObject or Pointer
function TtoObject(const t) : TObject;
begin
  // Manually inlining the code would require the IF-defs
  // {$IF Compilerversion >= 21}
  result := TObject(t);
  // {$ELSE}
  // Result := PObject(@T)^;
  // {$IFEND}
end;

function TtoPointer(const t) : Pointer;
begin
  // Manually inlining the code would require the IF-defs
  // {$IF Compilerversion >= 21}
  result := Pointer(t);
  // {$ELSE}
  // Result := PPointer(@T)^;
  // {$IFEND}
end;

procedure GetMemForT(var t; size : Integer); inline;
begin
  GetMem(Pointer(t), size);
end;
{$ENDIF}


// InitializeWithDefaultFormatSettings
//
procedure InitializeWithDefaultFormatSettings(var fmt : TFormatSettings);
begin
  {$IFDEF DELPHI_XE_PLUS}
  fmt := SysUtils.formatSettings;
  {$ELSE}
  fmt := SysUtils.TFormatSettings((@CurrencyString{ %H- })^);
  {$ENDIF}
end;

// AsString
//
function TModuleVersion.AsString : string;
begin
  result := Format('%d.%d.%d.%d', [Major, Minor, Release, Build]);
end;

// Adapted from Ian Boyd code published in
// http://stackoverflow.com/questions/10854958/how-to-get-version-of-running-executable
function GetModuleVersion(instance : THandle; var version : TModuleVersion) : Boolean;
var
  fileInformation : PVSFIXEDFILEINFO;
  verlen : Cardinal;
  rs : TResourceStream;
  m : TMemoryStream;
  resource : HRSRC;
begin
  result := False;

  // Workaround bug in Delphi if resource doesn't exist
  resource := FindResource(instance, PChar(1), RT_VERSION);
  if resource = 0 then Exit;

  m := TMemoryStream.Create;
  try
    rs := TResourceStream.CreateFromID(instance, 1, RT_VERSION);
    try
      m.CopyFrom(rs, rs.size);
    finally
      rs.Free;
    end;

    m.Position := 0;
    if VerQueryValue(m.Memory, '\', Pointer(fileInformation), verlen) then
    begin
      version.Major := fileInformation.dwFileVersionMS shr 16;
      version.Minor := fileInformation.dwFileVersionMS and $FFFF;
      version.Release := fileInformation.dwFileVersionLS shr 16;
      version.Build := fileInformation.dwFileVersionLS and $FFFF;
      result := True;
    end;
  finally
    m.Free;
  end;
end;

// GetApplicationVersion
//
var
  vApplicationVersion : TModuleVersion;
  vApplicationVersionRetrieved : Integer;

function GetApplicationVersion(var version : TModuleVersion) : Boolean;
begin
  if vApplicationVersionRetrieved = 0 then
  begin
    if GetModuleVersion(HInstance, vApplicationVersion) then
        vApplicationVersionRetrieved := 1
    else vApplicationVersionRetrieved := -1;
  end;
  result := (vApplicationVersionRetrieved = 1);
  if result then
      version := vApplicationVersion;
end;

// ApplicationVersion
//
function ApplicationVersion : string;
var
  version : TModuleVersion;
begin
  if GetApplicationVersion(version) then
      result := version.AsString
  else result := '?.?.?.?';
end;

// ------------------
// ------------------ TdwsCriticalSection ------------------
// ------------------

// Create
//
constructor TdwsCriticalSection.Create;
begin
  InitializeCriticalSection(FCS);
end;

// Destroy
//
destructor TdwsCriticalSection.Destroy;
begin
  DeleteCriticalSection(FCS);
end;

// Enter
//
procedure TdwsCriticalSection.Enter;
begin
  EnterCriticalSection(FCS);
end;

// Leave
//
procedure TdwsCriticalSection.Leave;
begin
  LeaveCriticalSection(FCS);
end;

// TryEnter
//
function TdwsCriticalSection.TryEnter : Boolean;
begin
  result := TryEnterCriticalSection(FCS);
end;

// ------------------
// ------------------ TPath ------------------
// ------------------

// GetTempPath
//
class function TPath.GetTempPath : string;
{$IFDEF WINDOWS}
var
  tempPath : array [0 .. MAX_PATH] of WideChar; // Buf sizes are MAX_PATH+1
begin
  if Winapi.Windows.GetTempPath(MAX_PATH, @tempPath[0]) = 0 then
  begin
    tempPath[1] := '.'; // Current directory
    tempPath[2] := #0;
  end;
  result := tempPath;
{$ELSE}
begin
  result := IOUtils.TPath.GetTempPath;
  {$ENDIF}
end;

// GetTempFileName
//
class function TPath.GetTempFileName : string;
{$IFDEF WINDOWS}
var
  tempPath, tempFileName : array [0 .. MAX_PATH] of WideChar; // Buf sizes are MAX_PATH+1
begin
  if Winapi.Windows.GetTempPath(MAX_PATH, @tempPath[0]) = 0 then
  begin
    tempPath[1] := '.'; // Current directory
    tempPath[2] := #0;
  end;
  if Winapi.Windows.GetTempFileNameW(@tempPath[0], 'DWS', 0, tempFileName) = 0 then
      RaiseLastOSError; // should never happen
  result := tempFileName;
{$ELSE}
begin
  result := IOUtils.TPath.GetTempFileName;
  {$ENDIF}
end;

// ------------------
// ------------------ TFile ------------------
// ------------------

// ReadAllBytes
//
class function TFile.ReadAllBytes(const filename : string) : TBytes;
{$IFDEF VER200} // Delphi 2009
var
  fileStream : TFileStream;
  n : Integer;
begin
  fileStream := TFileStream.Create(filename, fmOpenRead or fmShareDenyWrite);
  try
    n := fileStream.size;
    SetLength(result, n);
    if n > 0 then
        fileStream.ReadBuffer(result[0], n);
  finally
    fileStream.Free;
  end;
{$ELSE}

begin
  result := IOUtils.TFile.ReadAllBytes(filename);
  {$ENDIF}
end;

// ------------------
// ------------------ TdwsThread ------------------
// ------------------

{$IFNDEF FPC}
{$IFDEF VER200}


// Start
//
procedure TdwsThread.Start;
begin
  Resume;
end;

{$ENDIF}
{$ENDIF}

// ------------------
// ------------------ TMultiReadSingleWrite ------------------
// ------------------

{$IFNDEF SRW_FALLBACK}

procedure TMultiReadSingleWrite.BeginRead;
begin
  AcquireSRWLockShared(FSRWLock);
end;

function TMultiReadSingleWrite.TryBeginRead : Boolean;
begin
  result := TryAcquireSRWLockShared(FSRWLock);
end;

procedure TMultiReadSingleWrite.EndRead;
begin
  ReleaseSRWLockShared(FSRWLock)
end;

procedure TMultiReadSingleWrite.BeginWrite;
begin
  AcquireSRWLockExclusive(FSRWLock);
end;

function TMultiReadSingleWrite.TryBeginWrite : Boolean;
begin
  result := TryAcquireSRWLockExclusive(FSRWLock);
end;

procedure TMultiReadSingleWrite.EndWrite;
begin
  ReleaseSRWLockExclusive(FSRWLock)
end;

function TMultiReadSingleWrite.State : TMultiReadSingleWriteState;
begin
  // Attempt to guess the state of the lock without making assumptions
  // about implementation details
  // This is only for diagnosing locking issues
  if TryBeginWrite then
  begin
    EndWrite;
    result := mrswUnlocked;
  end else if TryBeginRead then
  begin
    EndRead;
    result := mrswReadLock;
  end
  else
  begin
    result := mrswWriteLock;
  end;
end;
{$ELSE}
// SRW_FALLBACK
constructor TMultiReadSingleWrite.Create;
begin
  FLock := TdwsCriticalSection.Create;
end;

destructor TMultiReadSingleWrite.Destroy;
begin
  FLock.Free;
end;

procedure TMultiReadSingleWrite.BeginRead;
begin
  FLock.Enter;
end;

function TMultiReadSingleWrite.TryBeginRead : Boolean;
begin
  result := FLock.TryEnter;
end;

procedure TMultiReadSingleWrite.EndRead;
begin
  FLock.Leave;
end;

procedure TMultiReadSingleWrite.BeginWrite;
begin
  FLock.Enter;
end;

function TMultiReadSingleWrite.TryBeginWrite : Boolean;
begin
  result := FLock.TryEnter;
end;

procedure TMultiReadSingleWrite.EndWrite;
begin
  FLock.Leave;
end;

function TMultiReadSingleWrite.State : TMultiReadSingleWriteState;
begin
  if FLock.TryEnter then
  begin
    FLock.Leave;
    result := mrswUnlocked;
  end
  else result := mrswWriteLock;
end;

{$ENDIF}

// ------------------
// ------------------ TTimerTimeout ------------------
// ------------------

{$IFDEF FPC}

type
  TWaitOrTimerCallback = procedure(Context : Pointer; Success : Boolean); stdcall;
function CreateTimerQueueTimer(out phNewTimer : THandle;
  TimerQueue : THandle; CallBack : TWaitOrTimerCallback;
  Parameter : Pointer; DueTime : DWORD; Period : DWORD; flags : ULONG) : BOOL; stdcall; external 'kernel32.dll';
function DeleteTimerQueueTimer(TimerQueue : THandle;
  Timer : THandle; CompletionEvent : THandle) : BOOL; stdcall; external 'kernel32.dll';
const
  WT_EXECUTEDEFAULT      = ULONG($00000000);
  WT_EXECUTEONLYONCE     = ULONG($00000008);
  WT_EXECUTELONGFUNCTION = ULONG($00000010);
  {$ENDIF}


procedure TTimerTimeoutCallBack(Context : Pointer; { %H- }Success : Boolean); stdcall;
var
  tt : TTimerTimeout;
  event : TTimerEvent;
begin
  tt := TTimerTimeout(Context);
  tt._AddRef;
  try
    event := tt.FOnTimer;
    if Assigned(event) then
        event();
    DeleteTimerQueueTimer(0, tt.FTimer, 0);
    tt.FTimer := 0;
  finally
    tt._Release;
  end;
end;

// Create
//
class function TTimerTimeout.Create(delayMSec : Cardinal; onTimer : TTimerEvent) : ITimer;
var
  obj : TTimerTimeout;
begin
  obj := TTimerTimeout(inherited Create);
  result := obj;
  obj.FOnTimer := onTimer;
  CreateTimerQueueTimer(obj.FTimer, 0, TTimerTimeoutCallBack, obj,
    delayMSec, 0,
    WT_EXECUTEDEFAULT or WT_EXECUTELONGFUNCTION or WT_EXECUTEONLYONCE);
end;

// Destroy
//
destructor TTimerTimeout.Destroy;
begin
  Cancel;
  inherited;
end;

// Cancel
//
procedure TTimerTimeout.Cancel;
begin
  FOnTimer := nil;
  if FTimer = 0 then Exit;
  DeleteTimerQueueTimer(0, FTimer, INVALID_HANDLE_VALUE);
  FTimer := 0;
end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
initialization

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

InitializeGetSystemMilliseconds;

end.

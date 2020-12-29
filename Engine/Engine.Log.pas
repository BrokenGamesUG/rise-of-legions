unit Engine.Log;

interface

uses
  Winapi.Windows,
  SysUtils,
  Classes,
  Vcl.Forms,
  SyncObjs,
  Winapi.DXGIType;
// This file musn't include any custom files, because it is used by all of them

{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}


type
  CException = class of Exception;

  EnumErrorLevel = (elDebug, elInfo, elWarning, elError);

  /// <summary> This helper class logs messages to an errorfile. This is placed to the exe and is named "Error.log". </summary>
  HLog = class
    protected
      const
      LOG_FILE_ROTATION = 3;
    var
      class var ProfilingTimeStamp : int64;
      class var ConsoleOpened : boolean;
      class var Semaphore : TMutex;
      class var FirstLog : boolean;
      class var StartDate : TDateTime;
      class var StartTime : TDateTime;
      class procedure CycleLogFiles;
      class constructor Create;
      class destructor Destroy;
      class function BuildLogFilename(Index : integer = -1) : string;
    public
      /// <summary> If True, any thread will log into own error.log file. Filenameschema is Error_%Thread_ID%.log.
      /// Default: False</summary>
      class var ThreadLogging : boolean;
      /// <summary> Path for error.log. Filename is Error.log or Error_%Thread_ID%.log</summary>
      class var LogFilePath : string;
      /// <summary> Opens the console window. </summary>
      class procedure OpenConsole; static;
      /// <summary> Logs a message to the console. </summary>
      class procedure Console(LogMessage : string; NewLine : boolean = True); overload; static;
      /// <summary> Logs a formatted message to the console. </summary>
      class procedure Console(LogMessage : string; Parameters : array of const; NewLine : boolean = True); overload; static;
      /// <summary> Clear the console window.</summary>
      class procedure ClearConsole; static;
      /// <summary> Clear the last line in the console window.</summary>
      class procedure ClearLineConsole; static;
      /// <summary> Logs the message to the error.log file. </summary>
      class procedure Log(LogMessage : string); overload; static;
      /// <summary> Logs the formatted message to the error.log file. </summary>
      class procedure Log(LogMessage : string; Parameters : array of const); overload; static;

      /// <summary> Handles the message with different methods depending on the error level. </summary>
      class procedure Write(Level : EnumErrorLevel; LogMessage : string; ExceptionType : CException = nil); overload; static;
      /// <summary> Handles the formatted message with different methods depending on the error level. </summary>
      class procedure Write(Level : EnumErrorLevel; LogMessage : string; Parameters : array of const; ExceptionType : CException = nil); overload; static;

      /// <summary> Checks the error code and log the error and its errormsg, if the code is an error. </summary>
      class procedure CheckDX9Error(ErrorCode : HRESULT; ErrorMsg : string);
      /// <summary> This will raise an exception with the specified type and msg, except it should fail silently,
      /// then the error is printed to the log. </summary>
      class procedure ProcessError(FailSilently : boolean; ErrorMsg : string; ExceptionType : CException);
      /// <summary> Assert the condition. In release this will log the error and returns true when the assertion failed. </summary>
      class function AssertAndLog(Condition : boolean; ErrorMsg : string) : boolean; overload;
      class function AssertAndLog(Condition : boolean; ErrorMsg : string; Parameters : array of const) : boolean; overload;
      /// <summary> Returns the content from log file if exists. If file not exists, return empty string.</summary>
      class function ReadLog : string;

      class procedure ProfilingStart;
      class procedure ProfilingEndStart(const Key : string);
      class procedure ProfilingEnd(const Key : string);
  end;

  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic])}

implementation

uses
  Engine.Helferlein.Windows;

{ HLog }

class function HLog.AssertAndLog(Condition : boolean; ErrorMsg : string) : boolean;
begin
  Result := not Condition;
  if Result then
  begin
    assert(False, ErrorMsg);
    HLog.Log(ErrorMsg);
  end;
end;

class function HLog.AssertAndLog(Condition : boolean; ErrorMsg : string; Parameters : array of const) : boolean;
begin
  Result := AssertAndLog(Condition, Format(ErrorMsg, Parameters));
end;

class function HLog.BuildLogFilename(Index : integer) : string;
var
  Filename : string;
begin
  if ThreadLogging then
      Filename := Format('Error_%d', [TThread.Current.ThreadID])
  else
      Filename := 'Error';
  Result := IncludeTrailingBackslash(LogFilePath) + Filename;
  if index > 0 then
      Result := Result + index.ToString;
  Result := Result + '.log';
end;

class procedure HLog.CheckDX9Error(ErrorCode : HRESULT; ErrorMsg : string);
const
  // constants for DirectX error conversion
  _FACDXGI          = $87A;
  _FACD3D           = $876;
  MAKE_D3DHRESULT_R = (1 shl 31) or (_FACD3D shl 16);
  MAKE_D3DSTATUS_R  = (0 shl 31) or (_FACD3D shl 16);

  // Direct3D Errors
  D3D_OK                           = S_OK;
  D3DERR_WRONGTEXTUREFORMAT        = HRESULT(MAKE_D3DHRESULT_R or 2072);
  D3DERR_UNSUPPORTEDCOLOROPERATION = HRESULT(MAKE_D3DHRESULT_R or 2073);
  D3DERR_UNSUPPORTEDCOLORARG       = HRESULT(MAKE_D3DHRESULT_R or 2074);
  D3DERR_UNSUPPORTEDALPHAOPERATION = HRESULT(MAKE_D3DHRESULT_R or 2075);
  D3DERR_UNSUPPORTEDALPHAARG       = HRESULT(MAKE_D3DHRESULT_R or 2076);
  D3DERR_TOOMANYOPERATIONS         = HRESULT(MAKE_D3DHRESULT_R or 2077);
  D3DERR_CONFLICTINGTEXTUREFILTER  = HRESULT(MAKE_D3DHRESULT_R or 2078);
  D3DERR_UNSUPPORTEDFACTORVALUE    = HRESULT(MAKE_D3DHRESULT_R or 2079);
  D3DERR_CONFLICTINGRENDERSTATE    = HRESULT(MAKE_D3DHRESULT_R or 2081);
  D3DERR_UNSUPPORTEDTEXTUREFILTER  = HRESULT(MAKE_D3DHRESULT_R or 2082);
  D3DERR_CONFLICTINGTEXTUREPALETTE = HRESULT(MAKE_D3DHRESULT_R or 2086);
  D3DERR_DRIVERINTERNALERROR       = HRESULT(MAKE_D3DHRESULT_R or 2087);
  D3DERR_NOTFOUND                  = HRESULT(MAKE_D3DHRESULT_R or 2150);
  D3DERR_MOREDATA                  = HRESULT(MAKE_D3DHRESULT_R or 2151);
  D3DERR_DEVICELOST                = HRESULT(MAKE_D3DHRESULT_R or 2152);
  D3DERR_DEVICENOTRESET            = HRESULT(MAKE_D3DHRESULT_R or 2153);
  D3DERR_NOTAVAILABLE              = HRESULT(MAKE_D3DHRESULT_R or 2154);
  D3DERR_OUTOFVIDEOMEMORY          = HRESULT(MAKE_D3DHRESULT_R or 380);
  D3DERR_INVALIDDEVICE             = HRESULT(MAKE_D3DHRESULT_R or 2155);
  D3DERR_INVALIDCALL               = HRESULT(MAKE_D3DHRESULT_R or 2156);
  D3DERR_DRIVERINVALIDCALL         = HRESULT(MAKE_D3DHRESULT_R or 2157);
  D3DERR_WASSTILLDRAWING           = HRESULT(MAKE_D3DHRESULT_R or 540);
  D3DOK_NOAUTOGEN                  = HRESULT(MAKE_D3DSTATUS_R or 2159);
var
  tmpstr : string;
begin
  if not(ErrorCode = D3D_OK) then
  begin
    case ErrorCode of
      D3DERR_WRONGTEXTUREFORMAT : tmpstr := 'D3DERR_WRONGTEXTUREFORMAT ';
      D3DERR_UNSUPPORTEDCOLOROPERATION : tmpstr := 'D3DERR_UNSUPPORTEDCOLOROPERATION ';
      D3DERR_UNSUPPORTEDCOLORARG : tmpstr := 'D3DERR_UNSUPPORTEDCOLORARG ';
      D3DERR_UNSUPPORTEDALPHAOPERATION : tmpstr := 'D3DERR_UNSUPPORTEDALPHAOPERATION ';
      D3DERR_UNSUPPORTEDALPHAARG : tmpstr := 'D3DERR_UNSUPPORTEDALPHAARG ';
      D3DERR_TOOMANYOPERATIONS : tmpstr := 'D3DERR_TOOMANYOPERATIONS ';
      D3DERR_CONFLICTINGTEXTUREFILTER : tmpstr := 'D3DERR_CONFLICTINGTEXTUREFILTER ';
      D3DERR_UNSUPPORTEDFACTORVALUE : tmpstr := 'D3DERR_UNSUPPORTEDFACTORVALUE ';
      D3DERR_CONFLICTINGRENDERSTATE : tmpstr := 'D3DERR_CONFLICTINGRENDERSTATE ';
      D3DERR_UNSUPPORTEDTEXTUREFILTER : tmpstr := 'D3DERR_UNSUPPORTEDTEXTUREFILTER ';
      D3DERR_CONFLICTINGTEXTUREPALETTE : tmpstr := 'D3DERR_CONFLICTINGTEXTUREPALETTE ';
      D3DERR_DRIVERINTERNALERROR : tmpstr := 'D3DERR_DRIVERINTERNALERROR ';
      D3DERR_NOTFOUND : tmpstr := 'D3DERR_NOTFOUND ';
      D3DERR_MOREDATA : tmpstr := 'D3DERR_MOREDATA ';
      D3DERR_DEVICELOST : tmpstr := 'D3DERR_DEVICELOST ';
      D3DERR_DEVICENOTRESET : tmpstr := 'D3DERR_DEVICENOTRESET ';
      D3DERR_NOTAVAILABLE : tmpstr := 'D3DERR_NOTAVAILABLE ';
      D3DERR_OUTOFVIDEOMEMORY : tmpstr := 'D3DERR_OUTOFVIDEOMEMORY ';
      D3DERR_INVALIDDEVICE : tmpstr := 'D3DERR_INVALIDDEVICE ';
      D3DERR_INVALIDCALL : tmpstr := 'D3DERR_INVALIDCALL ';
      D3DERR_DRIVERINVALIDCALL : tmpstr := 'D3DERR_DRIVERINVALIDCALL ';
      D3DERR_WASSTILLDRAWING : tmpstr := 'D3DERR_WASSTILLDRAWING ';
      D3DOK_NOAUTOGEN : tmpstr := 'D3DOK_NOAUTOGEN ';
      E_OUTOFMEMORY : tmpstr := 'E_OUTOFMEMORY';
    end;
    HLog.Log(tmpstr + ' - ' + ErrorMsg);
  end;
end;

class procedure HLog.ClearConsole;
var
  stdout : THandle;
  csbi : TConsoleScreenBufferInfo;
  ConsoleSize : DWORD;
  NumWritten : DWORD;
  Origin : TCoord;
begin
  // logger is thread safe
  Semaphore.Acquire;

  if ConsoleOpened then
  begin
    // code from https://stackoverflow.com/questions/29794559/delphi-console-xe7-clearscreen
    stdout := GetStdHandle(STD_OUTPUT_HANDLE);
    Win32Check(stdout <> INVALID_HANDLE_VALUE);
    Win32Check(GetConsoleScreenBufferInfo(stdout, csbi));
    ConsoleSize := csbi.dwSize.X * csbi.dwSize.Y;
    Origin.X := 0;
    Origin.Y := 0;
    Win32Check(FillConsoleOutputCharacter(stdout, ' ', ConsoleSize, Origin,
      NumWritten));
    Win32Check(FillConsoleOutputAttribute(stdout, csbi.wAttributes, ConsoleSize, Origin,
      NumWritten));
    Win32Check(SetConsoleCursorPosition(stdout, Origin));
  end;

  Semaphore.Release;
end;

class procedure HLog.ClearLineConsole;
var
  stdout : THandle;
  csbi : TConsoleScreenBufferInfo;
  ConsoleLineSize : DWORD;
  NumWritten : DWORD;
  Origin : TCoord;
begin
  // logger is thread safe
  Semaphore.Acquire;

  if ConsoleOpened then
  begin
    // code from https://stackoverflow.com/questions/29794559/delphi-console-xe7-clearscreen
    stdout := GetStdHandle(STD_OUTPUT_HANDLE);
    Win32Check(stdout <> INVALID_HANDLE_VALUE);
    Win32Check(GetConsoleScreenBufferInfo(stdout, csbi));
    ConsoleLineSize := csbi.dwSize.X;
    Origin.X := 0;
    Origin.Y := csbi.dwCursorPosition.Y;
    Win32Check(FillConsoleOutputCharacter(stdout, ' ', ConsoleLineSize, Origin, NumWritten));
    Win32Check(SetConsoleCursorPosition(stdout, Origin));
  end;

  Semaphore.Release;
end;

class procedure HLog.OpenConsole;
begin
  // logger is thread safe
  Semaphore.Acquire;

  if not HLog.ConsoleOpened then
  begin
    AllocConsole;
    HLog.ConsoleOpened := True;
  end;

  Semaphore.Release;
end;

class procedure HLog.Console(LogMessage : string; Parameters : array of const; NewLine : boolean);
begin
  HLog.Console(Format(LogMessage, Parameters), NewLine);
end;

class procedure HLog.Console(LogMessage : string; NewLine : boolean);
begin
  // logger is thread safe
  Semaphore.Acquire;

  if not HLog.ConsoleOpened then
  begin
    AllocConsole;
    HLog.ConsoleOpened := True;
  end;

  if NewLine then
      System.Writeln(LogMessage)
  else
      System.Write(LogMessage);

  Semaphore.Release;
end;

class constructor HLog.Create;
begin
  HLog.Semaphore := TMutex.Create();
  HLog.FirstLog := True;
  HLog.StartDate := Date();
  HLog.StartTime := Time();
  HLog.LogFilePath := ExtractFilePath(Application.ExeName);
  CycleLogFiles;
end;

class procedure HLog.CycleLogFiles;
var
  i : integer;
begin
  for i := LOG_FILE_ROTATION - 1 downto 0 do
  begin
    if i = LOG_FILE_ROTATION - 1 then
        DeleteFile(BuildLogFilename(i))
    else
        RenameFile(BuildLogFilename(i), BuildLogFilename(i + 1))
  end;
end;

class destructor HLog.Destroy;
begin
  HLog.Semaphore.Free;
end;

class procedure HLog.Log(LogMessage : string; Parameters : array of const);
begin
  HLog.Log(Format(LogMessage, Parameters));
end;

class procedure HLog.Log(LogMessage : string);
var
  LogFile : TStreamWriter;
begin
  // logger is thread safe
  Semaphore.Acquire;

  try
    LogFile := TStreamWriter.Create(BuildLogFilename(), True, TEncoding.UTF8);

    // if this is the first log since the application started, make a space to differ between sessions
    if FirstLog then
    begin
      FirstLog := False;
      LogFile.WriteLine('---------- Log from ' + DateToStr(StartDate) + ' ' + TimeToStr(StartTime) + ' ---------------------------------------------------------------------------------------');
    end;
    // write the log string
    LogFile.WriteLine('[' + DateToStr(Date) + ' ' + TimeToStr(Time) + '] ' + LogMessage);
    // close error file
    LogFile.Close;
    LogFile.Free;
  except
    // Do nothing, only ensure that log data can never break application
  end;

  Semaphore.Release;
end;

class procedure HLog.ProcessError(FailSilently : boolean; ErrorMsg : string; ExceptionType : CException);
begin
  if FailSilently then HLog.Log(ErrorMsg)
  else ExceptionType.Create(ErrorMsg);
end;

class procedure HLog.ProfilingEnd(const Key : string);
var
  CurrentTimestamp : int64;
begin
  CurrentTimestamp := TimeManager.GetTimeStamp;
  Console(Key + ' - ' + (CurrentTimestamp - ProfilingTimeStamp).ToString + 'ms');
end;

class procedure HLog.ProfilingEndStart(const Key : string);
begin
  ProfilingEnd(Key);
  ProfilingStart;
end;

class procedure HLog.ProfilingStart;
begin
  ProfilingTimeStamp := TimeManager.GetTimeStamp;
end;

class function HLog.ReadLog : string;
var
  Stream : TFileStream;
  TextReader : TStreamReader;
begin
  Result := '';
  if FileExists(BuildLogFilename) then
  begin
    Stream := nil;
    TextReader := nil;
    try
      try
        Stream := TFileStream.Create(BuildLogFilename, fmOpenRead or fmShareDenyNone);
        TextReader := TStreamReader.Create(Stream);
        Result := TextReader.ReadToEnd;
      finally
        TextReader.Free;
        Stream.Free;
      end;
    except
      Result := '';
    end;
  end;
end;

class procedure HLog.Write(Level : EnumErrorLevel; LogMessage : string; ExceptionType : CException);
begin
  if ExceptionType = nil then ExceptionType := Exception;
  {$IFDEF DEBUG}
  HLog.Log(LogMessage);
  case Level of
    elDebug, elInfo :;
    elWarning : HLog.Console(LogMessage);
    elError :
      begin
        HLog.Log(ExceptionType.ClassName + ': ' + LogMessage);
        raise ExceptionType.Create(LogMessage)at ReturnAddress;
      end;
  end;
  {$ELSE}
  case Level of
    elDebug :;
    elInfo, elWarning : HLog.Log(LogMessage);
    elError :
      begin
        HLog.Log(ExceptionType.ClassName + ': ' + LogMessage);
        raise ExceptionType.Create(LogMessage);
      end;
  end;
  {$ENDIF}
end;

class procedure HLog.Write(Level : EnumErrorLevel; LogMessage : string; Parameters : array of const; ExceptionType : CException);
begin
  HLog.Write(Level, Format(LogMessage, Parameters), ExceptionType);
end;

end.

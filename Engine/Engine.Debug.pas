unit Engine.Debug;

interface

uses
  // ----------- Delphi -------------
  // --------- ThirdParty -----------
  // FastMM4,
  Winapi.psAPI,
  Winapi.Windows,
  // --------- Engine ------------
  Engine.Helferlein.Windows;

type

  HMemoryDebug = class
    class function GetMemoryUsed : UInt64;
    class function GetMemoryUsedFormated : string;
    {$IFDEF FASTMM}
    class function GetMemoryUsedFastMM : UInt64;
    {$ENDIF}
    class function GetMemoryUsedWinApi : UInt64;
  end;

implementation

{ HMemoryDebug }

class function HMemoryDebug.GetMemoryUsedFormated : string;
begin
  result := HString.IntToStrBandwidth(HMemoryDebug.GetMemoryUsed, 1, 'MB');
end;

class function HMemoryDebug.GetMemoryUsed : UInt64;
begin
  {$IFDEF FASTMM}
  result := HMemoryDebug.GetMemoryUsedFastMM;
  {$ELSE}
  result := HMemoryDebug.GetMemoryUsedWinApi;
  {$ENDIF}
end;

{$IFDEF FASTMM}


class function HMemoryDebug.GetMemoryUsedFastMM : UInt64;
var
  st : TMemoryManagerState;
  sb : TSmallBlockTypeState;
begin
  GetMemoryManagerState(st);
  result := st.TotalAllocatedMediumBlockSize + st.TotalAllocatedLargeBlockSize;
  for sb in st.SmallBlockTypeStates do
  begin
    result := result + sb.UseableBlockSize * sb.AllocatedBlockCount;
  end;
end;
{$ENDIF}


class function HMemoryDebug.GetMemoryUsedWinApi : UInt64;
var
  MemCounters : TProcessMemoryCounters;
begin
  ZeroMemory(@MemCounters, SizeOf(TProcessMemoryCounters));
  MemCounters.cb := SizeOf(TProcessMemoryCounters);
  if GetProcessMemoryInfo(GetCurrentProcess(), @MemCounters, SizeOf(TProcessMemoryCounters)) then
      result := MemCounters.WorkingSetSize
  else
      result := 0;
end;

end.

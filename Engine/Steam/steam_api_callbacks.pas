unit steam_api_callbacks;

interface

uses
  // ------- Delphi ---------
  System.SysUtils,
  // ------- Steam ----------
  steam_api;

type

  CCallbackInterface = record
    vtable : Pointer;
    m_nCallbackFlags : byte;
    m_iCallback : integer;
    delphiInstance : TObject;
  end;

  PCCallbackInterface = ^CCallbackInterface;

  ESteamCallback = class(Exception);

  TSteamCallbackBase = class
    private type
      TProcSimple = procedure(Data : Pointer) of object;
    private
      FSteamInterface : CCallbackInterface;
      FProcedure : TProcSimple;
      FParameterDataSize : integer;
    public
      constructor Create;
  end;

  TSteamCallback<T> = class(TSteamCallbackBase)
    public type
      ProcCallback = procedure(const Data : T) of object;
    private
      FIdentifier : integer;
    public
      constructor Create(CallbackIdentifier : integer; CallbackMethod : ProcCallback); reintroduce;
      destructor Destroy; override;
  end;

  // Internal functions used by the utility CCallback objects to receive callbacks
procedure SteamAPI_RegisterCallback(pCallback : PCCallbackInterface; iCallback : integer); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_UnregisterCallback(pCallback : PCCallbackInterface); cdecl; external STEAM_API_LIBFILENAME delayed;

implementation


// emulation of C++ class on delphiside to implement steam callbacks (which are base on C++ classes)

type
  TSteamCallbackVTable = record
    Run : Pointer;
    Run_2 : Pointer;
    GetCallbackSizeBytes : Pointer;
    class constructor InitVTable;
  end;

var
  SteamCallbackVTable : TSteamCallbackVTable;

procedure VirtualSteamCallback_Run(pSelf : PCCallbackInterface; pvParam : Pointer); pascal;
begin
end;

procedure VirtualSteamCallback_Run_2(pvParam : Pointer); pascal;
var
  self : PCCallbackInterface;
begin
  asm
    mov self, ECX;
  end;
  TSteamCallbackBase(self.delphiInstance).FProcedure(pvParam);
end;

function VirtualSteamCallback_GetCallbackSizeBytes : integer; pascal;
var
  self : PCCallbackInterface;
begin
  asm
    mov self, ECX;
  end;
  result := TSteamCallbackBase(self.delphiInstance).FParameterDataSize;
end;

{ TSteamCallbackVTable }

class constructor TSteamCallbackVTable.InitVTable;
begin
  SteamCallbackVTable.Run := @VirtualSteamCallback_Run;
  SteamCallbackVTable.Run_2 := @VirtualSteamCallback_Run_2;
  SteamCallbackVTable.GetCallbackSizeBytes := @VirtualSteamCallback_GetCallbackSizeBytes;
end;

{ TSteamCallback }

constructor TSteamCallback<T>.Create(CallbackIdentifier : integer; CallbackMethod : ProcCallback);
begin
  FIdentifier := CallbackIdentifier;
  if @CallbackMethod = nil then
      raise ESteamCallback.Create('No valid callback procedure');
  FProcedure := TProcSimple(CallbackMethod);
  FParameterDataSize := SizeOf(T);

  inherited Create;

  SteamAPI_RegisterCallback(@FSteamInterface, CallbackIdentifier);
end;

destructor TSteamCallback<T>.Destroy;
begin
  SteamAPI_UnregisterCallback(@FSteamInterface);
end;

{ TSteamCallbackBase }

constructor TSteamCallbackBase.Create;
begin
  FSteamInterface.vtable := @SteamCallbackVTable;
  FSteamInterface.m_nCallbackFlags := 0;
  FSteamInterface.m_iCallback := 0;
  FSteamInterface.delphiInstance := self;
end;

end.

unit FMOD.Studio.Classes;

interface

uses
  // --- Delphi ----
  System.Rtti,
  System.SysUtils,
  System.Generics.Collections,
  // --- FMOD ---
  FMOD.Common,
  FMOD,
  FMOD.Studio,
  FMOD.Studio.Common,
  // --- Engine ---
  Engine.Log;

type

  FMODError = class(Exception);

  TFMODEventInstance = class
    private
      FInstance : PFMOD_STUDIO_EVENTINSTANCE;
      constructor Create(EventInstance : PFMOD_STUDIO_EVENTINSTANCE);
      function Get3DAttributes : FMOD_3D_ATTRIBUTES;
      procedure Set3DAttributes(const Value : FMOD_3D_ATTRIBUTES);
      function GetTimelinePosition : Integer;
      procedure SetTimelinePosition(const Value : Integer);
      function GetParameterValue(name : string) : single;
      procedure SetParameterValue(name : string; const Value : single);
      function GetParameterValueByIndex(index : Integer) : single;
      procedure SetParameterValueByIndex(index : Integer; const Value : single);
      function GetPitch : single;
      function GetVolume : single;
      procedure SetPitch(const Value : single);
      procedure SetVolume(const Value : single);
      function GetPlaybackState : FMOD_STUDIO_PLAYBACK_STATE;
    public
      property Volume : single read GetVolume write SetVolume;
      property Pitch : single read GetPitch write SetPitch;
      property Attributes3D : FMOD_3D_ATTRIBUTES read Get3DAttributes write Set3DAttributes;
      property TimelinePosition : Integer read GetTimelinePosition write SetTimelinePosition;
      property ParameterValue[name : string] : single read GetParameterValue write SetParameterValue;
      property ParameterValueByIndex[index : Integer] : single read GetParameterValueByIndex write SetParameterValueByIndex;
      property PlaybackState : FMOD_STUDIO_PLAYBACK_STATE read GetPlaybackState;
      function IsValid : FMOD_BOOL;
      procedure Start;
      procedure Stop(Mode : FMOD_STUDIO_STOP_MODE);
      destructor Destroy; override;
  end;

  TFMODEventDescription = class
    private
      FEventDescription : PFMOD_STUDIO_EVENTDESCRIPTION;
      constructor Create(EventDescription : PFMOD_STUDIO_EVENTDESCRIPTION);
    public
      function IsValid : FMOD_BOOL;
      function GetID : FMOD_GUID;
      function GetPath : string;
      function CreateIntance : TFMODEventInstance;
      destructor Destroy; override;
  end;

  TFMODStudioBus = class
    private
      FBus : PFMOD_STUDIO_BUS;
      constructor Create(Bus : PFMOD_STUDIO_BUS);
      function GetVolume : single;
      procedure SetVolume(const Value : single);
      function GetMute : boolean;
      procedure SetMute(const Value : boolean);
    public
      property Volume : single read GetVolume write SetVolume;
      /// <summary> Property muted, write is same as methods mute and unmute.</summary>
      property Muted : boolean read GetMute write SetMute;
      function IsValid : FMOD_BOOL;
      function GetID : FMOD_GUID;
      function GetPath : string;
      /// <summary> Mute the bus.</summary>
      procedure Mute;
      /// <summary> Unmute the bus.</summary>
      procedure Unmute;
      procedure StopAllEvents(Mode : FMOD_STUDIO_STOP_MODE);
      destructor Destroy; override;
  end;

  TFMODStudioSystem = class
    private
      FSystem : PFMOD_STUDIO_SYSTEM;
      FCrashed : boolean;
      function GetAdvancedSettings : FMOD_STUDIO_ADVANCEDSETTINGS;
      procedure SetAdvancedSettings(const Value : FMOD_STUDIO_ADVANCEDSETTINGS);
      function GetListenerAttributes(index : Integer) : FMOD_3D_ATTRIBUTES;
      function GetListenerWeight(index : Integer) : single;
      function GetNumListeners : Integer;
      procedure SetListenerAttributes(index : Integer; const Value : FMOD_3D_ATTRIBUTES);
      procedure SetListenerWeight(index : Integer; const Value : single);
      procedure SetNumListeners(const Value : Integer);
      procedure InternalFMODCheckResult(Result : FMOD_RESULT; CriticalOperation : boolean; const AdditionalInfo : string = '');
    public
      property Crashed : boolean read FCrashed;
      property AdvancedSettings : FMOD_STUDIO_ADVANCEDSETTINGS read GetAdvancedSettings write SetAdvancedSettings;
      property NumListeners : Integer read GetNumListeners write SetNumListeners;
      property ListenerAttributes[index : Integer] : FMOD_3D_ATTRIBUTES read GetListenerAttributes write SetListenerAttributes;
      property ListenerWeight[index : Integer] : single read GetListenerWeight write SetListenerWeight;
      function IsValid : FMOD_BOOL;
      procedure LoadBankFile(const Filename : string; Flags : FMOD_STUDIO_LOAD_BANK_FLAGS);
      function GetBankCount : Integer;
      procedure Update;
      procedure UnloadAll;
      function GetEvent(const PathOrID : string) : TFMODEventDescription;
      function GetEventInstance(const PathOrID : string) : TFMODEventInstance;
      function GetBus(const PathOrID : string) : TFMODStudioBus;
      // Initialize
      constructor Create(MaxChannels : Integer; StudioFlags : FMOD_STUDIO_INITFLAGS; Flags : FMOD_INITFLAGS; ExtraDriverData : Pointer);
      destructor Destroy; override;
  end;

implementation

/// <summary> Unmute the bus.</summary>
function FMODCheckResult(FMODResult : FMOD_RESULT; const AdditionalInfo : string = '') : boolean;
begin
  if FMODResult <> FMOD_OK then
  begin
    HLog.Write(elWarning, 'FMod error: "%s". AdditionalInfo: %s', [TValue.From<FMOD_RESULT>(FMODResult).ToString, AdditionalInfo], FMODError);
    Result := False;
  end
  else
      Result := True;
end;

{ TFMODStudioSystem }

constructor TFMODStudioSystem.Create(MaxChannels : Integer; StudioFlags : FMOD_STUDIO_INITFLAGS; Flags : FMOD_INITFLAGS; ExtraDriverData : Pointer);
var
  Result : FMOD_RESULT;
  LowLevelSystem : PFMOD_SYSTEM;
begin
  InitFmodStudioAPI();
  InitFMODAPI();
  InternalFMODCheckResult(FMOD_Studio_System_Create(FSystem, FMOD_VERSION), True, 'FMOD_Studio_System_Create');
  Result := FMOD_Studio_System_Initialize(FSystem, MaxChannels, StudioFlags, Flags, ExtraDriverData);
  if (Result in [FMOD_ERR_OUTPUT_INIT, FMOD_ERR_INVALID_HANDLE]) then
  begin
    // ignore
    InternalFMODCheckResult(FMOD_Studio_System_Release(FSystem), True, 'FMOD_Studio_System_Release');

    InternalFMODCheckResult(FMOD_Studio_System_Create(FSystem, FMOD_VERSION), True, 'FMOD_Studio_System_Create');
    InternalFMODCheckResult(FMOD_Studio_System_GetLowLevelSystem(FSystem, LowLevelSystem), True, 'FMOD_Studio_System_GetLowLevelSystem');
    InternalFMODCheckResult(FMOD_System_SetOutput(LowLevelSystem, FMOD_OUTPUTTYPE_NOSOUND), True, 'FMOD_System_SetOutput');
    InternalFMODCheckResult(FMOD_Studio_System_Initialize(FSystem, MaxChannels, FMOD_STUDIO_INIT_NORMAL, Flags, ExtraDriverData), True, 'FMOD_Studio_System_Initialize');
  end
  else
      InternalFMODCheckResult(Result, True, 'FMOD_Studio_System_Initialize');
end;

destructor TFMODStudioSystem.Destroy;
begin
  InternalFMODCheckResult(FMOD_Studio_System_Release(FSystem), True, 'FMOD_Studio_System_Release');
  ReleaseFMODStudioAPI();
  ReleaseFMODAPI();
  inherited;
end;

procedure TFMODStudioSystem.InternalFMODCheckResult(Result : FMOD_RESULT; CriticalOperation : boolean; const AdditionalInfo : string);
begin
  // any critical operation failed -> mark FMOD Studio as failed
  if not FMODCheckResult(Result, AdditionalInfo) and CriticalOperation then
      FCrashed := True;
end;

function TFMODStudioSystem.GetAdvancedSettings : FMOD_STUDIO_ADVANCEDSETTINGS;
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_GetAdvancedSettings(FSystem, Result), False)
  else
      FillChar(Result, SizeOf(FMOD_STUDIO_ADVANCEDSETTINGS), 0);
end;

function TFMODStudioSystem.GetBus(const PathOrID : string) : TFMODStudioBus;
var
  Bus : PFMOD_STUDIO_BUS;
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_GetBus(FSystem, AnsiString(PathOrID), Bus), True);
  if Crashed then Bus := nil;
  Result := TFMODStudioBus.Create(Bus);
end;

function TFMODStudioSystem.GetBankCount : Integer;
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_GetBankCount(FSystem, Result), False)
  else
      Result := 0;
end;

function TFMODStudioSystem.GetEvent(const PathOrID : string) : TFMODEventDescription;
var
  Event : PFMOD_STUDIO_EVENTDESCRIPTION;
  CallResult : FMOD_RESULT;
begin
  Result := nil;
  if not Crashed then
  begin
    CallResult := FMOD_Studio_System_GetEvent(FSystem, AnsiString(PathOrID), Event);
    case CallResult of
      FMOD_OK : Result := TFMODEventDescription.Create(Event);
      FMOD_ERR_EVENT_NOTFOUND : Result := nil;
    else
      InternalFMODCheckResult(CallResult, False);
    end;
  end
  else
      Result := TFMODEventDescription.Create(nil);
end;

function TFMODStudioSystem.GetEventInstance(const PathOrID : string) : TFMODEventInstance;
var
  EventDescription : TFMODEventDescription;
begin
  EventDescription := GetEvent(PathOrID);
  if assigned(EventDescription) then
  begin
    Result := EventDescription.CreateIntance;
    EventDescription.Free;
  end
  else
      Result := nil;
end;

function TFMODStudioSystem.GetListenerAttributes(index : Integer) : FMOD_3D_ATTRIBUTES;
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_GetListenerAttributes(FSystem, index, Result), False)
  else
      FillChar(Result, SizeOf(FMOD_3D_ATTRIBUTES), 0);
end;

function TFMODStudioSystem.GetListenerWeight(index : Integer) : single;
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_GetListenerWeight(FSystem, index, Result), False)
  else
      Result := 0;
end;

function TFMODStudioSystem.GetNumListeners : Integer;
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_GetNumListeners(FSystem, Result), False)
  else
      Result := 0;
end;

function TFMODStudioSystem.IsValid : FMOD_BOOL;
begin
  if not Crashed then
      Result := FMOD_Studio_System_IsValid(FSystem)
  else
      Result := FMOD_FALSE;
end;

procedure TFMODStudioSystem.LoadBankFile(const Filename : string; Flags : FMOD_STUDIO_LOAD_BANK_FLAGS);
var
  Bank : PFMOD_STUDIO_BANK;
  UTF8Filename : AnsiString;
begin
  if not Crashed then
  begin
    Bank := nil;
    UTF8Filename := UTF8Encode(Filename);
    InternalFMODCheckResult(FMOD_Studio_System_LoadBankFile(FSystem, UTF8Filename, Flags, Bank), True);
  end;
end;

procedure TFMODStudioSystem.SetAdvancedSettings(const Value : FMOD_STUDIO_ADVANCEDSETTINGS);
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_SetAdvancedSettings(FSystem, Value), False);
end;

procedure TFMODStudioSystem.SetListenerAttributes(index : Integer; const Value : FMOD_3D_ATTRIBUTES);
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_SetListenerAttributes(FSystem, index, Value), False);
end;

procedure TFMODStudioSystem.SetListenerWeight(index : Integer; const Value : single);
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_SetListenerWeight(FSystem, index, Value), False);
end;

procedure TFMODStudioSystem.SetNumListeners(const Value : Integer);
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_SetNumListeners(FSystem, Value), False);
end;

procedure TFMODStudioSystem.UnloadAll;
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_UnloadAll(FSystem), False);
end;

procedure TFMODStudioSystem.Update;
begin
  if not Crashed then
      InternalFMODCheckResult(FMOD_Studio_System_Update(FSystem), False);
end;

{ TFMODEventDescription }

constructor TFMODEventDescription.Create(EventDescription : PFMOD_STUDIO_EVENTDESCRIPTION);
begin
  FEventDescription := EventDescription;
end;

function TFMODEventDescription.CreateIntance : TFMODEventInstance;
var
  EventInstance : PFMOD_STUDIO_EVENTINSTANCE;
begin
  if FEventDescription <> nil then
      FMOD_Studio_EventDescription_CreateInstance(FEventDescription, EventInstance)
  else
      EventInstance := nil;
  Result := TFMODEventInstance.Create(EventInstance);
end;

destructor TFMODEventDescription.Destroy;
begin
  inherited;
end;

function TFMODEventDescription.GetID : FMOD_GUID;
begin
  if FEventDescription <> nil then
      FMODCheckResult(FMOD_Studio_EventDescription_GetID(FEventDescription, Result))
  else
      FillChar(Result, SizeOf(FMOD_GUID), 0);
end;

function TFMODEventDescription.GetPath : string;
var
  RawPath : AnsiString;
  Count : Integer;
begin
  if FEventDescription <> nil then
  begin
    setlength(RawPath, 512);
    FMODCheckResult(FMOD_Studio_EventDescription_GetPath(FEventDescription, PAnsiChar(RawPath), Length(RawPath), Count));
    // ignore last char, because getpath will also output the terminating null character
    setlength(RawPath, Count - 1);
  end
  else Result := '';
end;

function TFMODEventDescription.IsValid : FMOD_BOOL;
begin
  if FEventDescription <> nil then
      Result := FMOD_Studio_EventDescription_IsValid(FEventDescription)
  else
      Result := FMOD_FALSE;
end;

{ TFMODEventInstance }

constructor TFMODEventInstance.Create(EventInstance : PFMOD_STUDIO_EVENTINSTANCE);
begin
  FInstance := EventInstance;
end;

destructor TFMODEventInstance.Destroy;
begin
  if (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_Release(FInstance));
  inherited;
end;

function TFMODEventInstance.Get3DAttributes : FMOD_3D_ATTRIBUTES;
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_Get3DAttributes(FInstance, Result))
  else
      Result := default (FMOD_3D_ATTRIBUTES);
end;

function TFMODEventInstance.GetParameterValue(name : string) : single;
var
  dummy : single;
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_GetParameterValue(FInstance, AnsiString(name), Result, dummy))
  else
      Result := 0;
end;

function TFMODEventInstance.GetParameterValueByIndex(index : Integer) : single;
var
  dummy : single;
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_GetParameterValueByIndex(FInstance, index, Result, dummy))
  else
      Result := 0;
end;

function TFMODEventInstance.GetPitch : single;
var
  dummy : single;
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_GetPitch(FInstance, Result, dummy))
  else
      Result := 0;
end;

function TFMODEventInstance.GetPlaybackState : FMOD_STUDIO_PLAYBACK_STATE;
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_GetPlaybackState(FInstance, Result))
  else
      Result := FMOD_STUDIO_PLAYBACK_STOPPED;
end;

function TFMODEventInstance.GetTimelinePosition : Integer;
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_GetTimelinePosition(FInstance, Result))
  else
      Result := 0;
end;

function TFMODEventInstance.GetVolume : single;
var
  dummy : single;
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_GetVolume(FInstance, Result, dummy))
  else
      Result := 0;
end;

function TFMODEventInstance.IsValid : FMOD_BOOL;
begin
  if (self <> nil) and (FInstance <> nil) then
      Result := FMOD_Studio_EventInstance_IsValid(FInstance)
  else
      Result := FMOD_FALSE;
end;

procedure TFMODEventInstance.Set3DAttributes(const Value : FMOD_3D_ATTRIBUTES);
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_Set3DAttributes(FInstance, Value));
end;

procedure TFMODEventInstance.SetParameterValue(name : string; const Value : single);
var
  CallResult : FMOD_RESULT;
begin
  if (self <> nil) and (FInstance <> nil) then
  begin
    CallResult := FMOD_Studio_EventInstance_SetParameterValue(FInstance, AnsiString(name), Value);
    // ignore event not found
    if not(CallResult in [FMOD_OK, FMOD_ERR_EVENT_NOTFOUND]) then
        FMODCheckResult(CallResult);
  end;
end;

procedure TFMODEventInstance.SetParameterValueByIndex(index : Integer; const Value : single);
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_SetParameterValueByIndex(FInstance, index, Value));
end;

procedure TFMODEventInstance.SetPitch(const Value : single);
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_SetPitch(FInstance, Value));
end;

procedure TFMODEventInstance.SetTimelinePosition(const Value : Integer);
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_SetTimelinePosition(FInstance, Value));
end;

procedure TFMODEventInstance.SetVolume(const Value : single);
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_SetVolume(FInstance, Value));
end;

procedure TFMODEventInstance.Start;
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_Start(FInstance));
end;

procedure TFMODEventInstance.Stop(Mode : FMOD_STUDIO_STOP_MODE);
begin
  if (self <> nil) and (FInstance <> nil) then
      FMODCheckResult(FMOD_Studio_EventInstance_Stop(FInstance, Mode));
end;

{ TFMODStudioBus }

constructor TFMODStudioBus.Create(Bus : PFMOD_STUDIO_BUS);
begin
  FBus := Bus;
end;

destructor TFMODStudioBus.Destroy;
begin
  inherited;
end;

function TFMODStudioBus.GetID : FMOD_GUID;
begin
  if FBus <> nil then
      FMODCheckResult(FMOD_Studio_Bus_GetID(FBus, Result))
  else
      FillChar(Result, SizeOf(FMOD_GUID), 0);
end;

function TFMODStudioBus.GetMute : boolean;
var
  FMODResult : FMOD_BOOL;
begin
  if FBus <> nil then
  begin
    FMODCheckResult(FMOD_Studio_Bus_GetMute(FBus, FMODResult));
    Result := FMODResult = FMOD_True
  end
  else Result := False;
end;

function TFMODStudioBus.GetPath : string;
var
  RawPath : AnsiString;
  Count : Integer;
begin
  if FBus <> nil then
  begin
    setlength(RawPath, 512);
    FMODCheckResult(FMOD_Studio_Bus_GetPath(FBus, PAnsiChar(RawPath), Length(RawPath), Count));
    // ignore last char, because getpath will also output the terminating null character
    setlength(RawPath, Count - 1);
  end
  else Result := '';
end;

function TFMODStudioBus.GetVolume : single;
var
  finalvolume : single;
begin
  if FBus <> nil then
      FMODCheckResult(FMOD_Studio_Bus_GetVolume(FBus, Result, finalvolume))
  else
      Result := 0;
end;

function TFMODStudioBus.IsValid : FMOD_BOOL;
begin
  if FBus <> nil then
      Result := FMOD_Studio_Bus_IsValid(FBus)
  else
      Result := FMOD_FALSE;
end;

procedure TFMODStudioBus.Mute;
begin
  Muted := True;
end;

procedure TFMODStudioBus.SetMute(const Value : boolean);
begin
  if FBus <> nil then
  begin
    if Value then
        FMODCheckResult(FMOD_Studio_Bus_SetMute(FBus, FMOD_True))
    else
        FMODCheckResult(FMOD_Studio_Bus_SetMute(FBus, FMOD_FALSE));
  end;
end;

procedure TFMODStudioBus.SetVolume(const Value : single);
begin
  if FBus <> nil then
      FMODCheckResult(FMOD_Studio_Bus_SetVolume(FBus, Value));
end;

procedure TFMODStudioBus.StopAllEvents(Mode : FMOD_STUDIO_STOP_MODE);
begin
  if FBus <> nil then
      FMODCheckResult(FMOD_Studio_Bus_StopAllEvents(FBus, Mode));
end;

procedure TFMODStudioBus.Unmute;
begin
  Muted := False;
end;

end.

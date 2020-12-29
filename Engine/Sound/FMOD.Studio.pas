unit FMOD.Studio;

(*
 Translated by Martin Lange 09.2017

 original:

 fmod_studio.h - FMOD Studio API
 Copyright (c), Firelight Technologies Pty, Ltd. 2017.

 This header defines the C API. If you are programming in C++ use fmod_studio.hpp.
*)

interface

uses
  System.SysUtils,
  Winapi.Windows,
  FMOD.Studio.Common,
  FMOD.Common;

const
  // Enables logging for fmod if FMOD_LOGGING is defined, use only for debugging!
  {$IFDEF FMOD_LOGGING}
  FMODSTUDIO32_LIBFILENAME = 'fmodstudioL.dll';
  {$ELSE}
  FMODSTUDIO32_LIBFILENAME = 'fmodstudio.dll';
  {$ENDIF}


type
  (*
   Global
  *)
  TFMOD_Studio_ParseID = function(idstring : PAnsiChar; out id : FMOD_GUID) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_Create = function(out System : PFMOD_STUDIO_SYSTEM; headerversion : UInt32) : FMOD_RESULT; stdcall;

var
  FMOD_Studio_ParseID : TFMOD_Studio_ParseID;
  FMOD_Studio_System_Create : TFMOD_Studio_System_Create;

type
  (*
   System
  *)
  TFMOD_Studio_System_IsValid = function(System : PFMOD_STUDIO_SYSTEM) : FMOD_BOOL; stdcall;
  TFMOD_Studio_System_SetAdvancedSettings = function(System : PFMOD_STUDIO_SYSTEM; const settings : FMOD_STUDIO_ADVANCEDSETTINGS) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetAdvancedSettings = function(System : PFMOD_STUDIO_SYSTEM; out settings : FMOD_STUDIO_ADVANCEDSETTINGS) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_Initialize = function(System : PFMOD_STUDIO_SYSTEM; maxchannels : Integer; studioflags : FMOD_STUDIO_INITFLAGS; flags : FMOD_INITFLAGS; extradriverdata : Pointer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_Release = function(System : PFMOD_STUDIO_SYSTEM) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_Update = function(System : PFMOD_STUDIO_SYSTEM) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetLowLevelSystem = function(System : PFMOD_STUDIO_SYSTEM; out lowlevelsystem : PFMOD_SYSTEM) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetEvent = function(System : PFMOD_STUDIO_SYSTEM; const pathOrID : AnsiString; out event : PFMOD_STUDIO_EVENTDESCRIPTION) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetBus = function(System : PFMOD_STUDIO_SYSTEM; const pathOrID : AnsiString; out bus : PFMOD_STUDIO_BUS) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetVCA = function(System : PFMOD_STUDIO_SYSTEM; const pathOrID : AnsiString; out vca : PFMOD_STUDIO_VCA) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetBank = function(System : PFMOD_STUDIO_SYSTEM; pathOrID : PAnsiChar; out bank : PFMOD_STUDIO_BANK) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetEventByID = function(System : PFMOD_STUDIO_SYSTEM; const id : FMOD_GUID; out event : PFMOD_STUDIO_EVENTDESCRIPTION) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetBusByID = function(System : PFMOD_STUDIO_SYSTEM; const id : FMOD_GUID; out bus : PFMOD_STUDIO_BUS) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetVCAByID = function(System : PFMOD_STUDIO_SYSTEM; const id : FMOD_GUID; out vca : PFMOD_STUDIO_VCA) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetBankByID = function(System : PFMOD_STUDIO_SYSTEM; const id : FMOD_GUID; out bank : PFMOD_STUDIO_BANK) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetSoundInfo = function(System : PFMOD_STUDIO_SYSTEM; key : PAnsiChar; out info : FMOD_STUDIO_SOUND_INFO) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_LookupID = function(System : PFMOD_STUDIO_SYSTEM; path : PAnsiChar; out id : FMOD_GUID) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_LookupPath = function(System : PFMOD_STUDIO_SYSTEM; const id : FMOD_GUID; path : PAnsiChar; size : Integer; out retrieved : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetNumListeners = function(System : PFMOD_STUDIO_SYSTEM; out numlisteners : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_SetNumListeners = function(System : PFMOD_STUDIO_SYSTEM; numlisteners : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetListenerAttributes = function(System : PFMOD_STUDIO_SYSTEM; index : Integer; out attributes : FMOD_3D_ATTRIBUTES) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_SetListenerAttributes = function(System : PFMOD_STUDIO_SYSTEM; index : Integer; const attributes : FMOD_3D_ATTRIBUTES) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetListenerWeight = function(System : PFMOD_STUDIO_SYSTEM; index : Integer; out weight : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_SetListenerWeight = function(System : PFMOD_STUDIO_SYSTEM; index : Integer; weight : single) : FMOD_RESULT; stdcall;

  TFMOD_Studio_System_LoadBankFile = function(System : PFMOD_STUDIO_SYSTEM; const filename : AnsiString; flags : FMOD_STUDIO_LOAD_BANK_FLAGS; out bank : PFMOD_STUDIO_BANK) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_LoadBankMemory = function(System : PFMOD_STUDIO_SYSTEM; buffer : PByte; length : Integer; mode : FMOD_STUDIO_LOAD_MEMORY_MODE; flags : FMOD_STUDIO_LOAD_BANK_FLAGS; out bank : PFMOD_STUDIO_BANK) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_LoadBankCustom = function(System : PFMOD_STUDIO_SYSTEM; info : PFMOD_STUDIO_BANK_INFO; flags : FMOD_STUDIO_LOAD_BANK_FLAGS; out bank : PFMOD_STUDIO_BANK) : FMOD_RESULT; stdcall;
  // FMOD_Studio_System_RegisterPlugin = function(System : PFMOD_STUDIO_SYSTEM; description : PFMOD_DSP_DESCRIPTION) : FMOD_RESULT; stdcall;
  // FMOD_Studio_System_UnregisterPlugin = function(System : PFMOD_STUDIO_SYSTEM; const char * name) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_UnloadAll = function(System : PFMOD_STUDIO_SYSTEM) : FMOD_RESULT; stdcall;
  { FMOD_Studio_System_FlushCommands = function(System : PFMOD_STUDIO_SYSTEM) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_FlushSampleLoading = function(System : PFMOD_STUDIO_SYSTEM) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_StartCommandCapture = function(System : PFMOD_STUDIO_SYSTEM; const char * filename; FMOD_STUDIO_COMMANDCAPTURE_FLAGS flags) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_StopCommandCapture = function(System : PFMOD_STUDIO_SYSTEM) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_LoadCommandReplay = function(System : PFMOD_STUDIO_SYSTEM; const char * filename; FMOD_STUDIO_COMMANDREPLAY_FLAGS flags; FMOD_STUDIO_COMMANDREPLAY * * replay) : FMOD_RESULT; stdcall; }
  TFMOD_Studio_System_GetBankCount = function(System : PFMOD_STUDIO_SYSTEM; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_System_GetBankList = function(System : PFMOD_STUDIO_SYSTEM; list_array : PPFMOD_STUDIO_BANK; capacity : Integer; out count : Integer) : FMOD_RESULT; stdcall;
  { FMOD_Studio_System_GetCPUUsage = function(System : PFMOD_STUDIO_SYSTEM; FMOD_STUDIO_CPU_USAGE * usage) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_GetBufferUsage = function(System : PFMOD_STUDIO_SYSTEM; FMOD_STUDIO_BUFFER_USAGE * usage) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_ResetBufferUsage = function(System : PFMOD_STUDIO_SYSTEM) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_SetCallback = function(System : PFMOD_STUDIO_SYSTEM; FMOD_STUDIO_SYSTEM_CALLBACK callback; FMOD_STUDIO_SYSTEM_CALLBACK_TYPE callbackmask) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_SetUserData = function(System : PFMOD_STUDIO_SYSTEM; void * userdata) : FMOD_RESULT; stdcall;
   FMOD_Studio_System_GetUserData = function(System : PFMOD_STUDIO_SYSTEM; void * * userdata) : FMOD_RESULT; stdcall; }

var
  FMOD_Studio_System_IsValid : TFMOD_Studio_System_IsValid;
  FMOD_Studio_System_SetAdvancedSettings : TFMOD_Studio_System_SetAdvancedSettings;
  FMOD_Studio_System_GetAdvancedSettings : TFMOD_Studio_System_GetAdvancedSettings;
  FMOD_Studio_System_Initialize : TFMOD_Studio_System_Initialize;
  FMOD_Studio_System_Release : TFMOD_Studio_System_Release;
  FMOD_Studio_System_Update : TFMOD_Studio_System_Update;
  FMOD_Studio_System_GetLowLevelSystem : TFMOD_Studio_System_GetLowLevelSystem;
  FMOD_Studio_System_GetEvent : TFMOD_Studio_System_GetEvent;
  FMOD_Studio_System_GetBus : TFMOD_Studio_System_GetBus;
  FMOD_Studio_System_GetVCA : TFMOD_Studio_System_GetVCA;
  FMOD_Studio_System_GetBank : TFMOD_Studio_System_GetBank;
  FMOD_Studio_System_GetEventByID : TFMOD_Studio_System_GetEventByID;
  FMOD_Studio_System_GetBusByID : TFMOD_Studio_System_GetBusByID;
  FMOD_Studio_System_GetVCAByID : TFMOD_Studio_System_GetVCAByID;
  FMOD_Studio_System_GetBankByID : TFMOD_Studio_System_GetBankByID;
  FMOD_Studio_System_GetSoundInfo : TFMOD_Studio_System_GetSoundInfo;
  FMOD_Studio_System_LookupID : TFMOD_Studio_System_LookupID;
  FMOD_Studio_System_LookupPath : TFMOD_Studio_System_LookupPath;
  FMOD_Studio_System_GetNumListeners : TFMOD_Studio_System_GetNumListeners;
  FMOD_Studio_System_SetNumListeners : TFMOD_Studio_System_SetNumListeners;
  FMOD_Studio_System_GetListenerAttributes : TFMOD_Studio_System_GetListenerAttributes;
  FMOD_Studio_System_SetListenerAttributes : TFMOD_Studio_System_SetListenerAttributes;
  FMOD_Studio_System_GetListenerWeight : TFMOD_Studio_System_GetListenerWeight;
  FMOD_Studio_System_SetListenerWeight : TFMOD_Studio_System_SetListenerWeight;
  FMOD_Studio_System_LoadBankFile : TFMOD_Studio_System_LoadBankFile;
  FMOD_Studio_System_LoadBankMemory : TFMOD_Studio_System_LoadBankMemory;
  FMOD_Studio_System_LoadBankCustom : TFMOD_Studio_System_LoadBankCustom;
  // --- missing
  FMOD_Studio_System_UnloadAll : TFMOD_Studio_System_UnloadAll;
  // --- missing
  FMOD_Studio_System_GetBankCount : TFMOD_Studio_System_GetBankCount;
  FMOD_Studio_System_GetBankList : TFMOD_Studio_System_GetBankList;
  // --- missing

type

  (*
   EventDescription
  *)

  TFMOD_Studio_EventDescription_IsValid = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION) : FMOD_BOOL; stdcall;
  TFMOD_Studio_EventDescription_GetID = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out id : FMOD_GUID) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetPath = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; path : PAnsiChar; size : Integer; out retrieved : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetParameterCount = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetParameterByIndex = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; index : Integer; out parameter : FMOD_STUDIO_PARAMETER_DESCRIPTION) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetParameter = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; name : PAnsiChar; out parameter : FMOD_STUDIO_PARAMETER_DESCRIPTION) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetUserPropertyCount = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetUserPropertyByIndex = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; index : Integer; out user_property : FMOD_STUDIO_USER_PROPERTY) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetUserProperty = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; name : PAnsiChar; out user_property : FMOD_STUDIO_USER_PROPERTY) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetLength = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out length : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetMinimumDistance = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out distance : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetMaximumDistance = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out distance : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetSoundSize = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out size : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_IsSnapshot = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out snapshot : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_IsOneshot = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out oneshot : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_IsStream = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out isStream : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_Is3D = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out is3D : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_HasCue = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out cue : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_CreateInstance = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out instance : PFMOD_STUDIO_EVENTINSTANCE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetInstanceCount = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetInstanceList = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; list_array : PPFMOD_STUDIO_EVENTINSTANCE; capacity : Integer; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_LoadSampleData = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_UnloadSampleData = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetSampleLoadingState = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out state : FMOD_STUDIO_LOADING_STATE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_ReleaseAllInstances = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_SetCallback = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; callback : FMOD_STUDIO_EVENT_CALLBACK; callbackmask : FMOD_STUDIO_EVENT_CALLBACK_TYPE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_GetUserData = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; out userdata : Pointer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventDescription_SetUserData = function(eventdescription : PFMOD_STUDIO_EVENTDESCRIPTION; userdata : Pointer) : FMOD_RESULT; stdcall;

var
  FMOD_Studio_EventDescription_IsValid : TFMOD_Studio_EventDescription_IsValid;
  FMOD_Studio_EventDescription_GetID : TFMOD_Studio_EventDescription_GetID;
  FMOD_Studio_EventDescription_GetPath : TFMOD_Studio_EventDescription_GetPath;
  FMOD_Studio_EventDescription_GetParameterCount : TFMOD_Studio_EventDescription_GetParameterCount;
  FMOD_Studio_EventDescription_GetParameterByIndex : TFMOD_Studio_EventDescription_GetParameterByIndex;
  FMOD_Studio_EventDescription_GetParameter : TFMOD_Studio_EventDescription_GetParameter;
  FMOD_Studio_EventDescription_GetUserPropertyCount : TFMOD_Studio_EventDescription_GetUserPropertyCount;
  FMOD_Studio_EventDescription_GetUserPropertyByIndex : TFMOD_Studio_EventDescription_GetUserPropertyByIndex;
  FMOD_Studio_EventDescription_GetUserProperty : TFMOD_Studio_EventDescription_GetUserProperty;
  FMOD_Studio_EventDescription_GetLength : TFMOD_Studio_EventDescription_GetLength;
  FMOD_Studio_EventDescription_GetMinimumDistance : TFMOD_Studio_EventDescription_GetMinimumDistance;
  FMOD_Studio_EventDescription_GetMaximumDistance : TFMOD_Studio_EventDescription_GetMaximumDistance;
  FMOD_Studio_EventDescription_GetSoundSize : TFMOD_Studio_EventDescription_GetSoundSize;
  FMOD_Studio_EventDescription_IsSnapshot : TFMOD_Studio_EventDescription_IsSnapshot;
  FMOD_Studio_EventDescription_IsOneshot : TFMOD_Studio_EventDescription_IsOneshot;
  FMOD_Studio_EventDescription_IsStream : TFMOD_Studio_EventDescription_IsStream;
  FMOD_Studio_EventDescription_Is3D : TFMOD_Studio_EventDescription_Is3D;
  FMOD_Studio_EventDescription_HasCue : TFMOD_Studio_EventDescription_HasCue;
  FMOD_Studio_EventDescription_CreateInstance : TFMOD_Studio_EventDescription_CreateInstance;
  FMOD_Studio_EventDescription_GetInstanceCount : TFMOD_Studio_EventDescription_GetInstanceCount;
  FMOD_Studio_EventDescription_GetInstanceList : TFMOD_Studio_EventDescription_GetInstanceList;
  FMOD_Studio_EventDescription_LoadSampleData : TFMOD_Studio_EventDescription_LoadSampleData;
  FMOD_Studio_EventDescription_UnloadSampleData : TFMOD_Studio_EventDescription_UnloadSampleData;
  FMOD_Studio_EventDescription_GetSampleLoadingState : TFMOD_Studio_EventDescription_GetSampleLoadingState;
  FMOD_Studio_EventDescription_ReleaseAllInstances : TFMOD_Studio_EventDescription_ReleaseAllInstances;
  FMOD_Studio_EventDescription_SetCallback : TFMOD_Studio_EventDescription_SetCallback;
  FMOD_Studio_EventDescription_GetUserData : TFMOD_Studio_EventDescription_GetUserData;
  FMOD_Studio_EventDescription_SetUserData : TFMOD_Studio_EventDescription_SetUserData;

type
  (*
   EventInstance
  *)
  TFMOD_Studio_EventInstance_IsValid = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE) : FMOD_BOOL; stdcall;
  TFMOD_Studio_EventInstance_GetDescription = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out description : PFMOD_STUDIO_EVENTDESCRIPTION) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetVolume = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out volume : single; out finalvolume : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetVolume = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; volume : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetPitch = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out pitch : single; out finalpitch : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetPitch = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; pitch : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_Get3DAttributes = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out attributes : FMOD_3D_ATTRIBUTES) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_Set3DAttributes = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; const attributes : FMOD_3D_ATTRIBUTES) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetListenerMask = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out mask : UInt32) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetListenerMask = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; mask : UInt32) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetProperty = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; index : FMOD_STUDIO_EVENT_PROPERTY; out value : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetProperty = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; index : FMOD_STUDIO_EVENT_PROPERTY; value : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetReverbLevel = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; index : Integer; out level : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetReverbLevel = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; index : Integer; level : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetPaused = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out paused : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetPaused = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; paused : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_Start = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_Stop = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; mode : FMOD_STUDIO_STOP_MODE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetTimelinePosition = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out position : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetTimelinePosition = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; position : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetPlaybackState = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out state : FMOD_STUDIO_PLAYBACK_STATE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetChannelGroup = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out group : PFMOD_CHANNELGROUP) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_Release = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_IsVirtual = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out virtualState : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetParameter = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; name : PAnsiChar; out parameter : PFMOD_STUDIO_PARAMETERINSTANCE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetParameterByIndex = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; index : Integer; out parameter : PFMOD_STUDIO_PARAMETERINSTANCE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetParameterCount = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetParameterValue = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; const name : AnsiString; out value : single; out finalvalue : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetParameterValue = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; const name : AnsiString; value : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetParameterValueByIndex = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; index : Integer; out value : single; out finalvalue : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetParameterValueByIndex = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; index : Integer; value : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_TriggerCue = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetCallback = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; callback : FMOD_STUDIO_EVENT_CALLBACK; callbackmask : FMOD_STUDIO_EVENT_CALLBACK_TYPE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_GetUserData = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; out userdata : Pointer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_EventInstance_SetUserData = function(eventinstance : PFMOD_STUDIO_EVENTINSTANCE; userdata : Pointer) : FMOD_RESULT; stdcall;

var

  FMOD_Studio_EventInstance_IsValid : TFMOD_Studio_EventInstance_IsValid;
  FMOD_Studio_EventInstance_GetDescription : TFMOD_Studio_EventInstance_GetDescription;
  FMOD_Studio_EventInstance_GetVolume : TFMOD_Studio_EventInstance_GetVolume;
  FMOD_Studio_EventInstance_SetVolume : TFMOD_Studio_EventInstance_SetVolume;
  FMOD_Studio_EventInstance_GetPitch : TFMOD_Studio_EventInstance_GetPitch;
  FMOD_Studio_EventInstance_SetPitch : TFMOD_Studio_EventInstance_SetPitch;
  FMOD_Studio_EventInstance_Get3DAttributes : TFMOD_Studio_EventInstance_Get3DAttributes;
  FMOD_Studio_EventInstance_Set3DAttributes : TFMOD_Studio_EventInstance_Set3DAttributes;
  FMOD_Studio_EventInstance_GetListenerMask : TFMOD_Studio_EventInstance_GetListenerMask;
  FMOD_Studio_EventInstance_SetListenerMask : TFMOD_Studio_EventInstance_SetListenerMask;
  FMOD_Studio_EventInstance_GetProperty : TFMOD_Studio_EventInstance_GetProperty;
  FMOD_Studio_EventInstance_SetProperty : TFMOD_Studio_EventInstance_SetProperty;
  FMOD_Studio_EventInstance_GetReverbLevel : TFMOD_Studio_EventInstance_GetReverbLevel;
  FMOD_Studio_EventInstance_SetReverbLevel : TFMOD_Studio_EventInstance_SetReverbLevel;
  FMOD_Studio_EventInstance_GetPaused : TFMOD_Studio_EventInstance_GetPaused;
  FMOD_Studio_EventInstance_SetPaused : TFMOD_Studio_EventInstance_SetPaused;
  FMOD_Studio_EventInstance_Start : TFMOD_Studio_EventInstance_Start;
  FMOD_Studio_EventInstance_Stop : TFMOD_Studio_EventInstance_Stop;
  FMOD_Studio_EventInstance_GetTimelinePosition : TFMOD_Studio_EventInstance_GetTimelinePosition;
  FMOD_Studio_EventInstance_SetTimelinePosition : TFMOD_Studio_EventInstance_SetTimelinePosition;
  FMOD_Studio_EventInstance_GetPlaybackState : TFMOD_Studio_EventInstance_GetPlaybackState;
  FMOD_Studio_EventInstance_GetChannelGroup : TFMOD_Studio_EventInstance_GetChannelGroup;
  FMOD_Studio_EventInstance_Release : TFMOD_Studio_EventInstance_Release;
  FMOD_Studio_EventInstance_IsVirtual : TFMOD_Studio_EventInstance_IsVirtual;
  FMOD_Studio_EventInstance_GetParameter : TFMOD_Studio_EventInstance_GetParameter;
  FMOD_Studio_EventInstance_GetParameterByIndex : TFMOD_Studio_EventInstance_GetParameterByIndex;
  FMOD_Studio_EventInstance_GetParameterCount : TFMOD_Studio_EventInstance_GetParameterCount;
  FMOD_Studio_EventInstance_GetParameterValue : TFMOD_Studio_EventInstance_GetParameterValue;
  FMOD_Studio_EventInstance_SetParameterValue : TFMOD_Studio_EventInstance_SetParameterValue;
  FMOD_Studio_EventInstance_GetParameterValueByIndex : TFMOD_Studio_EventInstance_GetParameterValueByIndex;
  FMOD_Studio_EventInstance_SetParameterValueByIndex : TFMOD_Studio_EventInstance_SetParameterValueByIndex;
  FMOD_Studio_EventInstance_TriggerCue : TFMOD_Studio_EventInstance_TriggerCue;
  FMOD_Studio_EventInstance_SetCallback : TFMOD_Studio_EventInstance_SetCallback;
  FMOD_Studio_EventInstance_GetUserData : TFMOD_Studio_EventInstance_GetUserData;
  FMOD_Studio_EventInstance_SetUserData : TFMOD_Studio_EventInstance_SetUserData;

type
  (*
   Bank
  *)
  TFMOD_Studio_Bank_IsValid = function(bank : PFMOD_STUDIO_BANK) : FMOD_BOOL; stdcall;
  TFMOD_Studio_Bank_GetID = function(bank : PFMOD_STUDIO_BANK; id : PFMOD_GUID) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetPath = function(bank : PFMOD_STUDIO_BANK; path : PAnsiChar; size : Integer; out retrieved : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_Unload = function(bank : PFMOD_STUDIO_BANK) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_LoadSampleData = function(bank : PFMOD_STUDIO_BANK) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_UnloadSampleData = function(bank : PFMOD_STUDIO_BANK) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetLoadingState = function(bank : PFMOD_STUDIO_BANK; out state : FMOD_STUDIO_LOADING_STATE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetSampleLoadingState = function(bank : PFMOD_STUDIO_BANK; out state : FMOD_STUDIO_LOADING_STATE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetStringCount = function(bank : PFMOD_STUDIO_BANK; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetStringInfo = function(bank : PFMOD_STUDIO_BANK; index : Integer; id : PFMOD_GUID; path : PAnsiChar; size : Integer; out retrieved : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetEventCount = function(bank : PFMOD_STUDIO_BANK; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetEventList = function(bank : PFMOD_STUDIO_BANK; list_array : PPFMOD_STUDIO_EVENTDESCRIPTION; capacity : Integer; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetBusCount = function(bank : PFMOD_STUDIO_BANK; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetBusList = function(bank : PFMOD_STUDIO_BANK; list_array : PPFMOD_STUDIO_BUS; capacity : Integer; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetVCACount = function(bank : PFMOD_STUDIO_BANK; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetVCAList = function(bank : PFMOD_STUDIO_BANK; list_array : PPFMOD_STUDIO_VCA; capacity : Integer; out count : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_GetUserData = function(bank : PFMOD_STUDIO_BANK; out userdata : Pointer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bank_SetUserData = function(bank : PFMOD_STUDIO_BANK; userdata : Pointer) : FMOD_RESULT; stdcall;

var
  FMOD_Studio_Bank_IsValid : TFMOD_Studio_Bank_IsValid;
  FMOD_Studio_Bank_GetID : TFMOD_Studio_Bank_GetID;
  FMOD_Studio_Bank_GetPath : TFMOD_Studio_Bank_GetPath;
  FMOD_Studio_Bank_Unload : TFMOD_Studio_Bank_Unload;
  FMOD_Studio_Bank_LoadSampleData : TFMOD_Studio_Bank_LoadSampleData;
  FMOD_Studio_Bank_UnloadSampleData : TFMOD_Studio_Bank_UnloadSampleData;
  FMOD_Studio_Bank_GetLoadingState : TFMOD_Studio_Bank_GetLoadingState;
  FMOD_Studio_Bank_GetSampleLoadingState : TFMOD_Studio_Bank_GetSampleLoadingState;
  FMOD_Studio_Bank_GetStringCount : TFMOD_Studio_Bank_GetStringCount;
  FMOD_Studio_Bank_GetStringInfo : TFMOD_Studio_Bank_GetStringInfo;
  FMOD_Studio_Bank_GetEventCount : TFMOD_Studio_Bank_GetEventCount;
  FMOD_Studio_Bank_GetEventList : TFMOD_Studio_Bank_GetEventList;
  FMOD_Studio_Bank_GetBusCount : TFMOD_Studio_Bank_GetBusCount;
  FMOD_Studio_Bank_GetBusList : TFMOD_Studio_Bank_GetBusList;
  FMOD_Studio_Bank_GetVCACount : TFMOD_Studio_Bank_GetVCACount;
  FMOD_Studio_Bank_GetVCAList : TFMOD_Studio_Bank_GetVCAList;
  FMOD_Studio_Bank_GetUserData : TFMOD_Studio_Bank_GetUserData;
  FMOD_Studio_Bank_SetUserData : TFMOD_Studio_Bank_SetUserData;

type
  (*
   Bus
  *)
  TFMOD_Studio_Bus_IsValid = function(bus : PFMOD_STUDIO_BUS) : FMOD_BOOL; stdcall;
  TFMOD_Studio_Bus_GetID = function(bus : PFMOD_STUDIO_BUS; out id : FMOD_GUID) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_GetPath = function(bus : PFMOD_STUDIO_BUS; path : PAnsiChar; size : Integer; out retrieved : Integer) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_GetVolume = function(bus : PFMOD_STUDIO_BUS; out volume : single; out finalvolume : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_SetVolume = function(bus : PFMOD_STUDIO_BUS; volume : single) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_GetPaused = function(bus : PFMOD_STUDIO_BUS; out paused : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_SetPaused = function(bus : PFMOD_STUDIO_BUS; paused : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_GetMute = function(bus : PFMOD_STUDIO_BUS; out mute : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_SetMute = function(bus : PFMOD_STUDIO_BUS; mute : FMOD_BOOL) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_StopAllEvents = function(bus : PFMOD_STUDIO_BUS; mode : FMOD_STUDIO_STOP_MODE) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_LockChannelGroup = function(bus : PFMOD_STUDIO_BUS) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_UnlockChannelGroup = function(bus : PFMOD_STUDIO_BUS) : FMOD_RESULT; stdcall;
  TFMOD_Studio_Bus_GetChannelGroup = function(bus : PFMOD_STUDIO_BUS; out group : PFMOD_CHANNELGROUP) : FMOD_RESULT; stdcall;

var
  FMOD_Studio_Bus_IsValid : TFMOD_Studio_Bus_IsValid;
  FMOD_Studio_Bus_GetID : TFMOD_Studio_Bus_GetID;
  FMOD_Studio_Bus_GetPath : TFMOD_Studio_Bus_GetPath;
  FMOD_Studio_Bus_GetVolume : TFMOD_Studio_Bus_GetVolume;
  FMOD_Studio_Bus_SetVolume : TFMOD_Studio_Bus_SetVolume;
  FMOD_Studio_Bus_GetPaused : TFMOD_Studio_Bus_GetPaused;
  FMOD_Studio_Bus_SetPaused : TFMOD_Studio_Bus_SetPaused;
  FMOD_Studio_Bus_GetMute : TFMOD_Studio_Bus_GetMute;
  FMOD_Studio_Bus_SetMute : TFMOD_Studio_Bus_SetMute;
  FMOD_Studio_Bus_StopAllEvents : TFMOD_Studio_Bus_StopAllEvents;
  FMOD_Studio_Bus_LockChannelGroup : TFMOD_Studio_Bus_LockChannelGroup;
  FMOD_Studio_Bus_UnlockChannelGroup : TFMOD_Studio_Bus_UnlockChannelGroup;
  FMOD_Studio_Bus_GetChannelGroup : TFMOD_Studio_Bus_GetChannelGroup;

procedure InitFMODStudioAPI(LibaryFileName : string = FMODSTUDIO32_LIBFILENAME);
procedure ReleaseFMODStudioAPI;

implementation

var
  FmodLibHandle : HMODULE = 0;

procedure ReadFMODGlobal;
begin
  FMOD_Studio_ParseID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_ParseID');
  FMOD_Studio_System_Create := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_Create');
end;

procedure ReadFMODSystem;
begin
  FMOD_Studio_System_IsValid := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_IsValid');
  FMOD_Studio_System_SetAdvancedSettings := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_SetAdvancedSettings');
  FMOD_Studio_System_GetAdvancedSettings := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetAdvancedSettings');
  FMOD_Studio_System_Initialize := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_Initialize');
  FMOD_Studio_System_Release := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_Release');
  FMOD_Studio_System_Update := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_Update');
  FMOD_Studio_System_GetLowLevelSystem := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetLowLevelSystem');
  FMOD_Studio_System_GetEvent := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetEvent');
  FMOD_Studio_System_GetBus := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetBus');
  FMOD_Studio_System_GetVCA := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetVCA');
  FMOD_Studio_System_GetBank := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetBank');
  FMOD_Studio_System_GetEventByID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetEventByID');
  FMOD_Studio_System_GetBusByID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetBusByID');
  FMOD_Studio_System_GetVCAByID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetVCAByID');
  FMOD_Studio_System_GetBankByID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetBankByID');
  FMOD_Studio_System_GetSoundInfo := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetSoundInfo');
  FMOD_Studio_System_LookupID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_LookupID');
  FMOD_Studio_System_LookupPath := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_LookupPath');
  FMOD_Studio_System_GetNumListeners := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetNumListeners');
  FMOD_Studio_System_SetNumListeners := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_SetNumListeners');
  FMOD_Studio_System_GetListenerAttributes := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetListenerAttributes');
  FMOD_Studio_System_SetListenerAttributes := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_SetListenerAttributes');
  FMOD_Studio_System_GetListenerWeight := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetListenerWeight');
  FMOD_Studio_System_SetListenerWeight := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_SetListenerWeight');
  FMOD_Studio_System_LoadBankFile := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_LoadBankFile');
  FMOD_Studio_System_LoadBankMemory := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_LoadBankMemory');
  FMOD_Studio_System_LoadBankCustom := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_LoadBankCustom');
  // --- missing
  FMOD_Studio_System_UnloadAll := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_UnloadAll');
  // --- missing
  FMOD_Studio_System_GetBankCount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetBankCount');
  FMOD_Studio_System_GetBankList := GetProcAddress(FmodLibHandle, 'FMOD_Studio_System_GetBankList');
  // --- missing
end;

procedure ReadFMODEventDescription;
begin
  FMOD_Studio_EventDescription_IsValid := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_IsValid');
  FMOD_Studio_EventDescription_GetID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetID');
  FMOD_Studio_EventDescription_GetPath := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetPath');
  FMOD_Studio_EventDescription_GetParameterCount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetParameterCount');
  FMOD_Studio_EventDescription_GetParameterByIndex := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetParameterByIndex');
  FMOD_Studio_EventDescription_GetParameter := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetParameter');
  FMOD_Studio_EventDescription_GetUserPropertyCount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetUserPropertyCount');
  FMOD_Studio_EventDescription_GetUserPropertyByIndex := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetUserPropertyByIndex');
  FMOD_Studio_EventDescription_GetUserProperty := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetUserProperty');
  FMOD_Studio_EventDescription_GetLength := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetLength');
  FMOD_Studio_EventDescription_GetMinimumDistance := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetMinimumDistance');
  FMOD_Studio_EventDescription_GetMaximumDistance := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetMaximumDistance');
  FMOD_Studio_EventDescription_GetSoundSize := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetSoundSize');
  FMOD_Studio_EventDescription_IsSnapshot := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_IsSnapshot');
  FMOD_Studio_EventDescription_IsOneshot := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_IsOneshot');
  FMOD_Studio_EventDescription_IsStream := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_IsStream');
  FMOD_Studio_EventDescription_Is3D := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_Is3D');
  FMOD_Studio_EventDescription_HasCue := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_HasCue');
  FMOD_Studio_EventDescription_CreateInstance := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_CreateInstance');
  FMOD_Studio_EventDescription_GetInstanceCount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetInstanceCount');
  FMOD_Studio_EventDescription_GetInstanceList := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetInstanceList');
  FMOD_Studio_EventDescription_LoadSampleData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_LoadSampleData');
  FMOD_Studio_EventDescription_UnloadSampleData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_UnloadSampleData');
  FMOD_Studio_EventDescription_GetSampleLoadingState := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetSampleLoadingState');
  FMOD_Studio_EventDescription_ReleaseAllInstances := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_ReleaseAllInstances');
  FMOD_Studio_EventDescription_SetCallback := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_SetCallback');
  FMOD_Studio_EventDescription_GetUserData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_GetUserData');
  FMOD_Studio_EventDescription_SetUserData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventDescription_SetUserData');
end;

procedure ReadFMODEventInstance;
begin
  FMOD_Studio_EventInstance_IsValid := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_IsValid');
  FMOD_Studio_EventInstance_GetDescription := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetDescription');
  FMOD_Studio_EventInstance_GetVolume := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetVolume');
  FMOD_Studio_EventInstance_SetVolume := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetVolume');
  FMOD_Studio_EventInstance_GetPitch := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetPitch');
  FMOD_Studio_EventInstance_SetPitch := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetPitch');
  FMOD_Studio_EventInstance_Get3DAttributes := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_Get3DAttributes');
  FMOD_Studio_EventInstance_Set3DAttributes := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_Set3DAttributes');
  FMOD_Studio_EventInstance_GetListenerMask := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetListenerMask');
  FMOD_Studio_EventInstance_SetListenerMask := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetListenerMask');
  FMOD_Studio_EventInstance_GetProperty := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetProperty');
  FMOD_Studio_EventInstance_SetProperty := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetProperty');
  FMOD_Studio_EventInstance_GetReverbLevel := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetReverbLevel');
  FMOD_Studio_EventInstance_SetReverbLevel := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetReverbLevel');
  FMOD_Studio_EventInstance_GetPaused := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetPaused');
  FMOD_Studio_EventInstance_SetPaused := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetPaused');
  FMOD_Studio_EventInstance_Start := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_Start');
  FMOD_Studio_EventInstance_Stop := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_Stop');
  FMOD_Studio_EventInstance_GetTimelinePosition := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetTimelinePosition');
  FMOD_Studio_EventInstance_SetTimelinePosition := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetTimelinePosition');
  FMOD_Studio_EventInstance_GetPlaybackState := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetPlaybackState');
  FMOD_Studio_EventInstance_GetChannelGroup := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetChannelGroup');
  FMOD_Studio_EventInstance_Release := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_Release');
  FMOD_Studio_EventInstance_IsVirtual := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_IsVirtual');
  FMOD_Studio_EventInstance_GetParameter := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetParameter');
  FMOD_Studio_EventInstance_GetParameterByIndex := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetParameterByIndex');
  FMOD_Studio_EventInstance_GetParameterCount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetParameterCount');
  FMOD_Studio_EventInstance_GetParameterValue := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetParameterValue');
  FMOD_Studio_EventInstance_SetParameterValue := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetParameterValue');
  FMOD_Studio_EventInstance_GetParameterValueByIndex := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetParameterValueByIndex');
  FMOD_Studio_EventInstance_SetParameterValueByIndex := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetParameterValueByIndex');
  FMOD_Studio_EventInstance_TriggerCue := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_TriggerCue');
  FMOD_Studio_EventInstance_SetCallback := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetCallback');
  FMOD_Studio_EventInstance_GetUserData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_GetUserData');
  FMOD_Studio_EventInstance_SetUserData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_EventInstance_SetUserData');
end;

procedure ReadFMODBank;
begin
  FMOD_Studio_Bank_IsValid := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_IsValid');
  FMOD_Studio_Bank_GetID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetID');
  FMOD_Studio_Bank_GetPath := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetPath');
  FMOD_Studio_Bank_Unload := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_Unload');
  FMOD_Studio_Bank_LoadSampleData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_LoadSampleData');
  FMOD_Studio_Bank_UnloadSampleData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_UnloadSampleData');
  FMOD_Studio_Bank_GetLoadingState := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetLoadingState');
  FMOD_Studio_Bank_GetSampleLoadingState := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetSampleLoadingState');
  FMOD_Studio_Bank_GetStringCount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetStringCount');
  FMOD_Studio_Bank_GetStringInfo := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetStringInfo');
  FMOD_Studio_Bank_GetEventCount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetEventCount');
  FMOD_Studio_Bank_GetEventList := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetEventList');
  FMOD_Studio_Bank_GetBusCount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetBusCount');
  FMOD_Studio_Bank_GetBusList := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetBusList');
  FMOD_Studio_Bank_GetVCACount := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetVCACount');
  FMOD_Studio_Bank_GetVCAList := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetVCAList');
  FMOD_Studio_Bank_GetUserData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_GetUserData');
  FMOD_Studio_Bank_SetUserData := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bank_SetUserData');
end;

procedure ReadFMODBus;
begin
  FMOD_Studio_Bus_IsValid := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_IsValid');
  FMOD_Studio_Bus_GetID := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_GetID');
  FMOD_Studio_Bus_GetPath := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_GetPath');
  FMOD_Studio_Bus_GetVolume := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_GetVolume');
  FMOD_Studio_Bus_SetVolume := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_SetVolume');
  FMOD_Studio_Bus_GetPaused := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_GetPaused');
  FMOD_Studio_Bus_SetPaused := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_SetPaused');
  FMOD_Studio_Bus_GetMute := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_GetMute');
  FMOD_Studio_Bus_SetMute := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_SetMute');
  FMOD_Studio_Bus_StopAllEvents := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_StopAllEvents');
  FMOD_Studio_Bus_LockChannelGroup := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_LockChannelGroup');
  FMOD_Studio_Bus_UnlockChannelGroup := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_UnlockChannelGroup');
  FMOD_Studio_Bus_GetChannelGroup := GetProcAddress(FmodLibHandle, 'FMOD_Studio_Bus_GetChannelGroup');
end;

procedure readProcedureAdresses; {$IFDEF INLINE}inline; {$ENDIF INLINE}
begin
  ReadFMODGlobal;
  ReadFMODSystem;
  ReadFMODEventDescription;
  ReadFMODEventInstance;
  ReadFMODBank;
  ReadFMODBus;
end;

procedure InitFMODStudioAPI(LibaryFileName : string);
begin
  // no need to double load libary
  if FmodLibHandle = 0 then
  begin
    FmodLibHandle := LoadLibrary(PChar(ExpandFileName(LibaryFileName)));
    if FmodLibHandle <> 0 then
    begin
      readProcedureAdresses;
    end
    // handle = 0, an error occured
    else
        raise EFileNotFoundException.CreateFmt('InitFmodStudioAPI: Couldn''t load fmod libary from file "%s".', [ExpandFileName(LibaryFileName)]);
  end;
end;

procedure ReleaseFMODStudioAPI;
begin
  if FmodLibHandle <> 0 then FreeLibrary(FmodLibHandle);
end;

end.

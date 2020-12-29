unit steam_api;

interface

uses
  // --------- Delphi ---------
  System.SysUtils,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo,
  Winapi.Windows,
  // --------- Steam ---------
  isteamclient_,
  isteamuser_,
  isteamfriends_,
  isteamapps_,
  isteamutils_,
  steamtypes;

const
  STEAM_API_LIBFILENAME = 'steam_api.dll';

  // ----------------------------------------------------------------------------------------------------------------------------------------------------------//
  // Steam API setup & shutdown
  //
  // These functions manage loading, initializing and shutdown of the steamclient.dll
  //
  // ----------------------------------------------------------------------------------------------------------------------------------------------------------//

  // SteamAPI_Init must be called before using any other API functions. If it fails, an
  // error message will be output to the debugger (or stderr) with further information.
function SteamAPI_Init() : boolean;
// SteamAPI_Shutdown should be called during process shutdown if possible.
procedure SteamAPI_Shutdown();
// SteamAPI_RestartAppIfNecessary ensures that your executable was launched through Steam.
//
// Returns true if the current process should terminate. Steam is now re-launching your application.
//
// Returns false if no action needs to be taken. This means that your executable was started through
// the Steam client, or a steam_appid.txt file is present in your game's directory (for development).
// Your current process should continue if false is returned.
//
// NOTE: If you use the Steam DRM wrapper on your primary executable file, this check is unnecessary
// since the DRM wrapper will ensure that your application was launched properly through Steam.
function SteamAPI_RestartAppIfNecessary(unOwnAppID : LongWord) : boolean; cdecl; external STEAM_API_LIBFILENAME delayed;

// ----------------------------------------------------------------------------------------------------------------------------------------------------------//
// Global accessors for Steamworks C++ APIs. See individual isteam*.h files for details.
// You should not cache the results of these accessors or pass the result pointers across
// modules! Different modules may be compiled against different SDK header versions, and
// the interface pointers could therefore be different across modules. Every line of code
// which calls into a Steamworks API should retrieve the interface from a global accessor.
// ----------------------------------------------------------------------------------------------------------------------------------------------------------//
var
  SteamClient : ISteamClient;
  SteamApps : ISteamApps;
  SteamUser : ISteamUser;
  SteamFriends : ISteamFriends;
  SteamUtils : ISteamUtils;

  // inline ISteamMatchmaking *SteamMatchmaking();
  // inline ISteamUserStats *SteamUserStats();
  // inline ISteamNetworking *SteamNetworking();
  // inline ISteamMatchmakingServers *SteamMatchmakingServers();
  // inline ISteamRemoteStorage *SteamRemoteStorage();
  // inline ISteamScreenshots *SteamScreenshots();
  // inline ISteamHTTP *SteamHTTP();
  // inline ISteamUnifiedMessages *SteamUnifiedMessages();
  // inline ISteamController *SteamController();
  // inline ISteamUGC *SteamUGC();
  // inline ISteamAppList *SteamAppList();
  // inline ISteamMusic *SteamMusic();
  // inline ISteamMusicRemote *SteamMusicRemote();
  // inline ISteamHTMLSurface *SteamHTMLSurface();
  // inline ISteamInventory *SteamInventory();
  // inline ISteamVideo *SteamVideo();
  // inline ISteamParentalSettings *SteamParentalSettings();

type
  // ----------------------------------------------------------------------------------------------------------------------------------------------------------//
  // steam callback and call-result helpers
  //
  // The following macros and classes are used to register your application for
  // callbacks and call-results, which are delivered in a predictable manner.
  //
  // STEAM_CALLBACK macros are meant for use inside of a C++ class definition.
  // They map a Steam notification callback directly to a class member function
  // which is automatically prototyped as "void func( callback_type *pParam )".
  //
  // CCallResult is used with specific Steam APIs that return "result handles".
  // The handle can be passed to a CCallResult object's Set function, along with
  // an object pointer and member-function pointer. The member function will
  // be executed once the results of the Steam API call are available.
  //
  // CCallback and CCallbackManual classes can be used instead of STEAM_CALLBACK
  // macros if you require finer control over registration and unregistration.
  //
  // Callbacks and call-results are queued automatically and are only
  // delivered/executed when your application calls SteamAPI_RunCallbacks().
  // ----------------------------------------------------------------------------------------------------------------------------------------------------------//

  HSteamAPI<T> = class
    public type
      ProcCallback = procedure(const Data : T) of object;
    strict private
      class var FRegisteredCallbacks : TObjectDictionary<ProcCallback, TObject>;
      class var FRttiContext : TRttiContext;
      class constructor Initialize;
      class destructor Finalize;
    public
      class procedure RegisterCallback(CallbackMethod : ProcCallback); overload;
      class procedure RegisterCallback(CallbackMethod : ProcCallback; iCallback : integer); overload;
      class procedure UnregisterCallback(CallbackMethod : ProcCallback);

  end;

  // SteamAPI_RunCallbacks is safe to call from multiple threads simultaneously,
  // but if you choose to do this, callback code could be executed on any thread.
  // One alternative is to call SteamAPI_RunCallbacks from the main thread only,
  // and call SteamAPI_ReleaseCurrentThreadMemory regularly on other threads.
procedure SteamAPI_RunCallbacks(); cdecl; external STEAM_API_LIBFILENAME delayed;

// ----------------------------------------------------------------------------------------------------------------------------------------------------------//
// steamclient.dll private wrapper functions
//
// The following functions are part of abstracting API access to the steamclient.dll, but should only be used in very specific cases
// ----------------------------------------------------------------------------------------------------------------------------------------------------------//

// SteamAPI_IsSteamRunning() returns true if Steam is currently running
function SteamAPI_IsSteamRunning() : boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
// Pumps out all the steam messages, calling registered callbacks.
// NOT THREADSAFE - do not call from multiple threads simultaneously.
procedure Steam_RunCallbacks(hSteamPipe : hSteamPipe; bGameServerCallbacks : boolean); cdecl; external STEAM_API_LIBFILENAME delayed;
// register the callback funcs to use to interact with the steam dll
procedure Steam_RegisterInterfaceFuncs(hModule : pointer); cdecl; external STEAM_API_LIBFILENAME delayed;
// returns the HSteamUser of the last user to dispatch a callback
function Steam_GetHSteamUserCurrent() : HSteamUser; cdecl; external STEAM_API_LIBFILENAME delayed;
// returns the filename path of the current running Steam process, used if you need to load an explicit steam dll by name.
// DEPRECATED - implementation is Windows only, and the path returned is a UTF-8 string which must be converted to UTF-16 for use with Win32 APIs
function SteamAPI_GetSteamInstallPath() : PAnsiString; cdecl; external STEAM_API_LIBFILENAME delayed;
// returns the pipe we are communicating to Steam with
function SteamAPI_GetHSteamPipe() : hSteamPipe; cdecl; external STEAM_API_LIBFILENAME delayed;

implementation

uses
  steam_api_internal,
  steam_api_callbacks;

function SteamAPI_Init_Original() : boolean; cdecl; external STEAM_API_LIBFILENAME name 'SteamAPI_Init' delayed;
procedure SteamAPI_Shutdown_Original(); cdecl; external STEAM_API_LIBFILENAME name 'SteamAPI_Shutdown' delayed;

var
  SteamLibHandle : hModule = 0;
  SteamAPIContext : TSteamAPIContext;

function SteamAPI_Init : boolean;
begin
  result := SteamAPI_Init_Original();
  if result then
  begin
    SteamAPIContext := TSteamAPIContext.Create;
    SteamClient := SteamAPIContext.SteamClient;
    SteamUser := SteamAPIContext.SteamUser;
    SteamFriends := SteamAPIContext.SteamFriends;
    SteamApps := SteamAPIContext.SteamApps;
    SteamUtils := SteamAPIContext.SteamUtils;
  end;
end;

procedure SteamAPI_Shutdown();
begin
  FreeAndNil(SteamAPIContext);
  SteamAPI_Shutdown_Original();
end;

{ HSteamAPI<T> }

class destructor HSteamAPI<T>.Finalize;
begin
  FRegisteredCallbacks.Free;
  FRttiContext.Free;
end;

class constructor HSteamAPI<T>.Initialize;
begin
  FRegisteredCallbacks := TObjectDictionary<ProcCallback, TObject>.Create([doOwnsValues]);
  FRttiContext := TRttiContext.Create;
end;

class procedure HSteamAPI<T>.RegisterCallback(CallbackMethod : ProcCallback; iCallback : integer);
begin
  FRegisteredCallbacks.Add(CallbackMethod, TSteamCallback<T>.Create(iCallback, CallbackMethod));
end;

class procedure HSteamAPI<T>.RegisterCallback(CallbackMethod : ProcCallback);
var
  CallbackDataType : TRttiType;
  iCallback : integer;
  Attribute : TCustomAttribute;
begin
  CallbackDataType := FRttiContext.GetType(TypeInfo(T));
  if not assigned(CallbackDataType) then
      raise EInsufficientRtti.Create('HSteamAPI<T>.RegisterCallback: Could not find typeinfo, if you disabled typeinfo, please use ' +
      '"HSteamAPI<T>.RegisterCallback(CallbackMethod: ProcCallback; iCallback: integer)" instead.');
  assert(CallbackDataType.IsRecord);
  iCallback := -1;
  for Attribute in CallbackDataType.GetAttributes do
    if Attribute is SteamCallbackIdentifier then
    begin
      iCallback := SteamCallbackIdentifier(Attribute).iCallback;
      Break;
    end;
  if iCallback = -1 then
      raise ESteamCallback.Create('HSteamAPI<T>.RegisterCallback: No SteamCallbackIdentifier attribte found, if you disabled typeinfo, please use ' +
      '"HSteamAPI<T>.RegisterCallback(CallbackMethod: ProcCallback; iCallback: integer)" instead.');
  RegisterCallback(CallbackMethod, iCallback);
end;

class procedure HSteamAPI<T>.UnregisterCallback(CallbackMethod : ProcCallback);
begin
  FRegisteredCallbacks.Remove(CallbackMethod);
end;

end.

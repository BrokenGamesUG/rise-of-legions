unit isteamclient_;

interface

uses
  isteamuser_,
  isteamapps_,
  isteamfriends_,
  isteamunifiedmessages_,
  isteamutils_,
  steamtypes,
  steamclientpublic;

const
  STEAMCLIENT_INTERFACE_VERSION : AnsiString = 'SteamClient017';

type

  // helper record for typed pointer, don't use ISteamClient here, because pointer
  // points to c++ class and direct use (dereference) would cause serious errors
  _ISteamClient = record
  end;

  PISteamClient = ^_ISteamClient;

  // -----------------------------------------------------------------------------
  // Purpose: Interface to creating a new steam instance, or to
  // connect to an existing steam instance, whether it's in a
  // different process or is local.
  //
  // For most scenarios this is all handled automatically via SteamAPI_Init().
  // You'll only need these APIs if you have a more complex versioning scheme,
  // or if you want to implement a multiplexed gameserver where a single process
  // is handling multiple games at once with independent gameserver SteamIDs.
  // -----------------------------------------------------------------------------
  ISteamClient = class
    private
      FHandle : PISteamClient;
    public
      // Creates a communication pipe to the Steam client.
      // NOT THREADSAFE - ensure that no other threads are accessing Steamworks API when calling
      function CreateSteamPipe() : HSteamPipe;
      // Releases a previously created communications pipe
      // NOT THREADSAFE - ensure that no other threads are accessing Steamworks API when calling
      function BReleaseSteamPipe(HSteamPipe : HSteamPipe) : boolean;
      // connects to an existing global user, failing if none exists
      // used by the game to coordinate with the steamUI
      // NOT THREADSAFE - ensure that no other threads are accessing Steamworks API when calling
      function ConnectToGlobalUser(HSteamPipe : HSteamPipe) : HSteamUser;
      // used by game servers, create a steam user that won't be shared with anyone else
      // NOT THREADSAFE - ensure that no other threads are accessing Steamworks API when calling
      function CreateLocalUser(const phSteamPipe : HSteamPipe; eAccountType : eAccountType) : HSteamUser;
      // removes an allocated user
      // NOT THREADSAFE - ensure that no other threads are accessing Steamworks API when calling
      procedure ReleaseUser(HSteamPipe : HSteamPipe; hUser : HSteamUser);
      // retrieves the ISteamUser interface associated with the handle
      function GetISteamUser(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUser;
      procedure SetLocalIPBinding(unIP : LongWord; usPort : Word);
      function GetISteamFriends(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamFriends;
      function GetISteamGenericInterface(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : Pointer;
      function GetISteamApps(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamApps;
      function GetISteamUtils(HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUtils;
      function GetIPCCallCount() : LongWord;
      function BShutdownIfAllPipesClosed() : boolean;
      function GetISteamUnifiedMessages(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUnifiedMessages;

      constructor Create(SteamClientHandle : PISteamClient);
      destructor Destroy; override;
  end;

implementation

uses
  steam_api;

function SteamAPI_ISteamClient_CreateSteamPipe(SteamClient : PISteamClient) : HSteamPipe; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_BReleaseSteamPipe(SteamClient : PISteamClient; HSteamPipe : HSteamPipe) : boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_ConnectToGlobalUser(SteamClient : PISteamClient; HSteamPipe : HSteamPipe) : HSteamUser; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_CreateLocalUser(SteamClient : PISteamClient; const phSteamPipe : HSteamPipe; eAccountType : eAccountType) : HSteamUser; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamClient_ReleaseUser(SteamClient : PISteamClient; HSteamPipe : HSteamPipe; hUser : HSteamUser); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_GetISteamUser(SteamClient : PISteamClient; HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUser; cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamGameServer *function SteamAPI_ISteamClient_GetISteamGameServer(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamClient_SetLocalIPBinding(SteamClient : PISteamClient; unIP : LongWord; usPort : Word); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_GetISteamFriends(SteamClient : PISteamClient; HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamFriends; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_GetISteamUtils(SteamClient : PISteamClient; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUtils; cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamMatchmaking *function SteamAPI_ISteamClient_GetISteamMatchmaking(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamMatchmakingServers *function SteamAPI_ISteamClient_GetISteamMatchmakingServers(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_GetISteamGenericInterface(SteamClient : PISteamClient; HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : Pointer; cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamUserStats *function SteamAPI_ISteamClient_GetISteamUserStats(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamGameServerStats *function SteamAPI_ISteamClient_GetISteamGameServerStats(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_GetISteamApps(SteamClient : PISteamClient; HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamApps; cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamNetworking *function SteamAPI_ISteamClient_GetISteamNetworking(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamRemoteStorage *function SteamAPI_ISteamClient_GetISteamRemoteStorage(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamScreenshots *function SteamAPI_ISteamClient_GetISteamScreenshots(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_GetIPCCallCount(SteamClient : PISteamClient) : LongWord; cdecl; external STEAM_API_LIBFILENAME delayed;
// procedure SteamAPI_ISteamClient_SetWarningMessageHook(SteamClient : PISteamClient; pFunction : SteamAPIWarningMessageHook_t);  cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_BShutdownIfAllPipesClosed(SteamClient : PISteamClient) : boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamHTTP *function SteamAPI_ISteamClient_GetISteamHTTP(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamClient_GetISteamUnifiedMessages(SteamClient : PISteamClient; HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUnifiedMessages; cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamController *function SteamAPI_ISteamClient_GetISteamController(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamUGC *function SteamAPI_ISteamClient_GetISteamUGC(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamAppList *function SteamAPI_ISteamClient_GetISteamAppList(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamMusic *function SteamAPI_ISteamClient_GetISteamMusic(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamMusicRemote *function SteamAPI_ISteamClient_GetISteamMusicRemote(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamHTMLSurface *function SteamAPI_ISteamClient_GetISteamHTMLSurface(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamInventory *function SteamAPI_ISteamClient_GetISteamInventory(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamVideo *function SteamAPI_ISteamClient_GetISteamVideo(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;
// class ISteamParentalSettings *function SteamAPI_ISteamClient_GetISteamParentalSettings(SteamClient : PISteamClient; hSteamUser : HSteamUser; hSteamPipe : HSteamPipe ; const char * pchVersion);  cdecl; external STEAM_API_LIBFILENAME delayed;

{ TSteamClient }

function ISteamClient.BReleaseSteamPipe(HSteamPipe : HSteamPipe) : boolean;
begin
  result := SteamAPI_ISteamClient_BReleaseSteamPipe(FHandle, HSteamPipe);
end;

function ISteamClient.BShutdownIfAllPipesClosed : boolean;
begin
  result := SteamAPI_ISteamClient_BShutdownIfAllPipesClosed(FHandle);
end;

function ISteamClient.ConnectToGlobalUser(HSteamPipe : HSteamPipe) : HSteamUser;
begin
  result := SteamAPI_ISteamClient_ConnectToGlobalUser(FHandle, HSteamPipe);
end;

constructor ISteamClient.Create(SteamClientHandle : PISteamClient);
begin
  FHandle := SteamClientHandle;
end;

function ISteamClient.CreateLocalUser(const phSteamPipe : HSteamPipe; eAccountType : eAccountType) : HSteamUser;
begin
  result := SteamAPI_ISteamClient_CreateLocalUser(FHandle, phSteamPipe, eAccountType);
end;

function ISteamClient.CreateSteamPipe : HSteamPipe;
begin
  result := SteamAPI_ISteamClient_CreateSteamPipe(FHandle);
end;

destructor ISteamClient.Destroy;
begin

  inherited;
end;

function ISteamClient.GetIPCCallCount : LongWord;
begin
  result := SteamAPI_ISteamClient_GetIPCCallCount(FHandle);
end;

function ISteamClient.GetISteamApps(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamApps;
begin
  result := SteamAPI_ISteamClient_GetISteamApps(FHandle, HSteamUser, HSteamPipe, pchVersion);
end;

function ISteamClient.GetISteamFriends(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamFriends;
begin
  result := SteamAPI_ISteamClient_GetISteamFriends(FHandle, HSteamUser, HSteamPipe, pchVersion);
end;

function ISteamClient.GetISteamGenericInterface(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : Pointer;
begin
  result := SteamAPI_ISteamClient_GetISteamGenericInterface(FHandle, HSteamUser, HSteamPipe, pchVersion);
end;

function ISteamClient.GetISteamUnifiedMessages(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUnifiedMessages;
begin
  result := SteamAPI_ISteamClient_GetISteamUnifiedMessages(FHandle, HSteamUser, HSteamPipe, pchVersion);
end;

function ISteamClient.GetISteamUser(HSteamUser : HSteamUser; HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUser;
begin
  result := SteamAPI_ISteamClient_GetISteamUser(FHandle, HSteamUser, HSteamPipe, pchVersion);
end;

function ISteamClient.GetISteamUtils(HSteamPipe : HSteamPipe; const pchVersion : AnsiString) : PISteamUtils;
begin
  result := SteamAPI_ISteamClient_GetISteamUtils(FHandle, HSteamPipe, pchVersion);
end;

procedure ISteamClient.ReleaseUser(HSteamPipe : HSteamPipe; hUser : HSteamUser);
begin
  SteamAPI_ISteamClient_ReleaseUser(FHandle, HSteamPipe, hUser);
end;

procedure ISteamClient.SetLocalIPBinding(unIP : LongWord; usPort : Word);
begin
  SteamAPI_ISteamClient_ReleaseUser(FHandle, unIP, usPort);
end;

end.

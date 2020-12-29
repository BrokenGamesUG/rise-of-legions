unit steam_api_internal;

interface

uses
  // --------- Delphi ---------
  System.SysUtils,
  Winapi.Windows,
  // --------- Steam ----------
  steam_api,
  steamtypes,
  isteamclient_,
  isteamuser_,
  isteamfriends_,
  isteamapps_,
  isteamutils_;

type
  TSteamAPIContext = class
    private
      FhSteamUser : HSteamUser;
      FhSteamPipe : HSteamPipe;
      FSteamClient : ISteamClient;
      FSteamUser : ISteamUser;
      FSteamFriends : ISteamFriends;
      FSteamApps : ISteamApps;
      FSteamUtils : ISteamUtils;
    public
      property SteamClient : ISteamClient read FSteamClient;
      property SteamUser : ISteamUser read FSteamUser;
      property SteamFriends : ISteamFriends read FSteamFriends;
      property SteamApps : ISteamApps read FSteamApps;
      property SteamUtils : ISteamUtils read FSteamUtils;
      constructor Create;
      destructor Destroy; override;
  end;

  ESteamError = class(Exception);

implementation

function SteamAPI_GetHSteamUser() : HSteamUser; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamInternal_ContextInit(pContextInitData : Pointer) : Pointer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamInternal_CreateInterface(const ver : AnsiString) : Pointer; cdecl; external STEAM_API_LIBFILENAME delayed;

{ TSteamAPIContext }

constructor TSteamAPIContext.Create;
var
  SteamClientHandle : PISteamClient;
  SteamUserHandle : PISteamUser;
  SteamFriendsHandle : PISteamFriends;
  SteamAppsHandle : PISteamApps;
  SteamUtilsHandle : PISteamUtils;
begin
  FhSteamUser := SteamAPI_GetHSteamUser();
  FhSteamPipe := SteamAPI_GetHSteamPipe();
  if FhSteamPipe = 0 then
      raise ESteamError.Create('TSteamAPIContext.Create: SteamAPI_GetHSteamPipe error.');

  SteamClientHandle := PISteamClient(SteamInternal_CreateInterface(STEAMCLIENT_INTERFACE_VERSION));
  if not assigned(SteamClientHandle) then
      raise ESteamError.Create('TSteamAPIContext.Create: ISteamClient error.');
  FSteamClient := ISteamClient.Create(SteamClientHandle);

  SteamUserHandle := SteamClient.GetISteamUser(FhSteamUser, FhSteamPipe, STEAMUSER_INTERFACE_VERSION);
  if not assigned(SteamUserHandle) then
      raise ESteamError.Create('TSteamAPIContext.Create: ISteamUser error.');
  FSteamUser := ISteamUser.Create(SteamUserHandle);

  SteamFriendsHandle := SteamClient.GetISteamFriends(FhSteamUser, FhSteamPipe, STEAMFRIENDS_INTERFACE_VERSION);
  if not assigned(SteamFriendsHandle) then
      raise ESteamError.Create('TSteamAPIContext.Create: ISteamFriends error.');
  FSteamFriends := ISteamFriends.Create(SteamFriendsHandle);

  SteamAppsHandle := SteamClient.GetISteamApps(FhSteamUser, FhSteamPipe, STEAMAPPS_INTERFACE_VERSION);
  if not assigned(SteamAppsHandle) then
      raise ESteamError.Create('TSteamAPIContext.Create: ISteamApps error.');
  FSteamApps := ISteamApps.Create(SteamAppsHandle);

  SteamUtilsHandle := SteamClient.GetISteamUtils(FhSteamUser, STEAMUTILS_INTERFACE_VERSION);
  if not assigned(SteamUtilsHandle) then
      raise ESteamError.Create('TSteamAPIContext.Create: ISteamUtils error.');
  FSteamUtils := ISteamUtils.Create(SteamUtilsHandle);

end;

destructor TSteamAPIContext.Destroy;
begin
  FSteamClient.Free;
  FSteamUser.Free;
  FSteamFriends.Free;
  FSteamApps.Free;
  FSteamUtils.Free;
  inherited;
end;

end.

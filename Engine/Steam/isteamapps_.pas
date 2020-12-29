unit isteamapps_;

interface

uses
  steamtypes;

const
  STEAMAPPS_INTERFACE_VERSION = 'STEAMAPPS_INTERFACE_VERSION008';

type
  _ISteamApps = record
  end;

  PISteamApps = ^_ISteamApps;

  ISteamApps = class
    private
      FHandle : PISteamApps;
    public
      function BIsSubscribed : Boolean;
      function BIsLowViolence : Boolean;
      function BIsCybercafe : Boolean;
      function BIsVACBanned : Boolean;
      function GetCurrentGameLanguage : string;
      function GetAvailableGameLanguages : string;
      function BIsSubscribedApp(appID : AppId_t) : Boolean;
      function BIsDlcInstalled(appID : AppId_t) : Boolean;
      function GetEarliestPurchaseUnixTime(nAppID : AppId_t) : UInt32;
      function BIsSubscribedFromFreeWeekend : Boolean;
      function GetDLCCount : Integer;
      function BGetDLCDataByIndex(iDLC : Integer; out pAppID : AppId_t; out pbAvailable : Boolean; out pchName : string) : Boolean;
      procedure InstallDLC(nAppID : AppId_t);
      procedure UninstallDLC(nAppID : AppId_t);
      procedure RequestAppProofOfPurchaseKey(nAppID : AppId_t);
      function GetCurrentBetaName(out pchName : string) : Boolean;
      function MarkContentCorrupt(bMissingFilesOnly : Boolean) : Boolean;
      function GetInstalledDepots(appID : AppId_t; pvecDepots : PDepotId_t; cMaxDepots : UInt32) : UInt32;
      function GetAppInstallDir(appID : AppId_t; out pchFolder : string) : UInt32;
      function BIsAppInstalled(appID : AppId_t) : Boolean;
      function GetAppOwner : UInt64;
      function GetLaunchQueryParam(const pchKey : string) : string;
      function GetDlcDownloadProgress(nAppID : AppId_t; out punBytesDownloaded : UInt64; out punBytesTotal : UInt64) : Boolean;
      function GetAppBuildId : Integer;
      procedure RequestAllProofOfPurchaseKeys;

      constructor Create(SteamAppsHandle : PISteamApps);
      destructor Destroy; override;
  end;

  [SteamCallbackIdentifier(k_iSteamAppsCallbacks + 5)]
  DlcInstalled_t = record
    const
      k_iCallback = k_iSteamAppsCallbacks + 5;
    var
      m_nAppID : AppId_t; // AppID of the DLC
  end;

implementation

uses
  steam_api;

function SteamAPI_ISteamApps_BIsSubscribed(SteamApps : PISteamApps) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_BIsLowViolence(SteamApps : PISteamApps) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_BIsCybercafe(SteamApps : PISteamApps) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_BIsVACBanned(SteamApps : PISteamApps) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetCurrentGameLanguage(SteamApps : PISteamApps) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetAvailableGameLanguages(SteamApps : PISteamApps) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_BIsSubscribedApp(SteamApps : PISteamApps; appID : AppId_t) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_BIsDlcInstalled(SteamApps : PISteamApps; appID : AppId_t) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetEarliestPurchaseUnixTime(SteamApps : PISteamApps; nAppID : AppId_t) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_BIsSubscribedFromFreeWeekend(SteamApps : PISteamApps) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetDLCCount(SteamApps : PISteamApps) : Integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_BGetDLCDataByIndex(SteamApps : PISteamApps; iDLC : Integer; out pAppID : AppId_t; out pbAvailable : Boolean; pchName : PAnsiChar; cchNameBufferSize : Integer) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamApps_InstallDLC(SteamApps : PISteamApps; nAppID : AppId_t); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamApps_UninstallDLC(SteamApps : PISteamApps; nAppID : AppId_t); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamApps_RequestAppProofOfPurchaseKey(SteamApps : PISteamApps; nAppID : AppId_t); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetCurrentBetaName(SteamApps : PISteamApps; pchName : PAnsiChar; cchNameBufferSize : Integer) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_MarkContentCorrupt(SteamApps : PISteamApps; bMissingFilesOnly : Boolean) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetInstalledDepots(SteamApps : PISteamApps; appID : AppId_t; pvecDepots : PDepotId_t; cMaxDepots : UInt32) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetAppInstallDir(SteamApps : PISteamApps; appID : AppId_t; pchFolder : PAnsiChar; cchFolderBufferSize : UInt32) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_BIsAppInstalled(SteamApps : PISteamApps; appID : AppId_t) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetAppOwner(SteamApps : PISteamApps) : UInt64; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetLaunchQueryParam(SteamApps : PISteamApps; const pchKey : AnsiString) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetDlcDownloadProgress(SteamApps : PISteamApps; nAppID : AppId_t; out punBytesDownloaded : UInt64; out punBytesTotal : UInt64) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamApps_GetAppBuildId(SteamApps : PISteamApps) : Integer; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamApps_RequestAllProofOfPurchaseKeys(SteamApps : PISteamApps); cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamApps_GetFileDetails(SteamApps : PISteamApps; const char * pszFileName) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;

{ ISteamApps }

function ISteamApps.BGetDLCDataByIndex(iDLC : Integer; out pAppID : AppId_t; out pbAvailable : Boolean; out pchName : string) : Boolean;
var
  Buffer : TSteamStringBuffer;
begin
  result := SteamAPI_ISteamApps_BGetDLCDataByIndex(FHandle, iDLC, pAppID, pbAvailable, Buffer, STEAM_STRING_BUFFER_LENGTH);
  pchName := string(Buffer);
end;

function ISteamApps.BIsAppInstalled(appID : AppId_t) : Boolean;
begin
  result := SteamAPI_ISteamApps_BIsAppInstalled(FHandle, appID);
end;

function ISteamApps.BIsCybercafe : Boolean;
begin
  result := SteamAPI_ISteamApps_BIsCybercafe(FHandle);
end;

function ISteamApps.BIsDlcInstalled(appID : AppId_t) : Boolean;
begin
  result := SteamAPI_ISteamApps_BIsDlcInstalled(FHandle, appID);
end;

function ISteamApps.BIsLowViolence : Boolean;
begin
  result := SteamAPI_ISteamApps_BIsLowViolence(FHandle);
end;

function ISteamApps.BIsSubscribed : Boolean;
begin
  result := SteamAPI_ISteamApps_BIsSubscribed(FHandle);
end;

function ISteamApps.BIsSubscribedApp(appID : AppId_t) : Boolean;
begin
  result := SteamAPI_ISteamApps_BIsSubscribedApp(FHandle, appID);
end;

function ISteamApps.BIsSubscribedFromFreeWeekend : Boolean;
begin
  result := SteamAPI_ISteamApps_BIsSubscribedFromFreeWeekend(FHandle);
end;

function ISteamApps.BIsVACBanned : Boolean;
begin
  result := SteamAPI_ISteamApps_BIsVACBanned(FHandle);
end;

constructor ISteamApps.Create(SteamAppsHandle : PISteamApps);
begin
  FHandle := SteamAppsHandle;
end;

destructor ISteamApps.Destroy;
begin
  inherited;
end;

function ISteamApps.GetAppBuildId : Integer;
begin
  result := SteamAPI_ISteamApps_GetAppBuildId(FHandle);
end;

function ISteamApps.GetAppInstallDir(appID : AppId_t; out pchFolder : string) : UInt32;
var
  Buffer : TSteamStringBuffer;
begin
  result := SteamAPI_ISteamApps_GetAppInstallDir(FHandle, appID, Buffer, STEAM_STRING_BUFFER_LENGTH);
  pchFolder := string(Buffer);
end;

function ISteamApps.GetAppOwner : UInt64;
begin
  result := SteamAPI_ISteamApps_GetAppOwner(FHandle);
end;

function ISteamApps.GetAvailableGameLanguages : string;
begin
  result := string(SteamAPI_ISteamApps_GetAvailableGameLanguages(FHandle));
end;

function ISteamApps.GetCurrentBetaName(out pchName : string) : Boolean;
var
  Buffer : TSteamStringBuffer;
begin
  result := SteamAPI_ISteamApps_GetCurrentBetaName(FHandle, Buffer, STEAM_STRING_BUFFER_LENGTH);
  pchName := string(Buffer);
end;

function ISteamApps.GetCurrentGameLanguage : string;
begin
  result := string(SteamAPI_ISteamApps_GetCurrentGameLanguage(FHandle));
end;

function ISteamApps.GetDLCCount : Integer;
begin
  result := SteamAPI_ISteamApps_GetDLCCount(FHandle);
end;

function ISteamApps.GetDlcDownloadProgress(nAppID : AppId_t; out punBytesDownloaded, punBytesTotal : UInt64) : Boolean;
begin
  result := SteamAPI_ISteamApps_GetDlcDownloadProgress(FHandle, nAppID, punBytesDownloaded, punBytesTotal);
end;

function ISteamApps.GetEarliestPurchaseUnixTime(nAppID : AppId_t) : UInt32;
begin
  result := SteamAPI_ISteamApps_GetEarliestPurchaseUnixTime(FHandle, nAppID);
end;

function ISteamApps.GetInstalledDepots(appID : AppId_t; pvecDepots : PDepotId_t; cMaxDepots : UInt32) : UInt32;
begin
  result := SteamAPI_ISteamApps_GetInstalledDepots(FHandle, appID, pvecDepots, cMaxDepots);
end;

function ISteamApps.GetLaunchQueryParam(const pchKey : string) : string;
begin
  result := string(SteamAPI_ISteamApps_GetLaunchQueryParam(FHandle, AnsiString(pchKey)));
end;

procedure ISteamApps.InstallDLC(nAppID : AppId_t);
begin
  SteamAPI_ISteamApps_InstallDLC(FHandle, nAppID);
end;

function ISteamApps.MarkContentCorrupt(bMissingFilesOnly : Boolean) : Boolean;
begin
  result := SteamAPI_ISteamApps_MarkContentCorrupt(FHandle, bMissingFilesOnly);
end;

procedure ISteamApps.RequestAllProofOfPurchaseKeys;
begin
  SteamAPI_ISteamApps_RequestAllProofOfPurchaseKeys(FHandle);
end;

procedure ISteamApps.RequestAppProofOfPurchaseKey(nAppID : AppId_t);
begin
  SteamAPI_ISteamApps_RequestAppProofOfPurchaseKey(FHandle, nAppID);
end;

procedure ISteamApps.UninstallDLC(nAppID : AppId_t);
begin
  SteamAPI_ISteamApps_UninstallDLC(FHandle, nAppID);
end;

end.

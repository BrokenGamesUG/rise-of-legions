unit isteamuser_;

interface

uses
  System.SysUtils,
  steamclientpublic,
  steamtypes;

const
  STEAMUSER_INTERFACE_VERSION : AnsiString = 'SteamUser019';

type
  // helper record for typed pointer
  _ISteamUser = record
  end;

  PISteamUser = ^_ISteamUser;

  ISteamUser = class
    private
      FHandle : PISteamUser;
    public
      function GetHSteamUser : HSteamUser;
      function BLoggedOn : Boolean;
      function GetSteamID : UInt64;
      function InitiateGameConnection(pAuthBlob : Pointer; cbMaxAuthBlob : Integer; steamIDGameServer : CSteamID; unIPServer : UInt32; usPortServer : UInt16; bSecure : Boolean) : Integer;
      procedure TerminateGameConnection(unIPServer : UInt32; usPortServer : UInt16);
      procedure TrackAppUsageEvent(gameID : CGameID; eAppUsageEvent : Integer; const pchExtraInfo : AnsiString);
      function GetUserDataFolder(out pchBuffer : string) : Boolean;
      procedure StartVoiceRecording;
      procedure StopVoiceRecording;
      function GetAvailableVoice(out pcbCompressed : UInt32; out pcbUncompressed_Deprecated : UInt32; nUncompressedVoiceDesiredSampleRate_Deprecated : UInt32) : EVoiceResult;
      function GetVoice(bWantCompressed : Boolean; pDestBuffer : Pointer; cbDestBufferSize : UInt32; out nBytesWritten : UInt32; bWantUncompressed_Deprecated : Boolean; pUncompressedDestBuffer_Deprecated : Pointer; cbUncompressedDestBufferSize_Deprecated : UInt32; out nUncompressBytesWritten_Deprecated : UInt32; nUncompressedVoiceDesiredSampleRate_Deprecated : UInt32) : EVoiceResult;
      function DecompressVoice(pCompressed : Pointer; cbCompressed : UInt32; pDestBuffer : Pointer; cbDestBufferSize : UInt32; out nBytesWritten : UInt32; nDesiredSampleRate : UInt32) : EVoiceResult;
      function GetVoiceOptimalSampleRate : UInt32;
      function GetAuthSessionTicket(pTicket : Pointer; cbMaxTicket : Integer; out pcbTicket : UInt32) : HAuthTicket;
      function BeginAuthSession(pAuthTicket : Pointer; cbAuthTicket : Integer; steamID : CSteamID) : EBeginAuthSessionResult;
      procedure EndAuthSession(steamID : CSteamID);
      procedure CancelAuthTicket(HAuthTicket : HAuthTicket);
      function UserHasLicenseForApp(steamID : CSteamID; appID : AppId_t) : EUserHasLicenseForAppResult;
      function BIsBehindNAT : Boolean;
      procedure AdvertiseGame(steamIDGameServer : CSteamID; unIPServer : UInt32; usPortServer : UInt16);
      // function RequestEncryptedAppTicket( pDataToInclude : Pointer; cbDataToInclude : integer) : SteamAPICall_t;
      function GetEncryptedAppTicket(pTicket : Pointer; cbMaxTicket : Integer; out pcbTicket : UInt32) : Boolean;
      function GetGameBadgeLevel(nSeries : Integer; bFoil : Boolean) : Integer;
      function GetPlayerSteamLevel : Integer;
      // function RequestStoreAuthURL( const pchRedirectURL : AnsiString) : SteamAPICall_t;
      function BIsPhoneVerified : Boolean;
      function BIsTwoFactorEnabled : Boolean;
      function BIsPhoneIdentifying : Boolean;
      function BIsPhoneRequiringVerification : Boolean;

      constructor Create(SteamUserHandle : PISteamUser);
      destructor Destroy; override;
  end;

  [SteamCallbackIdentifier(k_iSteamUserCallbacks + 3)]
  SteamServersDisconnected_t = record
    const
      k_iCallback = k_iSteamUserCallbacks + 3;
    var
      m_eResult : EResult;
  end;

  [SteamCallbackIdentifier(k_iSteamUserCallbacks + 63)]
  GetAuthSessionTicketResponse_t = record
    const
      k_iCallback = k_iSteamUserCallbacks + 63;
    var
      m_hAuthTicket : HAuthTicket;
      m_eResult : EResult;
  end;

  [SteamCallbackIdentifier(k_iSteamUserCallbacks + 52)]
  MicroTxnAuthorizationResponse_t = record
    const
      k_iCallback = k_iSteamUserCallbacks + 52;
    var
      m_unAppID : UInt32;    // AppID for this microtransaction
      m_ulOrderID : UInt64;  // OrderID provided for the microtransaction
      m_bAuthorized : UInt8; // if user authorized transaction
  end;

implementation

uses
  steam_api;

function SteamAPI_ISteamUser_GetHSteamUser(SteamUser : PISteamUser) : HSteamUser; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_BLoggedOn(SteamUser : PISteamUser) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetSteamID(SteamUser : PISteamUser) : UInt64; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_InitiateGameConnection(SteamUser : PISteamUser; pAuthBlob : Pointer; cbMaxAuthBlob : Integer; steamIDGameServer : CSteamID; unIPServer : UInt32; usPortServer : UInt16; bSecure : Boolean) : Integer; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUser_TerminateGameConnection(SteamUser : PISteamUser; unIPServer : UInt32; usPortServer : UInt16); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUser_TrackAppUsageEvent(SteamUser : PISteamUser; gameID : CGameID; eAppUsageEvent : Integer; const pchExtraInfo : AnsiString); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetUserDataFolder(SteamUser : PISteamUser; pchBuffer : PAnsiChar; cubBuffer : Integer) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUser_StartVoiceRecording(SteamUser : PISteamUser); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUser_StopVoiceRecording(SteamUser : PISteamUser); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetAvailableVoice(SteamUser : PISteamUser; out pcbCompressed : UInt32; out pcbUncompressed_Deprecated : UInt32; nUncompressedVoiceDesiredSampleRate_Deprecated : UInt32) : EVoiceResult; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetVoice(SteamUser : PISteamUser; bWantCompressed : Boolean; pDestBuffer : Pointer; cbDestBufferSize : UInt32; out nBytesWritten : UInt32; bWantUncompressed_Deprecated : Boolean; pUncompressedDestBuffer_Deprecated : Pointer; cbUncompressedDestBufferSize_Deprecated : UInt32; out nUncompressBytesWritten_Deprecated : UInt32; nUncompressedVoiceDesiredSampleRate_Deprecated : UInt32) : EVoiceResult; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_DecompressVoice(SteamUser : PISteamUser; pCompressed : Pointer; cbCompressed : UInt32; pDestBuffer : Pointer; cbDestBufferSize : UInt32; out nBytesWritten : UInt32; nDesiredSampleRate : UInt32) : EVoiceResult; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetVoiceOptimalSampleRate(SteamUser : PISteamUser) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetAuthSessionTicket(SteamUser : PISteamUser; pTicket : Pointer; cbMaxTicket : Integer; out pcbTicket : UInt32) : HAuthTicket; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_BeginAuthSession(SteamUser : PISteamUser; pAuthTicket : Pointer; cbAuthTicket : Integer; steamID : CSteamID) : EBeginAuthSessionResult; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUser_EndAuthSession(SteamUser : PISteamUser; steamID : CSteamID); cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUser_CancelAuthTicket(SteamUser : PISteamUser; HAuthTicket : HAuthTicket); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_UserHasLicenseForApp(SteamUser : PISteamUser; steamID : CSteamID; appID : AppId_t) : EUserHasLicenseForAppResult; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_BIsBehindNAT(SteamUser : PISteamUser) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUser_AdvertiseGame(SteamUser : PISteamUser; steamIDGameServer : CSteamID; unIPServer : UInt32; usPortServer : UInt16); cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamUser_RequestEncryptedAppTicket(SteamUser : PISteamUser; pDataToInclude : Pointer; cbDataToInclude : integer) : SteamAPICall_t;cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetEncryptedAppTicket(SteamUser : PISteamUser; pTicket : Pointer; cbMaxTicket : Integer; out pcbTicket : UInt32) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetGameBadgeLevel(SteamUser : PISteamUser; nSeries : Integer; bFoil : Boolean) : Integer; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_GetPlayerSteamLevel(SteamUser : PISteamUser) : Integer; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamUser_RequestStoreAuthURL(SteamUser : PISteamUser; const pchRedirectURL : AnsiString) : SteamAPICall_t;cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_BIsPhoneVerified(SteamUser : PISteamUser) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_BIsTwoFactorEnabled(SteamUser : PISteamUser) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_BIsPhoneIdentifying(SteamUser : PISteamUser) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUser_BIsPhoneRequiringVerification(SteamUser : PISteamUser) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;

{ ISteamUser }

procedure ISteamUser.AdvertiseGame(steamIDGameServer : CSteamID; unIPServer : UInt32; usPortServer : UInt16);
begin
  SteamAPI_ISteamUser_AdvertiseGame(FHandle, steamIDGameServer, unIPServer, usPortServer);
end;

function ISteamUser.BeginAuthSession(pAuthTicket : Pointer; cbAuthTicket : Integer; steamID : CSteamID) : EBeginAuthSessionResult;
begin
  result := SteamAPI_ISteamUser_BeginAuthSession(FHandle, pAuthTicket, cbAuthTicket, steamID);
end;

function ISteamUser.BIsBehindNAT : Boolean;
begin
  result := SteamAPI_ISteamUser_BIsBehindNAT(FHandle);
end;

function ISteamUser.BIsPhoneIdentifying : Boolean;
begin
  result := SteamAPI_ISteamUser_BIsPhoneIdentifying(FHandle);
end;

function ISteamUser.BIsPhoneRequiringVerification : Boolean;
begin
  result := SteamAPI_ISteamUser_BIsPhoneRequiringVerification(FHandle);
end;

function ISteamUser.BIsPhoneVerified : Boolean;
begin
  result := SteamAPI_ISteamUser_BIsPhoneVerified(FHandle);
end;

function ISteamUser.BIsTwoFactorEnabled : Boolean;
begin
  result := SteamAPI_ISteamUser_BIsTwoFactorEnabled(FHandle);
end;

function ISteamUser.BLoggedOn : Boolean;
begin
  result := SteamAPI_ISteamUser_BLoggedOn(FHandle);
end;

procedure ISteamUser.CancelAuthTicket(HAuthTicket : HAuthTicket);
begin
  SteamAPI_ISteamUser_CancelAuthTicket(FHandle, HAuthTicket);
end;

constructor ISteamUser.Create(SteamUserHandle : PISteamUser);
begin
  FHandle := SteamUserHandle;
end;

function ISteamUser.DecompressVoice(pCompressed : Pointer; cbCompressed : UInt32;
  pDestBuffer : Pointer; cbDestBufferSize : UInt32; out nBytesWritten : UInt32;
  nDesiredSampleRate : UInt32) : EVoiceResult;
begin
  result := SteamAPI_ISteamUser_DecompressVoice(FHandle, pCompressed, cbCompressed, pDestBuffer, cbDestBufferSize, nBytesWritten, nDesiredSampleRate);
end;

destructor ISteamUser.Destroy;
begin
  inherited;
end;

procedure ISteamUser.EndAuthSession(steamID : CSteamID);
begin
  SteamAPI_ISteamUser_EndAuthSession(FHandle, steamID);
end;

function ISteamUser.GetAuthSessionTicket(pTicket : Pointer; cbMaxTicket : Integer; out pcbTicket : UInt32) : HAuthTicket;
begin
  result := SteamAPI_ISteamUser_GetAuthSessionTicket(FHandle, pTicket, cbMaxTicket, pcbTicket);
end;

function ISteamUser.GetAvailableVoice(out pcbCompressed, pcbUncompressed_Deprecated : UInt32;
  nUncompressedVoiceDesiredSampleRate_Deprecated : UInt32) : EVoiceResult;
begin
  result := SteamAPI_ISteamUser_GetAvailableVoice(FHandle, pcbCompressed, pcbUncompressed_Deprecated, nUncompressedVoiceDesiredSampleRate_Deprecated);
end;

function ISteamUser.GetEncryptedAppTicket(pTicket : Pointer; cbMaxTicket : Integer; out pcbTicket : UInt32) : Boolean;
begin
  result := SteamAPI_ISteamUser_GetEncryptedAppTicket(FHandle, pTicket, cbMaxTicket, pcbTicket);
end;

function ISteamUser.GetGameBadgeLevel(nSeries : Integer; bFoil : Boolean) : Integer;
begin
  result := SteamAPI_ISteamUser_GetGameBadgeLevel(FHandle, nSeries, bFoil);
end;

function ISteamUser.GetHSteamUser : HSteamUser;
begin
  result := SteamAPI_ISteamUser_GetHSteamUser(FHandle);
end;

function ISteamUser.GetPlayerSteamLevel : Integer;
begin
  result := SteamAPI_ISteamUser_GetPlayerSteamLevel(FHandle);
end;

function ISteamUser.GetSteamID : UInt64;
begin
  result := SteamAPI_ISteamUser_GetSteamID(FHandle);
end;

function ISteamUser.GetUserDataFolder(out pchBuffer : string) : Boolean;
var
  Buffer : TSteamStringBuffer;
begin
  result := SteamAPI_ISteamUser_GetUserDataFolder(FHandle, Buffer, STEAM_STRING_BUFFER_LENGTH);
  pchBuffer := string(Buffer);
end;

function ISteamUser.GetVoice(bWantCompressed : Boolean; pDestBuffer : Pointer; cbDestBufferSize : UInt32; out nBytesWritten : UInt32;
  bWantUncompressed_Deprecated : Boolean; pUncompressedDestBuffer_Deprecated : Pointer; cbUncompressedDestBufferSize_Deprecated : UInt32;
  out nUncompressBytesWritten_Deprecated : UInt32; nUncompressedVoiceDesiredSampleRate_Deprecated : UInt32) : EVoiceResult;
begin
  result := SteamAPI_ISteamUser_GetVoice(FHandle, bWantCompressed, pDestBuffer, cbDestBufferSize, nBytesWritten, bWantUncompressed_Deprecated, pUncompressedDestBuffer_Deprecated,
    cbUncompressedDestBufferSize_Deprecated, nUncompressBytesWritten_Deprecated, nUncompressedVoiceDesiredSampleRate_Deprecated);
end;

function ISteamUser.GetVoiceOptimalSampleRate : UInt32;
begin
  result := SteamAPI_ISteamUser_GetVoiceOptimalSampleRate(FHandle);
end;

function ISteamUser.InitiateGameConnection(pAuthBlob : Pointer; cbMaxAuthBlob : Integer; steamIDGameServer : CSteamID; unIPServer : UInt32;
  usPortServer : UInt16; bSecure : Boolean) : Integer;
begin
  result := SteamAPI_ISteamUser_InitiateGameConnection(FHandle, pAuthBlob, cbMaxAuthBlob, steamIDGameServer, unIPServer, usPortServer, bSecure);
end;

procedure ISteamUser.StartVoiceRecording;
begin
  SteamAPI_ISteamUser_StartVoiceRecording(FHandle);
end;

procedure ISteamUser.StopVoiceRecording;
begin
  SteamAPI_ISteamUser_StopVoiceRecording(FHandle);
end;

procedure ISteamUser.TerminateGameConnection(unIPServer : UInt32; usPortServer : UInt16);
begin
  SteamAPI_ISteamUser_TerminateGameConnection(FHandle, unIPServer, usPortServer);
end;

procedure ISteamUser.TrackAppUsageEvent(gameID : CGameID; eAppUsageEvent : Integer; const pchExtraInfo : AnsiString);
begin
  SteamAPI_ISteamUser_TrackAppUsageEvent(FHandle, gameID, eAppUsageEvent, pchExtraInfo);
end;

function ISteamUser.UserHasLicenseForApp(steamID : CSteamID; appID : AppId_t) : EUserHasLicenseForAppResult;
begin
  result := SteamAPI_ISteamUser_UserHasLicenseForApp(FHandle, steamID, appID);
end;

end.

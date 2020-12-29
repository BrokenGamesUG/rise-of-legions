unit isteamutils_;

interface

uses
  System.SysUtils,
  steamclientpublic,
  steamtypes;

const
  STEAMUTILS_INTERFACE_VERSION = 'SteamUtils009';

type
  // helper record for typed pointer
  _ISteamUtils = record
  end;

  PISteamUtils = ^_ISteamUtils;

  ISteamUtils = class
    private
      FHandle : PISteamUtils;
    public
      // Steam server time.  Number of seconds since January 1, 1970, GMT (i.e unix time)
      function GetServerRealTime() : UInt32;
      // returns the 2 digit ISO 3166-1-alpha-2 format country code this client is running in (as looked up via an IP-to-location database)
      // e.g "US" or "UK".
      function GetIPCountry() : string;
      // return the amount of battery power left in the current system in % [0..100], 255 for being on AC power
      function GetCurrentBatteryPower() : uint8;
      // returns the appID of the current process
      function GetAppID() : UInt32;
      // Returns true if the overlay is running & the user can access it. The overlay process could take a few seconds to
      // start & hook the game process, so this function will initially return false while the overlay is loading.
      function IsOverlayEnabled() : Boolean;
      constructor Create(SteamUtilsHandle : PISteamUtils);
      destructor Destroy; override;
  end;

implementation

uses
  steam_api;

function SteamAPI_ISteamUtils_GetSecondsSinceAppActive(SteamUtils : PISteamUtils) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetSecondsSinceComputerActive(SteamUtils : PISteamUtils) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamUtils_GetConnectedUniverse(SteamUtils : PISteamUtils) : EUniverse; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetServerRealTime(SteamUtils : PISteamUtils) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetIPCountry(SteamUtils : PISteamUtils) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetImageSize(SteamUtils : PISteamUtils; iImage : Integer; out pnWidth : UInt32; out pnHeight : UInt32) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetImageRGBA(SteamUtils : PISteamUtils; iImage : Integer; pubDest : PByte; nDestBufferSize : Integer) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetCSERIPPort(SteamUtils : PISteamUtils; out unIP : UInt32; out usPort : uint16) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetCurrentBatteryPower(SteamUtils : PISteamUtils) : uint8; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetAppID(SteamUtils : PISteamUtils) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUtils_SetOverlayNotificationPosition(SteamUtils : PISteamUtils; eNotificationPosition : eNotificationPosition); cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamUtils_IsAPICallCompleted(SteamUtils : PISteamUtils;hSteamAPICall : SteamAPICall_t; out pbFailed : Boolean) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamUtils_GetAPICallFailureReason(SteamUtils : PISteamUtils;hSteamAPICall : SteamAPICall_t) : ESteamAPICallFailure; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamUtils_GetAPICallResult(SteamUtils : PISteamUtils;hSteamAPICall : SteamAPICall_t; pCallback : Pointer; cubCallback : Integer; iCallbackExpected : Integer; out pbFailed : Boolean) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetIPCCallCount(SteamUtils : PISteamUtils) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
// procedure SteamAPI_ISteamUtils_SetWarningMessageHook(SteamUtils : PISteamUtils;pFunction : SteamAPIWarningMessageHook_t); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_IsOverlayEnabled(SteamUtils : PISteamUtils) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_BOverlayNeedsPresent(SteamUtils : PISteamUtils) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamUtils_CheckFileSignature(SteamUtils : PISteamUtils;const szFileName : AnsiChar) : SteamAPICall_t; cdecl; external STEAM_API_LIBFILENAME delayed;
// function SteamAPI_ISteamUtils_ShowGamepadTextInput(SteamUtils : PISteamUtils;eInputMode : EGamepadTextInputMode; eLineInputMode : EGamepadTextInputLineMode; const pchDescription : AnsiChar; unCharMax : uint32; const pchExistingText : AnsiChar) : Booleab; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(SteamUtils : PISteamUtils) : UInt32; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(SteamUtils : PISteamUtils; pchText : PAnsiChar; cchText : UInt32) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_GetSteamUILanguage(SteamUtils : PISteamUtils) : PAnsiChar; cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_IsSteamRunningInVR(SteamUtils : PISteamUtils) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUtils_SetOverlayNotificationInset(SteamUtils : PISteamUtils; nHorizontalInset : Integer; nVerticalInset : Integer); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_IsSteamInBigPictureMode(SteamUtils : PISteamUtils) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUtils_StartVRDashboard(SteamUtils : PISteamUtils); cdecl; external STEAM_API_LIBFILENAME delayed;
function SteamAPI_ISteamUtils_IsVRHeadsetStreamingEnabled(SteamUtils : PISteamUtils) : Boolean; cdecl; external STEAM_API_LIBFILENAME delayed;
procedure SteamAPI_ISteamUtils_SetVRHeadsetStreamingEnabled(SteamUtils : PISteamUtils; bEnabled : Boolean); cdecl; external STEAM_API_LIBFILENAME delayed;

{ ISteamUtils }

constructor ISteamUtils.Create(SteamUtilsHandle : PISteamUtils);
begin
  FHandle := SteamUtilsHandle;
end;

destructor ISteamUtils.Destroy;
begin

  inherited;
end;

function ISteamUtils.GetAppID : UInt32;
begin
  result := SteamAPI_ISteamUtils_GetAppID(FHandle);
end;

function ISteamUtils.GetCurrentBatteryPower : uint8;
begin
 result := SteamAPI_ISteamUtils_GetCurrentBatteryPower(FHandle);
end;

function ISteamUtils.GetIPCountry : string;
begin
  result := String(SteamAPI_ISteamUtils_GetIPCountry(FHandle));
end;

function ISteamUtils.GetServerRealTime : UInt32;
begin
  result := SteamAPI_ISteamUtils_GetServerRealTime(FHandle);
end;

function ISteamUtils.IsOverlayEnabled : Boolean;
begin
  result := SteamAPI_ISteamUtils_IsOverlayEnabled(FHandle);
end;

end.

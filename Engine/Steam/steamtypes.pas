unit steamtypes;

interface

type
  // original placed in isteamclient.h, but moved to steamtypes to evade
  // circular references
  // handle to a communication pipe to the Steam client
  HSteamPipe = Integer;
  // handle to single instance of a steam user
  HSteamUser = Integer;

  // this is baked into client messages and interfaces as an int,
  // make sure we never break this.
type
  AppId_t = UInt32;
const
  k_uAppIdInvalid : AppId_t = $0;

  // this is baked into client messages and interfaces as an int,
  // make sure we never break this.  AppIds and DepotIDs also presently
  // share the same namespace, but since we'd like to change that in the future
  // I've defined it seperately here.
type
  DepotId_t = UInt32;
  PDepotId_t = ^DepotId_t;
const
  k_uDepotIdInvalid : DepotId_t = $0;

const
  STEAM_STRING_BUFFER_LENGTH = 2048;

type
  TSteamStringBuffer = array [0 .. STEAM_STRING_BUFFER_LENGTH - 1] of AnsiChar;

const
  // -----------------------------------------------------------------------------
  // Purpose: Base values for callback identifiers, each callback must
  // have a unique ID.
  // -----------------------------------------------------------------------------
  k_iSteamUserCallbacks                  = 100;
  k_iSteamGameServerCallbacks            = 200;
  k_iSteamFriendsCallbacks               = 300;
  k_iSteamBillingCallbacks               = 400;
  k_iSteamMatchmakingCallbacks           = 500;
  k_iSteamContentServerCallbacks         = 600;
  k_iSteamUtilsCallbacks                 = 700;
  k_iClientFriendsCallbacks              = 800;
  k_iClientUserCallbacks                 = 900;
  k_iSteamAppsCallbacks                  = 1000;
  k_iSteamUserStatsCallbacks             = 1100;
  k_iSteamNetworkingCallbacks            = 1200;
  k_iClientRemoteStorageCallbacks        = 1300;
  k_iClientDepotBuilderCallbacks         = 1400;
  k_iSteamGameServerItemsCallbacks       = 1500;
  k_iClientUtilsCallbacks                = 1600;
  k_iSteamGameCoordinatorCallbacks       = 1700;
  k_iSteamGameServerStatsCallbacks       = 1800;
  k_iSteam2AsyncCallbacks                = 1900;
  k_iSteamGameStatsCallbacks             = 2000;
  k_iClientHTTPCallbacks                 = 2100;
  k_iClientScreenshotsCallbacks          = 2200;
  k_iSteamScreenshotsCallbacks           = 2300;
  k_iClientAudioCallbacks                = 2400;
  k_iClientUnifiedMessagesCallbacks      = 2500;
  k_iSteamStreamLauncherCallbacks        = 2600;
  k_iClientControllerCallbacks           = 2700;
  k_iSteamControllerCallbacks            = 2800;
  k_iClientParentalSettingsCallbacks     = 2900;
  k_iClientDeviceAuthCallbacks           = 3000;
  k_iClientNetworkDeviceManagerCallbacks = 3100;
  k_iClientMusicCallbacks                = 3200;
  k_iClientRemoteClientManagerCallbacks  = 3300;
  k_iClientUGCCallbacks                  = 3400;
  k_iSteamStreamClientCallbacks          = 3500;
  k_IClientProductBuilderCallbacks       = 3600;
  k_iClientShortcutsCallbacks            = 3700;
  k_iClientRemoteControlManagerCallbacks = 3800;
  k_iSteamAppListCallbacks               = 3900;
  k_iSteamMusicCallbacks                 = 4000;
  k_iSteamMusicRemoteCallbacks           = 4100;
  k_iClientVRCallbacks                   = 4200;
  k_iClientGameNotificationCallbacks     = 4300;
  k_iSteamGameNotificationCallbacks      = 4400;
  k_iSteamHTMLSurfaceCallbacks           = 4500;
  k_iClientVideoCallbacks                = 4600;
  k_iClientInventoryCallbacks            = 4700;
  k_iClientBluetoothManagerCallbacks     = 4800;
  k_iClientSharedConnectionCallbacks     = 4900;
  k_ISteamParentalSettingsCallbacks      = 5000;

type

  /// <summary> Rtti attribute for internal use only. Used to annotate iCallback (CallbackIdentifier) directly
  /// to data record to simplify HSteamAPI<T>.RegisterCallback.</summary>
  SteamCallbackIdentifier = class(TCustomAttribute)
    strict private
      FiCallback : Integer;
    public
      property iCallback : Integer read FiCallback;
      constructor Create(iCallback : Integer);
  end;

implementation

{ SteamCallbackIdentifier }

constructor SteamCallbackIdentifier.Create(iCallback: Integer);
begin
  FiCallback := iCallback;
end;

end.
